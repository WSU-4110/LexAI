//
//  HomeView.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/17/26.
//
// Sprint 3 : removed UI (for audit / [BUG] Sidebar PT 2 #46): by Sara Al-hachami
// showToolbar + conditional that hid the hamburger after one toggle (toolbar button always visible now)

import SwiftUI

struct HomeView: View {
    //changes made by Sara
    @EnvironmentObject private var authManager: AuthManager
    @State private var isSidebarOpen = false
    // Sprint 2 addition
    @StateObject private var sidebarVM = SidebarViewModel()
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "English" //language storing for conversational use
    @State private var showLanguageDropdown = false

    let languages = [
        "English",
        "Spanish",
        "French",
        "Arabic",
        "German"
    ]

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

                // Sprint 2 addition
                SideBarView(isOpen: $isSidebarOpen, vm: sidebarVM)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(x: isSidebarOpen ? -10 : -400)
                    .animation(.easeIn(duration: 0.25), value: isSidebarOpen)

                // Language selection dropdown box
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
                // Sprint 3: icon is xmark when sidebar open, hamburger when closed (replaces showToolbar hide on toggle behavior)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isSidebarOpen.toggle()
                    } label: {
                        Image(systemName: isSidebarOpen ? "xmark" : "line.horizontal.3")
                    }
                }

                // Globe button for language dropdown
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLanguageDropdown.toggle()
                    } label: {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        //changes made by Sara
        .environmentObject(AuthManager())
}
