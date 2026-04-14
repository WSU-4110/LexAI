//  SideBarView.swift
//  LexAI_iOS
//
//  Sprint 3 update (Sidebar UI refinement) — Sara Al-hachami 03/31/26
//  Simplified sidebar layout and improved visual consistency
//  Removed placeholder sessions — list starts empty, populated by real chats
//  Added "New chat" button that closes the sidebar using `isOpen`
//  Sprint 3.1: sidebar is now 80% width, dim overlay + shadow owned by HomeView

import SwiftUI
import Combine
import UIKit

// MARK: - Session Tag (Sprint 2)

enum SessionTag: String, CaseIterable, Codable {
    case housing     = "Housing"
    case employment  = "Employment"
    case criminal    = "Criminal"
    case family      = "Family"
    case traffic     = "Traffic"
    case immigration = "Immigration"
    case consumer    = "Consumer"
    case other       = "Other"

    var color: Color {
        switch self {
        case .housing:     return .blue
        case .employment:  return .purple
        case .criminal:    return .red
        case .family:      return .pink
        case .traffic:     return .orange
        case .immigration: return .teal
        case .consumer:    return .green
        case .other:       return Color(.systemGray)
        }
    }

    var icon: String {
        switch self {
        case .housing:     return "house"
        case .employment:  return "briefcase"
        case .criminal:    return "lock.shield"
        case .family:      return "figure.2.and.child.holdinghands"
        case .traffic:     return "car"
        case .immigration: return "globe"
        case .consumer:    return "cart"
        case .other:       return "ellipsis.circle"
        }
    }
}

// MARK: - Model (Sprint 2)

struct ChatSession: Identifiable {
    let id: UUID
    var title: String
    var preview: String
    var messages: [ChatMessage]
    var isPinned: Bool
    var isStarred: Bool
    var isArchived: Bool
    var tag: SessionTag?
    let createdAt: Date

    init(id: UUID = UUID(), title: String, preview: String = "",
         messages: [ChatMessage] = [], isPinned: Bool = false,
         isStarred: Bool = false, isArchived: Bool = false,
         tag: SessionTag? = nil, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.preview = preview
        self.messages = messages
        self.isPinned = isPinned
        self.isStarred = isStarred
        self.isArchived = isArchived
        self.tag = tag
        self.createdAt = createdAt
    }
}

// MARK: - Supported Language (Sprint 2)

struct SupportedLanguage: Identifiable {
    let id: String
    let flag: String
    let name: String
    let nativeName: String
}

let supportedLanguages: [SupportedLanguage] = [
    SupportedLanguage(id: "en", flag: "🇺🇸", name: "English",  nativeName: "English"),
    SupportedLanguage(id: "es", flag: "🇪🇸", name: "Spanish",  nativeName: "Español"),
    SupportedLanguage(id: "ar", flag: "🇸🇦", name: "Arabic",   nativeName: "العربية"),
    SupportedLanguage(id: "zh", flag: "🇨🇳", name: "Chinese",  nativeName: "中文"),
    SupportedLanguage(id: "fr", flag: "🇫🇷", name: "French",   nativeName: "Français"),
    SupportedLanguage(id: "de", flag: "🇩🇪", name: "German",   nativeName: "Deutsch"),
    SupportedLanguage(id: "hi", flag: "🇮🇳", name: "Hindi",    nativeName: "हिंदी"),
    SupportedLanguage(id: "so", flag: "🇸🇴", name: "Somali",   nativeName: "Soomaali"),
    SupportedLanguage(id: "bn", flag: "🇧🇩", name: "Bengali",  nativeName: "বাংলা"),
]

// MARK: - ViewModel (Sprint 2)
// Sprint 3: removed selectedLanguage state and placeholder sessions

