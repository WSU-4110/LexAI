//
//  ContentView.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/10/26.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var authManager = AuthManager()
    
    var body: some View {
        Group {
            //changes made by Sara
            if authManager.userSession != nil {
                HomeView()
                    //changes made by Sara
                    .environmentObject(authManager)
            } else {
                AuthView()
                    .environmentObject(authManager)
            }
        }
        // modification made by Sara Al-hachami to fix sign in error
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            print("[AuthDebug] ContentView observed isAuthenticated = \(isAuthenticated)")
        }
    }
}

#Preview {
    ContentView()
}
