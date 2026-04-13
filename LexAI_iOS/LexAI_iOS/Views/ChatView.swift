//
//  ChatView.swift
//  LexAI_iOS
//

import SwiftUI
import FirebaseFunctions
import UniformTypeIdentifiers
import PDFKit
import FirebaseAuth

private let bottomAnchorId = "bottom"

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var showDocumentMenu = false    // bottom popup menu
    @State private var showScanDocuments = false   // camera scanner
    @State private var showFilePicker = false      // file importer
    @State private var isAwaitingReply = false

    @Binding var selectedLanguage: String // language in conversation

    private let functions = Functions.functions()

    //Defines the main chat interface layout, including the title, message list, and input bar.
    var body: some View {
        ZStack(alignment: .bottom) {
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

            // MARK: Dim tap-away layer
            if showDocumentMenu {
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { showDocumentMenu = false } }
            }

            // MARK: Bottom popup menu (ChatGPT style)
            if showDocumentMenu {
                documentMenu
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showDocumentMenu)
        // Camera scanner
        .fullScreenCover(isPresented: $showScanDocuments) {
            #if targetEnvironment(simulator)
            VStack(spacing: 20) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(Color("grape"))
                Text("Camera scanner is not\navailable in the simulator.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("Dismiss") { showScanDocuments = false }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            #else
            ScanDocumentsView(isPresented: $showScanDocuments) { scannedText in
                messages.append(ChatMessage(text: scannedText, isFromUser: true))
            }
            #endif
        }
        // File picker
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.plainText, .pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    // MARK: Document Menu

    private var documentMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuRow(
                icon: "camera.viewfinder",
                label: "Scan Document"
            ) {
                withAnimation { showDocumentMenu = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showScanDocuments = true
                }
            }

            Divider().padding(.leading, 52)

            menuRow(
                icon: "arrow.up.doc",
                label: "Upload Document"
            ) {
                withAnimation { showDocumentMenu = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showFilePicker = true
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 90) // clears the input bar
    }

    private func menuRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 28)
                Text(label)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    //Makes a scrollable list of chat messages with automatic scrolling to the bottom
    // MARK: Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
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

    //Makes the input bar with scan document button, text field, and send button
    // MARK: Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // + button — opens bottom menu
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    showDocumentMenu.toggle()
                }
            } label: {
                Image(systemName: showDocumentMenu ? "xmark" : "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 35, height: 35)
                    .background(Color.white.opacity(0.25), in: Circle())
                    .animation(.easeInOut(duration: 0.18), value: showDocumentMenu)
            }
            .padding(.bottom, 4)

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

            Button { sendMessage() } label: {
                Image(systemName: isAwaitingReply ? "clock.arrow.circlepath" : "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 35, height: 35)
                    .foregroundStyle(inputText.isEmpty ? Color.white.opacity(0.6) : Color.white)
            }
            .disabled(inputText.isEmpty || isAwaitingReply)
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 4)
        .padding(.top)
    }

    //Sends the user's message, validates input, and handles the AI response asynchronously
    // MARK: File Import Handler

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

            if let text = extracted,
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                messages.append(ChatMessage(
                    text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                    isFromUser: true
                ))
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

    // MARK: Send Message

    private func sendMessage() {
        let text = ChatInputValidator.trimmedMessage(inputText)
        guard ChatInputValidator.shouldSendMessage(inputText) else { return }
        inputText = ""
        messages.append(ChatMessage(text: text, isFromUser: true))

        Task { @MainActor in
            isAwaitingReply = true
            defer { isAwaitingReply = false }
            do {
                let reply = try await generateAnswer(prompt: text, targetLanguage: selectedLanguage)
                messages.append(ChatMessage(text: reply, isFromUser: false))
            } catch {
                messages.append(
                    ChatMessage(text: ChatReplyErrorFormatter.replyErrorMessage(for: error), isFromUser: false)
                )
            }
        }
    }

    //Calls the Firebase function to generate an AI response based on the prompt and chat history
    private func generateAnswer(prompt: String, targetLanguage: String) async throws -> String {
        let callable = functions.httpsCallable("chat")

        //Build chat history from previous messages (exclude the one we just added)
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

// MARK: - Message Bubble

private struct MessageBubbleView: View {
    let message: ChatMessage
    
    //Defines the layout for displaying a single chat message bubble

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

#Preview {
    @Previewable @State var selectedLanguage = "English"
    return ChatView(selectedLanguage: $selectedLanguage)
}