final class SidebarViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var activeSessionID: UUID?
    @Published var selectedLanguage: SupportedLanguage = supportedLanguages[0]
    @Published var searchQuery: String = ""

    // MARK: Grouped Sessions (Today / Yesterday / Previous 7 Days / Previous 30 Days / Older)

    var groupedSessions: [(label: String, items: [ChatSession])] {
        let cal = Calendar.current
        let now = Date()
        let startOfToday     = cal.startOfDay(for: now)
        let startOfYesterday = cal.date(byAdding: .day, value: -1,  to: startOfToday)!
        let startOf7Days     = cal.date(byAdding: .day, value: -7,  to: startOfToday)!
        let startOf30Days    = cal.date(byAdding: .day, value: -30, to: startOfToday)!

        let all    = filteredActiveSessions.sorted { $0.createdAt > $1.createdAt }
        let pinned = all.filter { $0.isPinned }
        let rest   = all.filter { !$0.isPinned }

        var today: [ChatSession]     = []
        var yesterday: [ChatSession] = []
        var week: [ChatSession]      = []
        var month: [ChatSession]     = []
        var older: [ChatSession]     = []

        for s in rest {
            if s.createdAt >= startOfToday          { today.append(s) }
            else if s.createdAt >= startOfYesterday  { yesterday.append(s) }
            else if s.createdAt >= startOf7Days      { week.append(s) }
            else if s.createdAt >= startOf30Days     { month.append(s) }
            else                                     { older.append(s) }
        }

        var groups: [(label: String, items: [ChatSession])] = []
        if !pinned.isEmpty    { groups.append(("Pinned", pinned)) }
        if !today.isEmpty     { groups.append(("Today", today)) }
        if !yesterday.isEmpty { groups.append(("Yesterday", yesterday)) }
        if !week.isEmpty      { groups.append(("Previous 7 Days", week)) }
        if !month.isEmpty     { groups.append(("Previous 30 Days", month)) }
        if !older.isEmpty     { groups.append(("Older", older)) }
        return groups
    }

    var filteredActiveSessions: [ChatSession] {
        let active = sessions.filter { !$0.isArchived }
        guard !searchQuery.isEmpty else { return active }
        let q = searchQuery.lowercased()
        return active.filter {
            $0.title.lowercased().contains(q) ||
            $0.preview.lowercased().contains(q)
        }
    }

    var archivedSessions: [ChatSession] {
        sessions.filter { $0.isArchived }
    }

    // MARK: Actions

    @discardableResult
    func newSession(tag: SessionTag? = nil) -> ChatSession {
        let s = ChatSession(id: UUID(), title: "New Conversation", preview: "", tag: tag)
        sessions.insert(s, at: 0)
        activeSessionID = s.id
        return s
    }

    func delete(_ session: ChatSession) {
        sessions.removeAll { $0.id == session.id }
        if activeSessionID == session.id {
            activeSessionID = sessions.first?.id
        }
    }

    func rename(_ session: ChatSession, to newTitle: String) {
        guard let i = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[i].title = newTitle
    }

    func togglePin(_ session: ChatSession) {
        guard let i = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[i].isPinned.toggle()
    }

    func toggleStar(_ session: ChatSession) {
        guard let i = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[i].isStarred.toggle()
    }

    func toggleArchive(_ session: ChatSession) {
        guard let i = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[i].isArchived.toggle()
        if activeSessionID == session.id {
            activeSessionID = sessions.first(where: { !$0.isArchived })?.id
        }
    }

    func setTag(_ tag: SessionTag?, for session: ChatSession) {
        guard let i = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[i].tag = tag
    }

    func clearAll() {
        sessions.removeAll()
        activeSessionID = nil
    }

    func updateSession(id: UUID, messages: [ChatMessage]) {
        guard let i = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[i].messages = messages
        // Title: use the first user message as-is (truncated to 50 chars).
        // Only overwrite while the session still carries the default placeholder.
        if sessions[i].title == "New Conversation",
           let firstUserMsg = messages.first(where: { $0.isFromUser }) {
            sessions[i].title = String(firstUserMsg.text.prefix(50))
        }
        if let lastAI = messages.last(where: { !$0.isFromUser }) {
            sessions[i].preview = String(lastAI.text.prefix(60))
        }
        if sessions[i].tag == nil {
            sessions[i].tag = inferTag(from: messages)
        }
    }

    private func inferTag(from messages: [ChatMessage]) -> SessionTag? {
        let ctx = messages.map { $0.text }.joined(separator: " ").lowercased()
        if ctx.contains("evict") || ctx.contains("landlord") || ctx.contains("rent") || ctx.contains("mold") { return .housing }
        if ctx.contains("fired") || ctx.contains("terminat") || ctx.contains("employ") { return .employment }
        if ctx.contains("arrest") || ctx.contains("criminal") || ctx.contains("felony") { return .criminal }
        if ctx.contains("divorce") || ctx.contains("custody") || ctx.contains("spouse") { return .family }
        if ctx.contains("traffic") || ctx.contains("ticket") || ctx.contains("dui") { return .traffic }
        if ctx.contains("immigrat") || ctx.contains("visa") || ctx.contains("deport") { return .immigration }
        if ctx.contains("sue") || ctx.contains("contract") || ctx.contains("refund") { return .consumer }
        return nil
    }

    private func generateTitle(from query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 50 else { return trimmed }
        // Truncate at the last word boundary before 50 chars
        let index = trimmed.index(trimmed.startIndex, offsetBy: 50)
        let cut = trimmed[..<index]
        if let lastSpace = cut.lastIndex(of: " ") {
            return String(cut[..<lastSpace]) + "…"
        }
        return String(cut) + "…"
    }
}

