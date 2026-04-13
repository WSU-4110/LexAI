import SwiftUI

struct HomeView: View {

    @State private var isSidebarOpen = false
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "English"
    @State private var showLanguageDropdown = false
    @StateObject private var sidebarVM = SidebarViewModel()
    private let languages = ["English", "Spanish", "French", "Arabic", "German"]

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // MARK: Main content
                    VStack {
                        ChatView(selectedLanguage: $selectedLanguage)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // MARK: Dim overlay — tap to close
                    if isSidebarOpen {
                        Color.black
                            .opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture { closeSidebar() }
                            .transition(.opacity)
                            .zIndex(1)
                    }

                    // MARK: Sidebar — 80% width, slides in from left
                    SideBarView(isOpen: $isSidebarOpen, vm: sidebarVM)
                        .frame(width: geo.size.width * 0.80)
                        .offset(x: isSidebarOpen ? 0 : -(geo.size.width * 0.80))
                        .shadow(color: .black.opacity(isSidebarOpen ? 0.2 : 0), radius: 16, x: 4, y: 0)
                        .zIndex(2)

                    // MARK: Language dropdown
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
                        .zIndex(3)
                    }
                }
                .animation(.easeInOut(duration: 0.28), value: isSidebarOpen)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isSidebarOpen {
                        Button { openSidebar() } label: {
                            Image(systemName: "line.horizontal.3")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showLanguageDropdown.toggle() } label: {
                        Image(systemName: "globe")
                            .foregroundColor(Color("grape"))
                    }
                }
            }
            .overlay {
                LegalDisclaimerAlert()
            }
        }
    }

    private func openSidebar() {
        withAnimation(.easeInOut(duration: 0.28)) { isSidebarOpen = true }
    }

    private func closeSidebar() {
        withAnimation(.easeInOut(duration: 0.28)) { isSidebarOpen = false }
    }
}

#Preview {
    HomeView()
}
