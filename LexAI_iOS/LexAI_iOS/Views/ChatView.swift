//
//  ChatView.swift
//  LexAI_iOS
//

import SwiftUI

private let bottomAnchorId = "bottom"

struct ChatView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var viewModel: SidebarViewModel
    private let aiService = AIService()

    private var messages: [ChatMessage] {
        guard let id = viewModel.activeSessionID,
              let session = viewModel.sessions.first(where: { $0.id == id }) else {
            return []
        }
        return session.messages
    }

    @State private var inputText: String = ""
    @State private var showScanDocuments = false
    @State private var isAwaitingResponse = false
    @State private var streamingResponse: String = ""
    @Binding var selectedLanguage: String

    private var systemContext: String {
        let location = locationManager.locationString.isEmpty
            ? "an unknown location"
            : locationManager.locationString
        return """
You are LexAI, an AI legal assistant. \
The user is located in \(location). \
Where relevant, tailor your legal guidance to the laws and \
jurisdiction of that location. \
If you are unsure of local law, say so and give general guidance.
"""
    }

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
        .onChange(of: viewModel.activeSessionID) { _, _ in
            streamingResponse = ""
        }
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
                guard let id = viewModel.activeSessionID else { return }
                let next = messages + [ChatMessage(text: scannedText, isFromUser: true)]
                viewModel.updateSession(id: id, messages: next)
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

                    if !streamingResponse.isEmpty {
                        MessageBubbleView(
                            message: ChatMessage(text: streamingResponse, isFromUser: false)
                        )
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
            .onChange(of: streamingResponse) { _, _ in
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
                    Image(systemName: "camera")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundStyle(Color.white)
                }
                .padding(.bottom, 4)
                .padding(.leading, 20)

                TextField(getLocalizedPlaceholder(), text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .lineLimit(1...6)

                Button { sendMessage() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundStyle(inputText.isEmpty ? Color.white.opacity(0.6) : Color.white)
                }
                .disabled(inputText.isEmpty || isAwaitingResponse)
                .padding(.bottom, 4)

                ImportFile()
                    .padding(.bottom, 7)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.top)
        }
    }

    private func getLocalizedPlaceholder() -> String {
        switch selectedLanguage {
        case "Spanish": return "Mensaje..."
        case "French":  return "Message..."
        case "Arabic":  return "رسالة..."
        case "German":  return "Nachricht..."
        default:        return "Message..."
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard let sessionId = viewModel.activeSessionID else { return }

        let currentInput = text
        let system = systemContext
        inputText = ""

        let userMessage = ChatMessage(text: currentInput, isFromUser: true)
        viewModel.appendMessage(userMessage, to: sessionId)
        streamingResponse = ""

        Task {
            await MainActor.run { isAwaitingResponse = true }

            let updateQueue = DispatchQueue(label: "stream.queue")
            let orderedBuffer = NSMutableString()

            do {
                try await aiService.streamMessage(system: system, user: currentInput) { token in
                    updateQueue.async {
                        orderedBuffer.append(token)
                        Task { @MainActor in
                            streamingResponse += token
                        }
                    }
                }

                let finalText = await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
                    updateQueue.async {
                        continuation.resume(returning: orderedBuffer as String)
                    }
                }

                await MainActor.run {
                    let trimmed = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        let aiMessage = ChatMessage(text: finalText, isFromUser: false)
                        viewModel.appendMessage(aiMessage, to: sessionId)
                    }
                    streamingResponse = ""
                    isAwaitingResponse = false
                }
            } catch {
                let fallback = getLocalizedResponse(context: system)
                let fallbackMessage = ChatMessage(text: fallback, isFromUser: false)
                await MainActor.run {
                    viewModel.appendMessage(fallbackMessage, to: sessionId)
                    streamingResponse = ""
                    isAwaitingResponse = false
                }
            }
        }
    }

    private func getLocalizedResponse(context: String) -> String {
        _ = context
        switch selectedLanguage {
        case "Spanish": return "¡Hola! ¿En qué puedo ayudarte hoy?"
        case "French":  return "Bonjour ! Comment puis-je vous aider aujourd'hui ?"
        case "Arabic":  return "مرحبا! كيف يمكنني مساعدتك اليوم؟"
        case "German":  return "Hallo! Wie kann ich Ihnen heute helfen?"
        default:
            let location = locationManager.locationString.isEmpty ? "your area" : locationManager.locationString
            return "Hello from \(location)! How can I help you with legal questions today?"
        }
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
        .environmentObject(LocationManager())
        .environmentObject(SidebarViewModel())
}