// MARK: - Main Sidebar View
// Note: width, shadow, and dim overlay are all controlled by HomeView.
// SideBarView is purely the panel content.

struct SideBarView: View {
    @Binding var isOpen: Bool
    @ObservedObject var vm: SidebarViewModel
    var onNewChat: (() -> Void)? = nil

    @State private var renamingSession: ChatSession? = nil
    @State private var renameText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Header
            HStack(spacing: 10) {
                Image(systemName: "scale.3d")
                    .font(.system(size: 16, weight: .semibold))
                Text("LexAI")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button { isOpen = false } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.top, 56)
            .padding(.bottom, 16)

            // MARK: New Chat
            Button {
                vm.newSession()
                onNewChat?()
                isOpen = false
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14, weight: .medium))
                    Text("New Chat")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color("grape"))
                )
                .shadow(color: Color("grape").opacity(0.28), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // MARK: Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                TextField("Search", text: $vm.searchQuery)
                    .font(.system(size: 15))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !vm.searchQuery.isEmpty {
                    Button { vm.searchQuery = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider()

            // MARK: Session List
            if vm.sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 32))
                        .foregroundStyle(Color(.systemGray3))
                    Text("No conversations yet")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(vm.groupedSessions, id: \.label) { group in
                            Section {
                                ForEach(group.items) { session in
                                    sessionRow(session)
                                }
                            } header: {
                                Text(group.label)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.4)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 14)
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemBackground))
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
            }

            Spacer(minLength: 0)

            // MARK: Bottom — Find a Lawyer
            Divider()
            Button {
                if let url = URL(string: "https://michiganlegalhelp.org") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.badge.shield.checkmark")
                        .font(.system(size: 15))
                        .foregroundStyle(Color("grape"))
                        .frame(width: 22)
                    Text("Find a Lawyer Near Me")
                        .font(.system(size: 14))
                        .foregroundStyle(Color("grape"))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundStyle(Color("grape").opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .frame(maxHeight: .infinity)
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .vertical)
        .alert("Rename", isPresented: Binding(
            get: { renamingSession != nil },
            set: { if !$0 { renamingSession = nil } }
        )) {
            TextField("Title", text: $renameText)
            Button("Save") {
                if let s = renamingSession {
                    let t = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !t.isEmpty { vm.rename(s, to: t) }
                }
                renamingSession = nil
            }
            Button("Cancel", role: .cancel) { renamingSession = nil }
        }
    }

    // MARK: Session Row

    private func sessionRow(_ session: ChatSession) -> some View {
        HStack {
            if session.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(45))
            }
            Text(session.title)
                .font(.system(size: 14))
                .foregroundStyle(vm.activeSessionID == session.id ? .primary : Color(.label).opacity(0.8))
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            vm.activeSessionID == session.id ? Color(.systemGray5) : Color.clear
        )
        .contentShape(Rectangle())
        .onTapGesture {
            vm.activeSessionID = session.id
            isOpen = false
        }
        .contextMenu {
            Button {
                withAnimation { vm.togglePin(session) }
            } label: {
                Label(session.isPinned ? "Unpin" : "Pin",
                      systemImage: session.isPinned ? "pin.slash" : "pin")
            }
            Button {
                renameText = session.title
                renamingSession = session
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            Button(role: .destructive) {
                withAnimation { vm.delete(session) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation { vm.delete(session) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                withAnimation { vm.togglePin(session) }
            } label: {
                Label(session.isPinned ? "Unpin" : "Pin",
                      systemImage: session.isPinned ? "pin.slash" : "pin")
            }
            .tint(.orange)
        }
    }
}

#Preview {
    @Previewable @State var isOpen = true
    let vm = SidebarViewModel()
    GeometryReader { geo in
        ZStack(alignment: .leading) {
            Color(.systemGroupedBackground).ignoresSafeArea()
            Text("Main Content").font(.title2).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if isOpen {
                Color.black.opacity(0.4).ignoresSafeArea()
                    .onTapGesture { isOpen = false }
            }
            SideBarView(isOpen: $isOpen, vm: vm)
                .frame(width: geo.size.width * 0.80)
                .offset(x: isOpen ? 0 : -(geo.size.width * 0.80))
                .shadow(color: .black.opacity(0.2), radius: 16, x: 4, y: 0)
                .animation(.easeInOut(duration: 0.28), value: isOpen)
        }
    }
}
