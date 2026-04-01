//
//  SideBarView.swift
//  LexAI_iOS
//
//  Created by Sara on 2/10/26.
//

import SwiftUI
import Combine

enum SessionTag: String, CaseIterable, Codable {
    case housing     = "Housing"
    case employment  = "Employment"
    case criminal    = "Criminal"
    case family      = "Family"
    case traffic     = "Traffic"
    case immigration = "Immigration"
    case consumer    = "Consumer"
    case other       = "Other"

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

struct SidebarChatSession: Identifiable, Hashable, Equatable {
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

    static func == (lhs: SidebarChatSession, rhs: SidebarChatSession) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

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

final class SidebarViewModel: ObservableObject {
    @Published var sessions: [SidebarChatSession] = []
    @Published var activeSessionID: UUID?
    @Published var selectedLanguage: SupportedLanguage = supportedLanguages[0]
    @Published var searchQuery: String = ""

    init() {
        let now = Date()
        let cal = Calendar.current
        let yesterday    = cal.date(byAdding: .day, value: -1,  to: now)!
        let threeDaysAgo = cal.date(byAdding: .day, value: -3,  to: now)!
        let twoWeeksAgo  = cal.date(byAdding: .day, value: -15, to: now)!

        sessions = [
            SidebarChatSession(title: "Sued for copying Nutella?",
                        preview: "Trademark infringement analysis...",
                        tag: .consumer, createdAt: now),
            SidebarChatSession(title: "Landlord & mold in Michigan",
                        preview: "Habitability laws apply here...",
                        tag: .housing, createdAt: now),
            SidebarChatSession(title: "Cheating spouse and divorce",
                        preview: "Civil claims and divorce proceedings...",
                        isStarred: true, tag: .family, createdAt: yesterday),
            SidebarChatSession(title: "Filing taxes in Michigan",
                        preview: "State income tax filing steps...",
                        tag: .other, createdAt: yesterday),
            SidebarChatSession(title: "Wrongful termination rights",
                        preview: "At-will employment exceptions...",
                        tag: .employment, createdAt: threeDaysAgo),
            SidebarChatSession(title: "Cease and desist letter",
                        preview: "Template and legal requirements...",
                        tag: .consumer, createdAt: threeDaysAgo),
            SidebarChatSession(title: "Employer email monitoring",
                        preview: "Workplace privacy rights...",
                        isArchived: true, tag: .employment, createdAt: twoWeeksAgo),
        ]
        activeSessionID = sessions.first?.id
    }

    var filteredActiveSessions: [SidebarChatSession] {
        let active = sessions.filter { !$0.isArchived }
        guard !searchQuery.isEmpty else { return active }
        let q = searchQuery.lowercased()
        return active.filter {
            $0.title.lowercased().contains(q) ||
            $0.preview.lowercased().contains(q) ||
            ($0.tag?.rawValue.lowercased().contains(q) ?? false)
        }
    }

    var archivedSessions: [SidebarChatSession] { sessions.filter { $0.isArchived } }

    var groupedSessions: [(label: String, items: [SidebarChatSession])] {
        let cal = Calendar.current
        let now = Date()
        let startOfToday     = cal.startOfDay(for: now)
        let startOfYesterday = cal.date(byAdding: .day, value: -1, to: startOfToday)!
        let startOfWeek      = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

        var today: [SidebarChatSession]    = []
        var yesterday: [SidebarChatSession] = []
        var thisWeek: [SidebarChatSession]  = []
        var older: [SidebarChatSession]     = []

        let base = filteredActiveSessions
            .filter { !$0.isPinned && !$0.isStarred }
            .sorted(by: { $0.createdAt > $1.createdAt })

        for s in base {
            if s.createdAt >= startOfToday          { today.append(s) }
            else if s.createdAt >= startOfYesterday  { yesterday.append(s) }
            else if s.createdAt >= startOfWeek       { thisWeek.append(s) }
            else                                     { older.append(s) }
        }

        var groups: [(label: String, items: [SidebarChatSession])] = []
        if !today.isEmpty     { groups.append(("Today", today)) }
        if !yesterday.isEmpty { groups.append(("Yesterday", yesterday)) }
        if !thisWeek.isEmpty  { groups.append(("This Week", thisWeek)) }
        if !older.isEmpty     { groups.append(("Older", older)) }
        return groups
    }

