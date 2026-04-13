//
//  ChatView.swift
//  LexAI_iOS
//

import SwiftUI
import FirebaseFunctions
import FirebaseAuth

private let bottomAnchorId = "bottom"

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var showScanDocuments = false
    @State private var isAwaitingReply = false

    @Binding var selectedLanguage: String // language in conversation
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.scenePhase) private var scenePhase // to detect app exit

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
        // trigger 1: user leaves the view (new chat)
        .onDisappear {
            saveChatIfNeeded()
        }

        // trigger 2: app goes to background or is killed
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                saveChatIfNeeded()
            }
        }
    }

    // MARK: - Save chat
    private func saveChatIfNeeded() {
        guard !messages.isEmpty else { return }
        guard let userId = firebaseManager.user?.uid else { return }

        // Build a readable transcript from the message array
        let transcript = messages
            .map { ($0.isFromUser ? "User" : "LexAI") + ": " + $0.text }
            .joined(separator: "\n")

        let chatPrompt = ChatPrompt(
            prompt: transcript,
            documents: [],
            location: "",
            language: selectedLanguage,
            user: userId
        )

        firebaseManager.saveChat(prompt: chatPrompt) { _ in }
    }

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

    private var inputBar: some View {
        VStack {
            HStack(alignment: .bottom, spacing: 12) {
                Button(action: { showScanDocuments = true }) {
                    Image(systemName: "document.viewfinder")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white)
                        .shadow(radius: 8, x: 0, y: 8)
                }
                .padding(.bottom, 4)

                TextField(ChatPlaceholderText.placeholder(forSelectedLanguage: selectedLanguage), text: $inputText, axis: .vertical)
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
            .padding(.horizontal, 4)
            .padding(.top)
        }
    }

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

    private func generateAnswer(prompt: String, targetLanguage: String) async throws -> String {
        let callable = functions.httpsCallable("chat")

        // Build chat history from previous messages (exclude the one we just added)
        let chatHistory: [[String: String]] = messages.dropLast().map { msg in
            ["role": msg.isFromUser ? "user" : "assistant", "content": msg.text]
        }

        let result = try await callable.call([
            "prompt": prompt,
            "chat_history": chatHistory,
            "language": targetLanguage,
        ])

        // Parse the response
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


// MARK: - Message bubble
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

#Preview {
    @Previewable @State var selectedLanguage = "English"
    return ChatView(selectedLanguage: $selectedLanguage)
        .environmentObject(FirebaseManager())
}
