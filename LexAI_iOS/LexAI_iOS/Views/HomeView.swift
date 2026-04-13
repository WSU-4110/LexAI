import SwiftUI

struct HomeView: View {
    
    @State private var isSidebarOpen = false
    @State private var showToolbar = true
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "English"
    @State private var showLanguageDropdown = false

    @StateObject private var sidebarVM = SidebarViewModel()
    @State private var messages: [ChatMessage] = []
    @State private var chatViewResetID = UUID()

    private let languages = ["English", "Spanish", "French", "Arabic", "German"]

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    VStack {
                        ChatView(messages: $messages, selectedLanguage: $selectedLanguage)
                            .id(chatViewResetID)
                    }

                    if isSidebarOpen {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture { isSidebarOpen = false }
                    }

                    SideBarView(isOpen: $isSidebarOpen, vm: sidebarVM, onNewChat: {
                        // Reset both chat data and local ChatView state for a true fresh thread.
                        messages = []
                        chatViewResetID = UUID()
                    })
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
    }
}

#Preview {
    HomeView()
}
