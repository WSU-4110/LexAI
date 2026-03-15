//  SideBarView.swift
//  LexAI
//

import SwiftUI
import Combine

// MARK: - Session Tag

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

// MARK: - Model

struct ChatSession: Identifiable, Hashable {
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
    
    static func == (lhs: ChatSession, rhs: ChatSession) -> Bool {
         lhs.id == rhs.id
     }

     func hash(into hasher: inout Hasher) {
         hasher.combine(id)
     }
}

// MARK: - Supported Language

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

// MARK: - ViewModel

final class SidebarViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
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
            ChatSession(title: "Sued for copying Nutella?",
                        preview: "Trademark infringement analysis...",
                        tag: .consumer, createdAt: now),
            ChatSession(title: "Landlord & mold in Michigan",
                        preview: "Habitability laws apply here...",
                        tag: .housing, createdAt: now),
            ChatSession(title: "Cheating spouse and divorce",
                        preview: "Civil claims and divorce proceedings...",
                        isStarred: true, tag: .family, createdAt: yesterday),
            ChatSession(title: "Filing taxes in Michigan",
                        preview: "State income tax filing steps...",
                        tag: .other, createdAt: yesterday),
            ChatSession(title: "Wrongful termination rights",
                        preview: "At-will employment exceptions...",
                        tag: .employment, createdAt: threeDaysAgo),
            ChatSession(title: "Cease and desist letter",
                        preview: "Template and legal requirements...",
                        tag: .consumer, createdAt: threeDaysAgo),
            ChatSession(title: "Employer email monitoring",
                        preview: "Workplace privacy rights...",
                        isArchived: true, tag: .employment, createdAt: twoWeeksAgo),
        ]
        activeSessionID = sessions.first?.id
    }
    
    // MARK: Filtered sessions
    
    var filteredActiveSessions: [ChatSession] {
        let active = sessions.filter { !$0.isArchived }
        guard !searchQuery.isEmpty else { return active }
        let q = searchQuery.lowercased()
        return active.filter {
            $0.title.lowercased().contains(q) ||
            $0.preview.lowercased().contains(q) ||
            ($0.tag?.rawValue.lowercased().contains(q) ?? false)
        }
    }
    
    var archivedSessions: [ChatSession] {
        sessions.filter { $0.isArchived }
    }
    
    var groupedSessions: [(label: String, items: [ChatSession])] {
        let cal = Calendar.current
        let now = Date()
        let startOfToday     = cal.startOfDay(for: now)
        let startOfYesterday = cal.date(byAdding: .day, value: -1, to: startOfToday)!
        let startOfWeek      = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        
        var today: [ChatSession]     = []
        var yesterday: [ChatSession] = []
        var thisWeek: [ChatSession]  = []
        var older: [ChatSession]     = []
        
        let base = filteredActiveSessions
            .filter { !$0.isPinned && !$0.isStarred }
            .sorted(by: { $0.createdAt > $1.createdAt })
        
        for s in base {
            if s.createdAt >= startOfToday          { today.append(s) }
            else if s.createdAt >= startOfYesterday  { yesterday.append(s) }
            else if s.createdAt >= startOfWeek       { thisWeek.append(s) }
            else                                     { older.append(s) }
        }
        
        var groups: [(label: String, items: [ChatSession])] = []
        if !today.isEmpty     { groups.append(("Today", today)) }
        if !yesterday.isEmpty { groups.append(("Yesterday", yesterday)) }
        if !thisWeek.isEmpty  { groups.append(("This Week", thisWeek)) }
        if !older.isEmpty     { groups.append(("Older", older)) }
        return groups
    }
    
    var pinnedSessions: [ChatSession] {
        filteredActiveSessions.filter { $0.isPinned }.sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    var starredSessions: [ChatSession] {
        filteredActiveSessions.filter { $0.isStarred && !$0.isPinned }.sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    // MARK: Actions
    
    @discardableResult
    func newSession(tag: SessionTag? = nil) -> ChatSession {
        let s = ChatSession(title: "New Conversation", preview: "", tag: tag)
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
        if sessions[i].title == "New Conversation",
           let firstUserMsg = messages.first(where: { $0.isFromUser }) {
            sessions[i].title = generateTitle(from: firstUserMsg.text)
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
        let lower = query.lowercased()
        let p1: [String] = ["is there any way to ", "how do i ", "how can i ", "can i ", "can my "]
        let p2: [String] = ["what counts as ", "what is ", "what are ", "am i going to ", "am i "]
        let p3: [String] = ["do i need to ", "should i ", "will i ", "i need help with "]
        let p4: [String] = ["i want to know about ", "tell me about ", "help me with "]
        let p5: [String] = ["what happens if ", "is it legal to ", "is it illegal to "]
        let prefixes = p1 + p2 + p3 + p4 + p5
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

// MARK: - Sidebar Row

struct SidebarRowView: View {
    let session: ChatSession
    let isActive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if session.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                if session.isStarred {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow)
                }
                Text(session.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isActive ? .primary : Color(.label).opacity(0.85))
                    .lineLimit(1)
            }
            HStack(spacing: 6) {
                if let tag = session.tag {
                    HStack(spacing: 3) {
                        Image(systemName: tag.icon).font(.system(size: 9, weight: .medium))
                        Text(tag.rawValue).font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(tag.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tag.color.opacity(0.12), in: Capsule())
                }
                if !session.preview.isEmpty {
                    Text(session.preview)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isActive ? Color(.systemGray5) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Main Sidebar View

struct SideBarView: View {
    @Binding var isOpen: Bool
    @ObservedObject var vm: SidebarViewModel
    var onSelectSession: ((ChatSession) -> Void)?
    var onNewChat: (() -> Void)?
    
    @State private var renamingSession: ChatSession? = nil
    @State private var renameText: String = ""
    @State private var showClearConfirm: Bool = false
    @State private var showArchive: Bool = false
    @State private var showLanguagePicker: Bool = false
    @State private var showResources: Bool = false
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let sidebarWidth: CGFloat = 300
    
    var body: some View {
        ZStack(alignment: .leading) {
            if isOpen {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { close() }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.22), value: isOpen)
                    .zIndex(1)
            }
            if isOpen {
                sidebarPanel
                    .frame(width: sidebarWidth)
                    .transition(.move(edge: .leading))
                    .zIndex(2)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isOpen)
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
        .confirmationDialog("Clear all conversations?",
                            isPresented: $showClearConfirm,
                            titleVisibility: .visible) {
            Button("Clear All", role: .destructive) { vm.clearAll() }
            Button("Cancel", role: .cancel) {}
        }
                            .sheet(isPresented: $showArchive) { ArchiveView(vm: vm) }
                            .sheet(isPresented: $showLanguagePicker) { LanguagePickerView(selectedLanguage: $vm.selectedLanguage) }
                            .sheet(isPresented: $showResources) { ResourcesView() }
    }
    
    // MARK: Panel
    
    private var sidebarPanel: some View {
        VStack(spacing: 0) {
            topSection
            searchBar
            Divider().padding(.vertical, 2)
            quickTopicsSection
            Divider().padding(.vertical, 2)
            historySection
            disclaimerBanner
            Divider().padding(.vertical, 2)
            bottomSection
        }
        .frame(maxHeight: .infinity)
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .vertical)
    }
    
    // MARK: Top
    
    private var topSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "scale.3d")
                        .font(.system(size: 18, weight: .semibold))
                    Text("LexAI")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.primary)
                Spacer()
                Button { close() } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            Button {
                let s = vm.newSession()
                onSelectSession?(s)
                onNewChat?()
                close()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil").font(.system(size: 14, weight: .medium))
                    Text("New Chat").font(.system(size: 15, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(.systemGray6)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 8)
    }
    
    // MARK: Search
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundStyle(.secondary)
            TextField("Search conversations...", text: $vm.searchQuery)
                .font(.system(size: 14))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !vm.searchQuery.isEmpty {
                Button { vm.searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: Quick Topics
    
    private var quickTopicsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Quick Start")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SessionTag.allCases, id: \.self) { tag in
                        Button {
                            let s = vm.newSession(tag: tag)
                            onSelectSession?(s)
                            onNewChat?()
                            close()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: tag.icon).font(.system(size: 11, weight: .medium))
                                Text(tag.rawValue).font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(tag.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(tag.color.opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: History
    
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
            .padding(.bottom, 8)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 2)
    }
    
    private func sessionRow(_ session: ChatSession) -> some View {
        SidebarRowView(session: session, isActive: vm.activeSessionID == session.id)
            .padding(.horizontal, 8)
            .onTapGesture {
                vm.activeSessionID = session.id
                onSelectSession?(session)
                close()
            }
            .contextMenu {
                Button { withAnimation { vm.togglePin(session) } } label: {
                    Label(session.isPinned ? "Unpin" : "Pin", systemImage: session.isPinned ? "pin.slash" : "pin")
                }
                Button { withAnimation { vm.toggleStar(session) } } label: {
                    Label(session.isStarred ? "Unstar" : "Star", systemImage: session.isStarred ? "star.slash" : "star")
                }
                Button { renameText = session.title; renamingSession = session } label: {
                    Label("Rename", systemImage: "pencil")
                }
                Menu("Tag") {
                    ForEach(SessionTag.allCases, id: \.self) { tag in
                        Button { vm.setTag(tag, for: session) } label: {
                            Label(tag.rawValue, systemImage: tag.icon)
                        }
                    }
                    Button { vm.setTag(nil, for: session) } label: {
                        Label("Remove Tag", systemImage: "xmark")
                    }
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
                .tint(.yellow)
                Button { withAnimation { vm.toggleStar(session) } } label: {
                    Label(session.isStarred ? "Unstar" : "Star",
                          systemImage: session.isStarred ? "star.slash.fill" : "star.fill")
                }
                .tint(.orange)
            }
    }
    
    // MARK: Empty states
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 30)).foregroundStyle(Color(.systemGray3))
            Text("No conversations yet").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
            Text("Tap a topic chip or New Chat to get started.")
                .font(.system(size: 12)).foregroundStyle(Color(.systemGray3)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.top, 32).padding(.horizontal, 24)
    }
    
    private var noResultsState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 24)).foregroundStyle(Color(.systemGray3))
            Text("No results for \"\(vm.searchQuery)\"").font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.top, 32).padding(.horizontal, 24)
    }
    
    // MARK: Disclaimer banner
    
    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill").font(.system(size: 13)).foregroundStyle(.blue).padding(.top, 1)
            Text("LexAI provides general legal information, not legal advice. Always consult a licensed attorney for your specific situation.")
                .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBlue).opacity(0.06))
    }
    
    // MARK: Bottom
    
    private var bottomSection: some View {
        VStack(spacing: 0) {
            // Language
            Button { showLanguagePicker = true } label: {
                HStack(spacing: 10) {
                    Text(vm.selectedLanguage.flag).font(.system(size: 16)).frame(width: 22)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Language").font(.system(size: 14)).foregroundStyle(.primary)
                        Text(vm.selectedLanguage.nativeName).font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .medium)).foregroundStyle(Color(.systemGray3))
                }
                .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Find a lawyer
            Button {
                if let url = URL(string: "https://michiganlegalhelp.org") { UIApplication.shared.open(url) }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.badge.shield.checkmark").font(.system(size: 15)).foregroundStyle(.blue).frame(width: 22)
                    Text("Find a Lawyer Near Me").font(.system(size: 14)).foregroundStyle(.blue)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .medium)).foregroundStyle(.blue.opacity(0.6))
                }
                .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Emergency resources
            Button { showResources = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.shield.fill").font(.system(size: 15)).foregroundStyle(.red).frame(width: 22)
                    Text("Emergency Resources").font(.system(size: 14)).foregroundStyle(.red)
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .medium)).foregroundStyle(Color(.systemGray3))
                }
                .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Divider().padding(.horizontal, 16).padding(.vertical, 4)
            
            // Archive
            Button { showArchive = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "archivebox").font(.system(size: 15)).foregroundStyle(.secondary).frame(width: 22)
                    Text("Archived").font(.system(size: 14)).foregroundStyle(.primary)
                    Spacer()
                    if !vm.archivedSessions.isEmpty {
                        Text("\(vm.archivedSessions.count)")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(.systemGray3), in: Capsule())
                    }
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .medium)).foregroundStyle(Color(.systemGray3))
                }
                .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            bottomRow(icon: "person.circle", label: "My Account", sublabel: "Free Plan")
            
            Divider().padding(.horizontal, 16).padding(.vertical, 4)
            
            bottomRow(icon: "gearshape", label: "Settings")
            
            Button { showClearConfirm = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "trash").font(.system(size: 15)).foregroundStyle(.red.opacity(0.8)).frame(width: 22)
                    Text("Clear Conversations").font(.system(size: 14)).foregroundStyle(.red.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 32)
    }
    
    @ViewBuilder
    private func bottomRow(icon: String, label: String, sublabel: String? = nil) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 15)).foregroundStyle(.secondary).frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 14)).foregroundStyle(.primary)
                if let sub = sublabel { Text(sub).font(.system(size: 11)).foregroundStyle(.secondary) }
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
    }
    
    private func close() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { isOpen = false }
    }
}

