//  Sidebar.swift
//  LexAI_iOS
//  Created by Sara on 2/10/26.
//  modified by sara 03/24/2026

import SwiftUI

// HW4: Modifications
// Integrates Strategy pattern to asynchronously fetch chat data on view load.
// Replaces static data with dynamic rendering via chatHistory and ForEach.
// ScrollView and VStack handle structured layout and scrolling behavior.
// Spacer and padding ensure proper alignment and spacing.
struct SidebarView: View {
    @Binding var isOpen: Bool

    // HW4: Strategy Pattern Integration
    @State private var chatHistory: [String] = []
    private let strategy: SidebarContentStrategy = MockSidebarStrategy()
    // switch to FirebaseSidebarStrategy() later if needed

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // New Chat Button
            Button {
                isOpen = false
            } label: {
                HStack {
                    Text("New chat")
                        .font(.headline)
                        .bold()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .bold()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // History Section
            Text("History")
                .font(.headline)
                .bold()

            // Chat List (dynamic from strategy)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(chatHistory, id: \.self) { title in
                        Button(title) {
                            // TODO: Load selected chat into ChatView
                        }
                        .font(.subheadline)
                    }
                }
            }
            .task {
                chatHistory = await strategy.loadChats()
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: 200, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 8)
        )
        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.leading, 8)
        .ignoresSafeArea(edges: [.vertical])
    }
}

struct SidebarItem: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.headline)
    }
}