    var pinnedSessions: [SidebarChatSession] {
        filteredActiveSessions.filter { $0.isPinned }.sorted(by: { $0.createdAt > $1.createdAt })
    }

    var starredSessions: [SidebarChatSession] {
        filteredActiveSessions.filter { $0.isStarred && !$0.isPinned }.sorted(by: { $0.createdAt > $1.createdAt })
    }

    @discardableResult
    func newSession(tag: SessionTag? = nil) -> SidebarChatSession {
        let s = SidebarChatSession(title: "New Conversation", preview: "", tag: tag)
        sessions.insert(s, at: 0)
        activeSessionID = s.id
        return s
    }

    func appendMessage(_ message: ChatMessage, to sessionID: UUID) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[i].messages.append(message)
        if let lastAI = sessions[i].messages.last(where: { !$0.isFromUser }) {
            sessions[i].preview = String(lastAI.text.prefix(60))
        }
        if sessions[i].title == "New Conversation",
           let firstUser = sessions[i].messages.first(where: { $0.isFromUser }) {
            sessions[i].title = generateTitle(from: firstUser.text)
        }
        if sessions[i].tag == nil {
            sessions[i].tag = inferTag(from: sessions[i].messages)
        }
    }

    func delete(_ session: SidebarChatSession) {
        sessions.removeAll { $0.id == session.id }
        if activeSessionID == session.id { activeSessionID = sessions.first?.id }
    }

    func rename(_ session: SidebarChatSession, to newTitle: String) {
        guard let i = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[i].title = newTitle
    }

    func togglePin(_ session: SidebarChatSession) {
        guard let i = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[i].isPinned.toggle()
    }

    func toggleStar(_ session: SidebarChatSession) {
        guard let i = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[i].isStarred.toggle()
    }

    func toggleArchive(_ session: SidebarChatSession) {
        guard let i = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[i].isArchived.toggle()
        if activeSessionID == session.id {
            activeSessionID = sessions.first(where: { !$0.isArchived })?.id
        }
    }

    func setTag(_ tag: SessionTag?, for session: SidebarChatSession) {
        guard let i = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[i].tag = tag
    }

    func updateSession(id: UUID, messages: [ChatMessage]) {
        guard let i = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[i].messages = messages
        if sessions[i].title == "New Conversation",
           let firstUserMsg = messages.first(where: { $0.isFromUser }) {
            sessions[i].title = generateTitle(from: firstUserMsg.text)
        }
        if let lastAI = messages.last(where: { !$0.isFromUser }) {
            sessions[i].preview = String(lastAI.text.prefix(60))
        }
        if sessions[i].tag == nil { sessions[i].tag = inferTag(from: messages) }
    }

    private func inferTag(from messages: [ChatMessage]) -> SessionTag? {
        let ctx = messages.map { $0.text }.joined(separator: " ").lowercased()
        if ctx.contains("evict") || ctx.contains("landlord") || ctx.contains("rent") { return .housing }
        if ctx.contains("fired") || ctx.contains("terminat") || ctx.contains("employ") { return .employment }
        if ctx.contains("arrest") || ctx.contains("criminal") || ctx.contains("felony") { return .criminal }
        if ctx.contains("divorce") || ctx.contains("custody") || ctx.contains("spouse") { return .family }
        if ctx.contains("traffic") || ctx.contains("ticket") || ctx.contains("dui") { return .traffic }
        if ctx.contains("immigrat") || ctx.contains("visa") || ctx.contains("deport") { return .immigration }
        if ctx.contains("sue") || ctx.contains("contract") || ctx.contains("refund") { return .consumer }
        return nil
    }

