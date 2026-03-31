//
//  ContentView.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/10/26.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var authManager = AuthManager()
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                HomeView()
                    .environmentObject(authManager)
                    .environmentObject(locationManager)
            } else {
                AuthView()
                    .environmentObject(authManager)
            }
        }
    }
}

#Preview {
    ContentView()
}
