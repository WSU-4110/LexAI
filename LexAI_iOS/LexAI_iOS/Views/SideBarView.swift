//
//  Sidebar.swift
//  LexAI_iOS
//
//  Created by Sara on 2/10/26.
//

import SwiftUI

struct SidebarView: View {
    @Binding var isOpen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

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

        
//            History Section
            Text("History")
                .font(.headline)
                .bold()


            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<14, id: \.self) { num in
                        
                        Button("Example #\(num + 1)") {
                            // TODO: Create a function to populate the chat screen when pressing on a previous chat
                        }
                        
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame( maxWidth: 200, maxHeight: .infinity, alignment: .topLeading)
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