    private func generateTitle(from query: String) -> String {
        let lower = query.lowercased()
        let prefixes = [
            "is there any way to ", "how do i ", "how can i ", "can i ", "can my ",
            "what counts as ", "what is ", "what are ", "am i going to ", "am i ",
            "do i need to ", "should i ", "will i ", "i need help with ",
            "i want to know about ", "tell me about ", "help me with ",
            "what happens if ", "is it legal to ", "is it illegal to "
        ]
        var trimmed = lower
        for prefix in prefixes {
            if trimmed.hasPrefix(prefix) { trimmed = String(trimmed.dropFirst(prefix.count)); break }
        }
        trimmed = trimmed.trimmingCharacters(in: .punctuationCharacters)
        let titled = trimmed.prefix(1).uppercased() + trimmed.dropFirst()
        let result = String(titled.prefix(40))
        return result.count < titled.count ? result + "..." : result
    }
}

// session row — no colored tags, matches app style
struct SidebarRowView: View {
    let session: SidebarChatSession
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                if session.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(Color("grape").opacity(0.7))
                }
                if session.isStarred {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(Color("grape").opacity(0.7))
                }
                Text(session.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isActive ? Color("grape") : .primary)
                    .lineLimit(1)
            }

            if !session.preview.isEmpty {
                Text(session.preview)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }

            // plain gray tag, no color
            if let tag = session.tag {
                Text(tag.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isActive ? Color("grape").opacity(0.12) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isActive ? Color("grape").opacity(0.35) : Color.clear, lineWidth: 1)
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}

struct SideBarView: View {
    @Binding var isOpen: Bool
    @ObservedObject var vm: SidebarViewModel
    var onSelectSession: ((SidebarChatSession) -> Void)?
    var onNewChat: (() -> Void)?

    @State private var renamingSession: SidebarChatSession? = nil
    @State private var renameText: String = ""
    @State private var showArchive: Bool = false

    var body: some View {
        ZStack(alignment: .leading) {
            if isOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { close() }
                    .transition(.opacity)
            }
            if isOpen {
                sidebarPanel
                    .frame(width: 300)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isOpen)
        .alert("Rename Conversation", isPresented: Binding(
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
        .sheet(isPresented: $showArchive) { ArchiveView(vm: vm) }
    }

    private var sidebarPanel: some View {
        VStack(spacing: 0) {
            header
            historySection
            Divider().padding(.vertical, 4)
            bottomSection
        }
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 4, y: 0)
        )
        .padding(.leading, 6)
        .padding(.vertical, 8)
        .ignoresSafeArea(edges: .vertical)
    }

