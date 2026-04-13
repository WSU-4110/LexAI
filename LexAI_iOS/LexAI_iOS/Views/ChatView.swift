//  ChatView.swift
//  LexAI_iOS

import SwiftUI

struct ChatView: View {

    // Bindings owned by HomeView — keeps HomeView call site unchanged
    @Binding var messages: [ChatMessage]
    @Binding var selectedLanguage: String

    // Sidebar wiring — optional so the existing HomeView call compiles as-is.
    // Pass vm + sessionID from HomeView when you're ready to enable title sync.
    var vm: SidebarViewModel? = nil
    var sessionID: UUID? = nil

    @State private var inputText: String = ""

    var body: some View {
        VStack {
            // ── your existing message list UI goes here ──

            // MARK: Send Button
            Button("Send") {
                sendMessage()
            }
        }
    }

    // MARK: - Send Message
    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 1. Append user message
        let userMessage = ChatMessage(text: trimmed, isFromUser: true)
        messages.append(userMessage)
        inputText = ""

        // 2. Tell the sidebar — triggers title + preview update on first message
        if let id = sessionID {
            vm?.updateSession(id: id, messages: messages)
        }

        // 3. Your existing AI call here
        fetchAIResponse(for: trimmed)
    }

    // MARK: - AI Response Handler
    private func fetchAIResponse(for prompt: String) {
        // ... your existing API call ...
        //
        // When the AI response arrives, add these two lines:
        //   messages.append(ChatMessage(text: responseText, isFromUser: false))
        //   if let id = sessionID { vm?.updateSession(id: id, messages: messages) }
    }
}
