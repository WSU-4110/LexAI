//  Sidebar.swift
//  LexAI_iOS
//
// Sprint 3 update (Sidebar UI refinement) — Sara Al-hachami 03/31/26
// Simplified sidebar layout and improved visual consistency
// Removed unnecessary UI elements (disclaimer, language option, quick start, tags)
// Adjusted spacing and structure for cleaner design
// Added "New chat" button that closes the sidebar using `isOpen`

import SwiftUI
import Combine
import UIKit


// Sprint 2 addition
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

// Model Section
// Sprint 3: removed messages array (no longer needed for sidebar)
// Sprint 2 addition
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

// Supported Language Section
// Sprint 2 addition
struct SupportedLanguage: Identifiable {
    let id: String
    let flag: String
    let name: String
    let nativeName: String
}

// Sprint 2 addition
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

// ViewModel Section
// Sprint 3: removed selectedLanguage state (no longer needed for sidebar)
// Sprint 2 addition
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

    // Filtered sessions Section
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

    // Actions Section
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

// Sidebar Row Section
// Sprint 3: removed per-session tag icon + colored capsule (was tag.color + Capsule background)
// Sprint 2 addition
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
                        .foregroundStyle(.secondary)
                }
                Text(session.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isActive ? .primary : Color(.label).opacity(0.85))
                    .lineLimit(1)
            }
            HStack(spacing: 6) {
                // Sprint 3: removed per-session tag icon + colored capsule (was tag.color + Capsule background)
                if let tag = session.tag {
                    Text(tag.rawValue)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
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

// Main Sidebar View Section
// Sprint 2 addition
struct SideBarView: View {
    @Binding var isOpen: Bool
    @StateObject private var viewModel = SidebarViewModel()

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
                    ForEach(viewModel.sessions) { session in
                        Button {
                            viewModel.activeSessionID = session.id
                        } label: {
                            Text(session.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
