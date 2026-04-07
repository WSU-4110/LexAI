import SwiftUI

struct HomeView: View {
    @State private var isSidebarOpen = false
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "English"
    @State private var showLanguageDropdown = false

    private let languages = ["English", "Spanish", "French", "Arabic", "German"]

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    ChatView(selectedLanguage: $selectedLanguage)
                }

                if isSidebarOpen {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { isSidebarOpen = false }
                }

                SideBarView(isOpen: $isSidebarOpen, vm: SidebarViewModel())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(x: isSidebarOpen ? -10 : -400)
                    .animation(.easeIn(duration: 0.25), value: isSidebarOpen)

                if showLanguageDropdown {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(languages, id: \.self) { language in
                            Button {
                                selectedLanguage = language
                                showLanguageDropdown = false
                            } label: {
                                HStack {
                                    Text(language)
                                        .foregroundColor(.black)
                                    Spacer()
                                    if language == selectedLanguage {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            if language != languages.last {
                                Divider()
                            }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isSidebarOpen {
                        Button {
                            isSidebarOpen = true
                        } label: {
                            Image(systemName: "line.horizontal.3")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLanguageDropdown.toggle()
                    } label: {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
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
