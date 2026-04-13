//
//  ContentView.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/10/26.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var firebaseManager = FirebaseManager()
    
    var body: some View {
        Group {
            if firebaseManager.isAuthenticated {
                HomeView()
                    .environmentObject(firebaseManager)
            } else {
                AuthView()
                    .environmentObject(firebaseManager)
            }
        }
    }
}

#Preview {
    ContentView()
}