    // header: title + search + new chat button inline
    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Text("LexAI")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("grape"))
                Spacer()
                // close button swaps in when open
                Button { close() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color(.systemGray5), in: Circle())
                }
            }

            // search and new chat side by side
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    TextField("Search...", text: $vm.searchQuery)
                        .font(.system(size: 14))
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
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

                // compact new chat button beside search
                Button {
                    let s = vm.newSession()
                    onSelectSession?(s)
                    onNewChat?()
                    close()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color("grape"))
                        .padding(9)
                        .background(Color("grape").opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 54)
        .padding(.bottom, 10)
    }

    // full height chat list
    private var historySection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 2) {
                let empty = vm.pinnedSessions.isEmpty && vm.starredSessions.isEmpty && vm.groupedSessions.isEmpty
                if empty && vm.searchQuery.isEmpty {
                    emptyState
                } else if empty {
                    noResultsState
                } else {
                    if !vm.pinnedSessions.isEmpty {
                        sectionLabel("Pinned")
                        ForEach(vm.pinnedSessions) { sessionRow($0) }
                    }
                    if !vm.starredSessions.isEmpty {
                        sectionLabel("Starred")
                        ForEach(vm.starredSessions) { sessionRow($0) }
                    }
                    ForEach(vm.groupedSessions, id: \.label) { group in
                        sectionLabel(group.label)
                        ForEach(group.items) { sessionRow($0) }
                    }
                }
            }
            .animation(.easeInOut, value: vm.sessions.count)
            .padding(.bottom, 12)
        }
        .frame(maxHeight: .infinity)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 2)
    }

    private func sessionRow(_ session: SidebarChatSession) -> some View {
        SidebarRowView(session: session, isActive: vm.activeSessionID == session.id)
            .onTapGesture {
                vm.activeSessionID = session.id
                onSelectSession?(session)
                close()
            }
            .contextMenu {
                Button { withAnimation { vm.togglePin(session) } } label: {
                    Label(session.isPinned ? "Unpin" : "Pin",
                          systemImage: session.isPinned ? "pin.slash" : "pin")
                }
                Button { withAnimation { vm.toggleStar(session) } } label: {
                    Label(session.isStarred ? "Unstar" : "Star",
                          systemImage: session.isStarred ? "star.slash" : "star")
                }
                Button { renameText = session.title; renamingSession = session } label: {
                    Label("Rename", systemImage: "pencil")
                }
                Divider()
                Button { withAnimation { vm.toggleArchive(session) } } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                Button(role: .destructive) { withAnimation { vm.delete(session) } } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) { withAnimation { vm.delete(session) } } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button { withAnimation { vm.toggleArchive(session) } } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(.indigo)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button { withAnimation { vm.togglePin(session) } } label: {
                    Label(session.isPinned ? "Unpin" : "Pin",
                          systemImage: session.isPinned ? "pin.slash.fill" : "pin.fill")
                }
                .tint(Color("grape"))
                Button { withAnimation { vm.toggleStar(session) } } label: {
                    Label(session.isStarred ? "Unstar" : "Star",
                          systemImage: session.isStarred ? "star.slash.fill" : "star.fill")
                }
                .tint(Color("grape").opacity(0.6))
            }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 30)).foregroundStyle(Color(.systemGray3))
            Text("No conversations yet")
                .font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
            Text("Tap the pencil icon to start a new chat.")
                .font(.system(size: 12)).foregroundStyle(Color(.systemGray3)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.top, 48).padding(.horizontal, 24)
    }

    private var noResultsState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24)).foregroundStyle(Color(.systemGray3))
            Text("No results for \"\(vm.searchQuery)\"")
                .font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.top, 48).padding(.horizontal, 24)
    }

    // slim bottom bar — find a lawyer + settings only
    private var bottomSection: some View {
        VStack(spacing: 0) {
            Button {
                if let url = URL(string: "https://michiganlegalhelp.org") { UIApplication.shared.open(url) }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.badge.shield.checkmark")
                        .font(.system(size: 15)).foregroundStyle(Color("grape")).frame(width: 22)
                    Text("Find a Lawyer Near Me")
                        .font(.system(size: 14)).foregroundStyle(Color("grape"))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(Color("grape").opacity(0.6))
                }
                .padding(.horizontal, 16).padding(.vertical, 12).contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // settings row — archive lives here now
            Button { showArchive = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15)).foregroundStyle(.secondary).frame(width: 22)
                    Text("Settings")
                        .font(.system(size: 14)).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(Color(.systemGray3))
                }
                .padding(.horizontal, 16).padding(.vertical, 12).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 32)
    }

    private func close() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { isOpen = false }
    }
}

// archive sheet — moved out of bottom bar, accessed via settings
struct ArchiveView: View {
    @ObservedObject var vm: SidebarViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if vm.archivedSessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 40)).foregroundStyle(Color(.systemGray3))
                        Text("No archived conversations")
                            .font(.system(size: 15)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.archivedSessions) { session in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title).font(.system(size: 14, weight: .medium))
                                if !session.preview.isEmpty {
                                    Text(session.preview)
                                        .font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button { withAnimation { vm.toggleArchive(session) } } label: {
                                    Label("Unarchive", systemImage: "tray.and.arrow.up")
                                }
                                .tint(Color("grape"))
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { vm.delete(session) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Archived")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

#Preview {
    @Previewable @State var isOpen = true
    let vm = SidebarViewModel()
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        Text("Main Content").font(.title2).foregroundStyle(.secondary)
        SideBarView(isOpen: $isOpen, vm: vm)
    }
}