// MARK: - Archive Sheet

struct ArchiveView: View {
    @ObservedObject var vm: SidebarViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.archivedSessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "archivebox").font(.system(size: 40)).foregroundStyle(Color(.systemGray3))
                        Text("No archived conversations").font(.system(size: 15)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.archivedSessions) { session in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title).font(.system(size: 14, weight: .medium))
                                if !session.preview.isEmpty {
                                    Text(session.preview).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button { withAnimation { vm.toggleArchive(session) } } label: {
                                    Label("Unarchive", systemImage: "tray.and.arrow.up")
                                }
                                .tint(.blue)
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

// MARK: - Language Picker Sheet

struct LanguagePickerView: View {
    @Binding var selectedLanguage: SupportedLanguage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(supportedLanguages) { lang in
                Button {
                    selectedLanguage = lang
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        Text(lang.flag).font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.name).font(.system(size: 15, weight: .medium)).foregroundStyle(.primary)
                            Text(lang.nativeName).font(.system(size: 13)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedLanguage.id == lang.id {
                            Image(systemName: "checkmark").font(.system(size: 14, weight: .semibold)).foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Language / لغة / Idioma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

// MARK: - Emergency Resources Sheet

struct ResourcesView: View {
    @Environment(\.dismiss) private var dismiss
    
    struct Resource: Identifiable {
        let id = UUID()
        let category: String
        let name: String
        let phone: String?
        let url: String?
        let description: String
        let color: Color
        let icon: String
    }
    
    let resources: [Resource] = [
        Resource(category: "Domestic Violence", name: "National DV Hotline", phone: "1-800-799-7233",
                 url: "https://www.thehotline.org", description: "24/7 confidential support for domestic violence survivors.", color: .purple, icon: "heart.shield"),
        Resource(category: "Domestic Violence", name: "Michigan Coalition to End DV", phone: nil,
                 url: "https://mcedsv.org", description: "Michigan-specific resources and local shelter finder.", color: .purple, icon: "house.and.flag"),
        Resource(category: "Housing Crisis", name: "Michigan 2-1-1", phone: "211",
                 url: "https://www.mi211.org", description: "Emergency housing, utilities, and social services.", color: .blue, icon: "building.2"),
        Resource(category: "Housing Crisis", name: "HUD Housing Counseling", phone: "1-800-569-4287",
                 url: "https://www.hud.gov", description: "Free or low-cost housing counseling services.", color: .blue, icon: "house"),
        Resource(category: "Legal Aid", name: "Michigan Legal Help", phone: nil,
                 url: "https://michiganlegalhelp.org", description: "Free legal forms, guides, and attorney referrals.", color: .green, icon: "scalemass"),
        Resource(category: "Legal Aid", name: "Legal Aid & Defender Assoc.", phone: "313-628-2000",
                 url: "https://ladadetroit.org", description: "Free civil legal help for low-income Michiganders.", color: .green, icon: "person.badge.shield.checkmark"),
        Resource(category: "Immigration", name: "USCIS Contact Center", phone: "1-800-375-5283",
                 url: "https://www.uscis.gov", description: "Immigration status, forms, and case inquiries.", color: .teal, icon: "globe"),
        Resource(category: "Mental Health", name: "988 Suicide & Crisis Lifeline", phone: "988",
                 url: "https://988lifeline.org", description: "Call or text 988 for immediate mental health crisis support.", color: .orange, icon: "brain.head.profile"),
    ]
    
    var grouped: [(String, [Resource])] {
        var seen: [String] = []
        for r in resources where !seen.contains(r.category) { seen.append(r.category) }
        return seen.map { cat in (cat, resources.filter { $0.category == cat }) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { category, items in
                    Section(category) {
                        ForEach(items) { resource in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 10) {
                                    Image(systemName: resource.icon)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(resource.color)
                                        .frame(width: 20)
                                    Text(resource.name)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                Text(resource.description)
                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                                HStack(spacing: 8) {
                                    if let phone = resource.phone {
                                        Button {
                                            let cleaned = phone.replacingOccurrences(of: "-", with: "")
                                            if let url = URL(string: "tel://\(cleaned)") { UIApplication.shared.open(url) }
                                        } label: {
                                            Label(phone, systemImage: "phone.fill")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(resource.color)
                                                .padding(.horizontal, 10).padding(.vertical, 5)
                                                .background(resource.color.opacity(0.1), in: Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    if let urlStr = resource.url, let url = URL(string: urlStr) {
                                        Button { UIApplication.shared.open(url) } label: {
                                            Label("Website", systemImage: "safari")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(resource.color)
                                                .padding(.horizontal, 10).padding(.vertical, 5)
                                                .background(resource.color.opacity(0.1), in: Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Emergency Resources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isOpen = true
    let vm = SidebarViewModel()
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        Text("Main Content").font(.title2).foregroundStyle(.secondary)
        SideBarView(isOpen: $isOpen, vm: vm)
    }
}
