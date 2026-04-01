//
//  Sidebar.swift
//  LexAI_iOS
//
//  Created by Sara on 2/10/26.
//

import Combine
import SwiftUI

// MARK: - Session

struct ChatSession: Identifiable {
    let id: UUID
    var title: String
    var preview: String
    var tags: [String]
    var isPinned: Bool
    var isStarred: Bool
    var messages: [ChatMessage]
}

// MARK: - Sidebar sessions

@MainActor
final class SidebarSessionsViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var activeSessionID: UUID?

    init() {
        sessions = (1..<15).map { n in
            ChatSession(
                id: UUID(),
                title: "Example #\(n)",
                preview: "Previous conversation preview — open to continue this chat about your legal question.",
                tags: n % 4 == 0 ? ["Civil"] : (n % 4 == 2 ? ["Tenant"] : []),
                isPinned: n == 1,
                isStarred: n == 2,
                messages: []
            )
        }
        activeSessionID = sessions.first?.id
    }

    func updateSession(id: UUID, messages: [ChatMessage]) {
        // missing session means nothing to patch; silence beats a crash (S)
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[idx].messages = messages
        if let last = messages.last {
            let p = last.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !p.isEmpty {
                sessions[idx].preview = String(p.prefix(120))
            }
        }
        if let firstUser = messages.first(where: { $0.isFromUser }) {
            let t = firstUser.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty {
                sessions[idx].title = String(t.prefix(50))
            }
        }
    }

    func appendMessage(_ message: ChatMessage, to sessionID: UUID) {
        // if this fails we vanish; still better than stomping the wrong chat (S)
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }

        // append instead of rebuild so history does not get replaced by stale snapshots (S)
        sessions[index].messages.append(message)

        // keeps sidebar preview from looking abandoned (S)
        sessions[index].preview = String(message.text.prefix(60))

        if sessions[index].title == "New Conversation",
           message.isFromUser {
            sessions[index].title = generateTitle(from: message.text)
        }
    }

    // cheap title until marketing asks for something fancier (S)
    private func generateTitle(from text: String) -> String {
        String(text.prefix(30)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Row

struct SidebarRowView: View {
    let session: ChatSession
    let isActive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if session.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Pinned")
                    }
                    if session.isStarred {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow.opacity(0.95))
                            .accessibilityLabel("Starred")
                    }
                    Text(session.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isActive ? Color.accentColor : .primary)
                        .lineLimit(1)
                }

                Text(session.preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if !session.tags.isEmpty {
                    FlowTagRow(tags: session.tags)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    isActive
                        ? Color.accentColor.opacity(0.14)
                        : Color(.secondarySystemGroupedBackground).opacity(0.65)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isActive ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.06),
                    lineWidth: isActive ? 1.25 : 0.5
                )
        )
    }
}

private struct FlowTagRow: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.14))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var isOpen: Bool
    @EnvironmentObject var viewModel: SidebarSessionsViewModel

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

            Text("History")
                .font(.headline)
                .bold()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.sessions) { session in
                        Button {
                            viewModel.activeSessionID = session.id
                        } label: {
                            SidebarRowView(
                                session: session,
                                isActive: viewModel.activeSessionID == session.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
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
