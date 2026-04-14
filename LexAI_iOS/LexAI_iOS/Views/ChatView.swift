//  ChatView.swift
//  LexAI_iOS

import SwiftUI
import FirebaseFunctions
import UniformTypeIdentifiers
import PDFKit
import FirebaseAuth

private let bottomAnchorId = "bottom"

struct ChatView: View {
    @Binding var messages: [ChatMessage]
    @Binding var selectedLanguage: String
    @Binding var activeChatDocumentID: String?

    var vm: SidebarViewModel? = nil
    var sessionID: UUID? = nil
    var onChatPersisted: ((String) -> Void)? = nil

    @State private var inputText: String = ""
    @State private var showScanDocuments = false
    @State private var showFilePicker = false
    @State private var isAwaitingReply = false
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.scenePhase) private var scenePhase
    private let functions = Functions.functions()

    var body: some View {
        VStack(spacing: 0) {
            Text("LexAI")
                .font(.system(size: 46))
                .fontWeight(.semibold)
                .foregroundStyle(Color("grape"))
                .shadow(radius: 14, x: 0, y: 12)

            messageList
            inputBar
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.white,
                    Color("grape").opacity(0.6),
                    Color("grape").opacity(0.9),
                    Color("grape"),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .fullScreenCover(isPresented: $showScanDocuments) {
            #if targetEnvironment(simulator)
            VStack(spacing: 20) {
                Text("Document Scanner Preview")
                    .font(.headline)
                    .padding()
                Button("Dismiss") { showScanDocuments = false }
                    .buttonStyle(.borderedProminent)
            }
            #else
            ScanDocumentsView(isPresented: $showScanDocuments) { scannedText in
                messages.append(ChatMessage(text: scannedText, isFromUser: true))
            }
            #endif
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.plainText, .pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .onDisappear {
            saveChatIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                saveChatIfNeeded()
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if messages.isEmpty {
                        Text("Start a new chat")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    }

                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                    }

                    if isAwaitingReply {
                        ThinkingBubbleView()
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                    Color.clear
                        .frame(height: 8)
                        .id(bottomAnchorId)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(bottomAnchorId, anchor: .bottom)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var inputBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                actionButton(icon: "document.viewfinder", label: "Scan Document") {
                    showScanDocuments = true
                }
                actionButton(icon: "arrow.up.doc", label: "Upload Document") {
                    showFilePicker = true
                }
                Spacer()
            }
            .padding(.horizontal, 4)

            HStack(alignment: .bottom, spacing: 12) {
                TextField(
                    ChatPlaceholderText.placeholder(forSelectedLanguage: selectedLanguage),
                    text: $inputText,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .lineLimit(1...6)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: isAwaitingReply ? "clock.arrow.circlepath" : "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundStyle(inputText.isEmpty ? Color.white.opacity(0.6) : Color.white)
                }
                .disabled(inputText.isEmpty || isAwaitingReply)
                .padding(.bottom, 4)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top)
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.22), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            let extracted: String?
            if url.pathExtension.lowercased() == "pdf" {
                extracted = extractTextFromPDF(url: url)
            } else {
                extracted = try? String(contentsOf: url, encoding: .utf8)
            }

            if let text = extracted, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                messages.append(ChatMessage(text: text.trimmingCharacters(in: .whitespacesAndNewlines), isFromUser: true))
            }

        case .failure(let error):
            print("File import error: \(error)")
        }
    }

    private func extractTextFromPDF(url: URL) -> String? {
        guard let pdf = PDFDocument(url: url) else { return nil }
        var text = ""
        for i in 0..<pdf.pageCount {
            if let page = pdf.page(at: i), let content = page.string {
                text += content + "\n"
            }
        }
        return text.isEmpty ? nil : text
    }

    private func saveChatIfNeeded() {
        print("saveChatIfNeeded called, message count: \(messages.count)")
        guard !messages.isEmpty else { return }
        guard let userId = firebaseManager.user?.uid else { return }

        let transcript = messages
            .map { ($0.isFromUser ? "User" : "LexAI") + ": " + $0.text }
            .joined(separator: "\n")

        let chatPrompt = ChatPrompt(
            id: activeChatDocumentID,
            prompt: transcript,
            documents: [],
            location: "",
            language: selectedLanguage,
            user: userId
        )

        if let existingID = activeChatDocumentID, !existingID.isEmpty {
            firebaseManager.updateChat(chatId: existingID, newPrompt: transcript) { success in
                print("Save result: \(success)")
                if success {
                    onChatPersisted?(transcript)
                }
            }
        } else {
            firebaseManager.saveChat(prompt: chatPrompt) { newDocumentID in
                let success = (newDocumentID != nil)
                print("Save result: \(success)")
                if let newDocumentID {
                    activeChatDocumentID = newDocumentID
                    onChatPersisted?(transcript)
                }
            }
        }
    }

    private func sendMessage() {
        let text = ChatInputValidator.trimmedMessage(inputText)
        guard ChatInputValidator.shouldSendMessage(inputText) else { return }

        inputText = ""

        messages.append(ChatMessage(text: text, isFromUser: true))
        if let id = sessionID { vm?.updateSession(id: id, messages: messages) }

        Task { @MainActor in
            isAwaitingReply = true
            defer { isAwaitingReply = false }

            do {
                let reply = try await generateAnswer(prompt: text, targetLanguage: selectedLanguage)
                messages.append(ChatMessage(text: reply, isFromUser: false))
                if let id = sessionID { vm?.updateSession(id: id, messages: messages) }
            } catch {
                messages.append(
                    ChatMessage(text: ChatReplyErrorFormatter.replyErrorMessage(for: error), isFromUser: false)
                )
            }
        }
    }

    private func generateAnswer(prompt: String, targetLanguage: String) async throws -> String {
        let callable = functions.httpsCallable("chat")

        let chatHistory: [[String: String]] = messages.dropLast().map { msg in
            ["role": msg.isFromUser ? "user" : "assistant", "content": msg.text]
        }

        let result = try await callable.call([
            "prompt": prompt,
            "chat_history": chatHistory,
            "language": targetLanguage,
        ])

        if let data = result.data as? [String: Any],
           let response = data["response"] as? String {
            return response
        } else if let data = result.data as? [String: Any],
                  let error = data["error"] as? String {
            throw NSError(domain: "LexAI", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
        }

        throw NSError(domain: "LexAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to parse response"])
    }
}

private struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.isFromUser { Spacer(minLength: 48) }
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isFromUser ? Color("grape") : Color(.systemGray6))
                    .foregroundStyle(message.isFromUser ? .white : .black)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            if !message.isFromUser { Spacer(minLength: 48) }
        }
    }
}
