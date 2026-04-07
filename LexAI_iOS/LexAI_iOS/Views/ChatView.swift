//
//  ChatView.swift
//  LexAI_iOS
//

import SwiftUI
import FirebaseFunctions

private let bottomAnchorId = "bottom"

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var showScanDocuments = false
    @State private var isAwaitingReply = false
    @Binding var selectedLanguage: String
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
        let callable = functions.httpsCallable("generateAnswer")
        let result = try await callable.call([
            "prompt": prompt,
            "targetLanguage": targetLanguage,
        ])

        return try GenerateAnswerResponseParser.displayText(fromCallableData: result.data)
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
                    .background(message.isFromUser ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(message.isFromUser ? .white : .primary)
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
