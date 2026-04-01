//
//  HomeView.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/17/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var sidebarViewModel = SidebarViewModel()
    @State private var isSidebarOpen = false

    @AppStorage("selectedLanguage") private var selectedLanguage: String = "English"
    @State private var showLanguageDropdown = false

    let languages = ["English", "Spanish", "French", "Arabic", "German"]

    var body: some View {
        NavigationStack {
            ZStack {
                ChatView(selectedLanguage: $selectedLanguage)
                    .environmentObject(sidebarViewModel)
                    .environmentObject(locationManager)

                // language dropdown
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

                // sidebar sits on top of everything
                SideBarView(isOpen: $isSidebarOpen, vm: sidebarViewModel)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isSidebarOpen.toggle()
                    } label: {
                        Image(systemName: isSidebarOpen ? "xmark" : "line.horizontal.3")
                            .font(.body.weight(isSidebarOpen ? .semibold : .regular))
                    }
                    .accessibilityLabel(isSidebarOpen ? "Close sidebar" : "Open sidebar")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showLanguageDropdown.toggle() } label: {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { authManager.signOut() } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
        .environmentObject(LocationManager())
}
