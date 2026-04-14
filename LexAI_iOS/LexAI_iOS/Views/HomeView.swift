import SwiftUI
import FirebaseAuth

struct HomeView: View {
    
    @State private var isSidebarOpen = false
    @State private var showToolbar = true
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "English"
    @State private var showLanguageDropdown = false

    @StateObject private var sidebarVM = SidebarViewModel()
    @State private var messages: [ChatMessage] = []
    @State private var chatViewResetID = UUID()
    @State private var activeChatDocumentID: String?
    @State private var hasSavedBeforeLeaving = false
    @State private var chatBySessionID: [UUID: ChatPrompt] = [:]
    @EnvironmentObject var firebaseManager: FirebaseManager

    private let languages = ["English", "Spanish", "French", "Arabic", "German"]

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    VStack {
                        ChatView(
                            messages: $messages,
                            selectedLanguage: $selectedLanguage,
                            activeChatDocumentID: $activeChatDocumentID,
                            hasSavedBeforeLeaving: $hasSavedBeforeLeaving,
                            vm: sidebarVM,
                            sessionID: sidebarVM.activeSessionID,
                            onChatPersisted: { transcript in
                                reloadChatHistory(selectTranscript: transcript)
                            }
                        )
                            .environmentObject(firebaseManager)
                            .id(chatViewResetID)
                    }

                    if isSidebarOpen {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture { isSidebarOpen = false }
                    }

                    SideBarView(
                        isOpen: $isSidebarOpen,
                        vm: sidebarVM,
                        onSelectSession: { session in
                            if let chat = chatBySessionID[session.id] {
                                saveCurrentConversation {
                                    messages = parseTranscript(chat.prompt)
                                    activeChatDocumentID = chat.id
                                    hasSavedBeforeLeaving = false
                                }
                            }
                        },
                        onNewChat: {
                            saveCurrentConversation {
                                messages = []
                                activeChatDocumentID = nil
                                sidebarVM.activeSessionID = nil
                                hasSavedBeforeLeaving = false
                                chatViewResetID = UUID()
                                reloadChatHistory()
                            }
                        },
                        onDeleteSession: { session in
                            guard let chatID = chatBySessionID[session.id]?.id else { return }
                            firebaseManager.deleteChat(chatId: chatID) { success in
                                if success {
                                    if activeChatDocumentID == chatID {
                                        messages = []
                                        activeChatDocumentID = nil
                                        hasSavedBeforeLeaving = false
                                    }
                                    reloadChatHistory()
                                }
                            }
                        },
                        onSidebarAppear: {
                            reloadChatHistory()
                        }
                    )
                    .frame(width: geo.size.width * 0.80)
                    .offset(x: isSidebarOpen ? 0 : -(geo.size.width * 0.80))
                    .shadow(color: .black.opacity(isSidebarOpen ? 0.2 : 0), radius: 16, x: 4, y: 0)
                    .animation(.easeInOut(duration: 0.28), value: isSidebarOpen)

                    if showLanguageDropdown {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(languages, id: \.self) { language in
                                Button {
                                    selectedLanguage = language
                                    showLanguageDropdown = false
                                } label: {
                                    HStack {
                                        Text(language).foregroundColor(.black)
                                        Spacer()
                                        if language == selectedLanguage {
                                            Image(systemName: "checkmark").foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                if language != languages.last { Divider() }
                            }
                        }
                        .frame(width: 200)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 6)
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .animation(.easeInOut(duration: 0.2), value: showLanguageDropdown)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isSidebarOpen {
                        Button { isSidebarOpen = true } label: {
                            Image(systemName: "line.horizontal.3")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showLanguageDropdown.toggle() } label: {
                        Image(systemName: "globe").foregroundColor(Color("grape"))
                    }
                }
            }
            .overlay {
                LegalDisclaimerAlert()
            }
        }
        .task {
            reloadChatHistory()
        }
        .onChange(of: firebaseManager.user?.uid) { _, _ in
            reloadChatHistory()
        }
        .onChange(of: isSidebarOpen) { _, isOpen in
            if isOpen {
                reloadChatHistory()
            }
        }
    }

    private func reloadChatHistory(selectTranscript: String? = nil) {
        guard let userId = firebaseManager.user?.uid, !userId.isEmpty else {
            sidebarVM.sessions = []
            chatBySessionID = [:]
            return
        }

        firebaseManager.fetchChats(userId: userId) { chats in
            var mapping: [UUID: ChatPrompt] = [:]
            var sessions: [ChatSession] = []

            for chat in chats {
                let sid = UUID()
                mapping[sid] = chat
                sessions.append(
                    ChatSession(
                        id: sid,
                        title: chat.previewTitle,
                        preview: chat.previewTitle
                    )
                )
            }

            chatBySessionID = mapping
            sidebarVM.sessions = sessions

            if let transcript = selectTranscript,
               let matched = chats.first(where: { $0.prompt == transcript }),
               let matchedID = matched.id {
                activeChatDocumentID = matchedID
            }

            if let activeID = activeChatDocumentID,
               let matchingPair = mapping.first(where: { $0.value.id == activeID }) {
                sidebarVM.activeSessionID = matchingPair.key
            }
        }
    }

    private func parseTranscript(_ transcript: String) -> [ChatMessage] {
        let lines = transcript.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var parsed: [ChatMessage] = []
        var currentSpeakerIsUser: Bool?
        var currentText: String = ""

        func flushCurrent() {
            guard let isUser = currentSpeakerIsUser else { return }
            let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                parsed.append(ChatMessage(text: text, isFromUser: isUser))
            }
            currentSpeakerIsUser = nil
            currentText = ""
        }

        for line in lines {
            if line.hasPrefix("User: ") {
                flushCurrent()
                currentSpeakerIsUser = true
                currentText = String(line.dropFirst("User: ".count))
            } else if line.hasPrefix("LexAI: ") {
                flushCurrent()
                currentSpeakerIsUser = false
                currentText = String(line.dropFirst("LexAI: ".count))
            } else if currentSpeakerIsUser != nil {
                currentText += currentText.isEmpty ? line : "\n" + line
            }
        }

        flushCurrent()
        return parsed
    }

    private func saveCurrentConversation(completion: @escaping () -> Void) {
        guard !messages.isEmpty else {
            completion()
            return
        }
        guard let userId = firebaseManager.user?.uid, !userId.isEmpty else {
            completion()
            return
        }

        let transcript = messages
            .map { ($0.isFromUser ? "User" : "LexAI") + ": " + $0.text }
            .joined(separator: "\n")

        if let existingID = activeChatDocumentID, !existingID.isEmpty {
            firebaseManager.updateChat(chatId: existingID, newPrompt: transcript) { _ in
                hasSavedBeforeLeaving = true
                completion()
            }
            return
        }

        let prompt = ChatPrompt(
            id: nil,
            prompt: transcript,
            documents: [],
            location: "",
            language: selectedLanguage,
            user: userId
        )
        firebaseManager.saveChat(prompt: prompt) { newID in
            if let newID {
                activeChatDocumentID = newID
                hasSavedBeforeLeaving = true
            }
            completion()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(FirebaseManager(isPreview: true))
}
