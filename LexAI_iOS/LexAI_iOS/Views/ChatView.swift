//  ChatView.swift
//  LexAI_iOS

import SwiftUI

private let bottomAnchorId = "bottom"

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
<<<<<<< Updated upstream

    @State private var showScanDocuments = false
    @Binding var selectedLanguage: String //For language in conversation
=======
    @State private var showScanDocuments = false
    @Binding var selectedLanguage: String //For language in conversation


>>>>>>> Stashed changes
    var body: some View {
        VStack(spacing: 0) {
            Text("LexAI")
                .font(.system(size: 46))
                .fontWeight(.semibold)
                .foregroundStyle(Color("grape"))
                .shadow(radius: 14, x: 0, y: 12)
<<<<<<< Updated upstream

=======
            
>>>>>>> Stashed changes
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
        .fullScreenCover(isPresented: $showScanDocuments) {
                    //Preview Wrapper
                    #if targetEnvironment(simulator)
                    VStack(spacing: 20) {
                        Text("Document Scanner Preview")
                            .font(.headline)
                            .padding()
                        Button("Dismiss") {
                            showScanDocuments = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    #else
<<<<<<< Updated upstream
                    ScanDocumentsView(isPresented: $showScanDocuments) { scannedText in
                        messages.append(ChatMessage(text: scannedText, isFromUser: true))
                    }
                    #endif
                }
            }
    
=======
            
                    ScanDocumentsView(isPresented: $showScanDocuments) { scannedText in
                        messages.append(ChatMessage(text: scannedText, isFromUser: true))
                    }
            
                    #endif
                }
            }

>>>>>>> Stashed changes
    private var messageList: some View {
         ScrollViewReader { proxy in
             ScrollView {
                 LazyVStack(alignment: .leading, spacing: 12) {
                     ForEach(messages) { message in
                         MessageBubbleView(message: message)
                     }
<<<<<<< Updated upstream
=======
                     
>>>>>>> Stashed changes
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
                Button(action: {
                    showScanDocuments = true
                }) {
                    Image(systemName: "camera")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundStyle(Color.white)
                }
                .padding(.bottom, 4)
                .padding(.leading, 20)

<<<<<<< Updated upstream
=======
                
>>>>>>> Stashed changes
                TextField(getLocalizedPlaceholder(), text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .lineLimit(1...6)

<<<<<<< Updated upstream
=======

>>>>>>> Stashed changes
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundStyle(inputText.isEmpty ? Color.white.opacity(0.6) : Color.white)
<<<<<<< Updated upstream
=======
                    
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
=======
    
>>>>>>> Stashed changes
    private func getLocalizedPlaceholder() -> String {
        switch selectedLanguage {
<<<<<<< Updated upstream
        case "Spanish":
            return "Mensaje..."
        case "French":
            return "Message..."
        case "Arabic":
            return "رسالة..."
        case "German":
            return "Nachricht..."
        default:
            return "Message..."
=======
            case "Spanish":
                return "Mensaje..."

            case "French":
                return "Message..."

            case "Arabic":
                return "رسالة..."

            case "German":
                return "Nachricht..."

            default:
                return "Message..."
>>>>>>> Stashed changes
        }

    }

<<<<<<< Updated upstream

=======
    
>>>>>>> Stashed changes
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
<<<<<<< Updated upstream
=======
        
>>>>>>> Stashed changes
        guard !text.isEmpty else { return }
        inputText = ""
        messages.append(ChatMessage(text: text, isFromUser: true))
<<<<<<< Updated upstream
=======

>>>>>>> Stashed changes
        //For reply placeholder ot align to language
        let response = getLocalizedResponse()
        messages.append(ChatMessage(text: response, isFromUser: false))
        
    }
<<<<<<< Updated upstream
=======
    
>>>>>>> Stashed changes

    private func getLocalizedResponse() -> String {
        switch selectedLanguage {
<<<<<<< Updated upstream
        case "Spanish":
            return "¡Hola! ¿En qué puedo ayudarte hoy?"
        case "French":
            return "Bonjour ! Comment puis-je vous aider aujourd'hui ?"
        case "Arabic":
            return "مرحبا! كيف يمكنني مساعدتك اليوم؟"
        case "German":
            return "Hallo! Wie kann ich Ihnen heute helfen?"
        default:
            return "Hello! How can I help you today?"
=======

            case "Spanish":
                return "¡Hola! ¿En qué puedo ayudarte hoy?"

            case "French":
                return "Bonjour ! Comment puis-je vous aider aujourd'hui ?"

            case "Arabic":
                return "مرحبا! كيف يمكنني مساعدتك اليوم؟"

            case "German":
                return "Hallo! Wie kann ich Ihnen heute helfen?"

            default:
                return "Hello! How can I help you today?"

>>>>>>> Stashed changes
        }
    }
}

<<<<<<< Updated upstream
// MARK: - Message bubble

private struct MessageBubbleView: View {

    let message: ChatMessage
=======

// MARK: - Message bubble
private struct MessageBubbleView: View {

    let message: ChatMessage
    
>>>>>>> Stashed changes
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
//Preview Wrapper
#Preview {
    @Previewable @State var selectedLanguage = "English"
    return ChatView(selectedLanguage: $selectedLanguage)
}

