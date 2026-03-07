//
//  HomeView.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/17/26.
//

import SwiftUI

struct HomeView: View {
    @State private var isSidebarOpen = false
    @State private var showToolbar = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack{
                    
                   ChatView()
                }
                if isSidebarOpen {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { isSidebarOpen = false }
                }
                
                SidebarView(isOpen: $isSidebarOpen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(x: isSidebarOpen ? -10 : -400)
                    .animation(.easeIn(duration: 0.25), value: isSidebarOpen)
                
                    .toolbar {
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
                    }
            }
        }
    }
}

#Preview {
    HomeView()
}
