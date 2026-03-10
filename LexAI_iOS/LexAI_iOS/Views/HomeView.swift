//
//  HomeView.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/17/26.
//

import SwiftUI

struct HomeView: View {
<<<<<<< Updated upstream
    @State private var isSidebarOpen = false
    @State private var showToolbar = true

    @AppStorage("selectedLanguage") private var selectedLanguage: String = "English" //language storing for conversational use
    @State private var showLanguageDropdown = false

=======
    
    @State private var isSidebarOpen = false
    @State private var showToolbar = true
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "English" //language storing for conversational use
    @State private var showLanguageDropdown = false
    
>>>>>>> Stashed changes
    let languages = [
        "English",
        "Spanish",
        "French",
        "Arabic",
        "German"
    ]
<<<<<<< Updated upstream

=======
    
>>>>>>> Stashed changes
    var body: some View {
        NavigationStack {
            ZStack {
                VStack{
                    ChatView(selectedLanguage: $selectedLanguage)
                }
<<<<<<< Updated upstream
=======
                
>>>>>>> Stashed changes
                if isSidebarOpen {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { isSidebarOpen = false }
                }
<<<<<<< Updated upstream
        
=======
                
>>>>>>> Stashed changes
                SidebarView(isOpen: $isSidebarOpen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(x: isSidebarOpen ? -10 : -400)
                    .animation(.easeIn(duration: 0.25), value: isSidebarOpen)
<<<<<<< Updated upstream
=======
                
>>>>>>> Stashed changes
                //language selection-DropDown Box
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
<<<<<<< Updated upstream
                                
                                    Spacer()
                            
                                    if language == selectedLanguage {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
=======
                                    Spacer()
                                    if language == selectedLanguage {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                }
    
            }
    
            .toolbar {
=======
                    
                }
            }
            .toolbar {
                
>>>>>>> Stashed changes
                ToolbarItem(placement: .navigationBarLeading) {
                    if showToolbar {
                        Button {
                            isSidebarOpen.toggle()
                            showToolbar.toggle()
                        } label: {
                            Image(systemName: "line.horizontal.3")
                        }
                    }
                }
<<<<<<< Updated upstream
=======
                
>>>>>>> Stashed changes
                //Addition of globe for Dropdown menu selection
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLanguageDropdown.toggle()
                    } label: {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
<<<<<<< Updated upstream

                    }

                }

         

=======
                    }
                }
                
>>>>>>> Stashed changes
            }
        }
    }
}

#Preview {
    HomeView()
}
