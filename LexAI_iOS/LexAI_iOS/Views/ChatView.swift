//
//  ChatView.swift
//  LexAI_iOS
//

import SwiftUI

private let bottomAnchorId = "bottom"

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""

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
                    colors: [Color.white,
                             Color("grape").opacity(0.6),
                             Color("grape").opacity(0.9),
                             Color("grape")],
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
                TextField("Message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .lineLimit(1...6)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundStyle(inputText.isEmpty ? Color.white.opacity(0.6) : Color.white)
                }
                .disabled(inputText.isEmpty)
                .padding(.bottom, 4)
                
                ImportFile()
                    .padding(.bottom, 7)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.top)
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        messages.append(ChatMessage(text: text, isFromUser: true))
        messages.append(ChatMessage(text: "Reply placeholder", isFromUser: false))
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
    ChatView()
}
