//  ChatView.swift
//  LexAI_iOS

import SwiftUI
import FirebaseFunctions

private let bottomAnchorId = "bottom"

struct ChatView: View {
    @Binding var messages: [ChatMessage]
    @Binding var selectedLanguage: String

    var vm: SidebarViewModel? = nil
    var sessionID: UUID? = nil

    @State private var inputText: String = ""
    @State private var isAwaitingReply = false
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
        .padding(.horizontal, 4)
        .padding(.top)
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
