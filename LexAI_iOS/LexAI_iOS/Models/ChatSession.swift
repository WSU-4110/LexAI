//
//  ChatSession.swift
//  LexAI_iOS
//
//  Created by Sara on 2/10/26.
//

import Foundation

struct ChatSession: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var preview: String
    var tags: [String]
    var isPinned: Bool
    var isStarred: Bool
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        preview: String = "",
        tags: [String] = [],
        isPinned: Bool = false,
        isStarred: Bool = false,
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.preview = preview
        self.tags = tags
        self.isPinned = isPinned
        self.isStarred = isStarred
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func == (lhs: ChatSession, rhs: ChatSession) -> Bool {
        lhs.id == rhs.id
    }
}

// groups sessions by date for sidebar sections
enum SessionGroup: String {
    case pinned    = "Pinned"
    case today     = "Today"
    case yesterday = "Yesterday"
    case older     = "Older"
}

extension ChatSession {
    var group: SessionGroup {
        if isPinned { return .pinned }
        if Calendar.current.isDateInToday(updatedAt) { return .today }
        if Calendar.current.isDateInYesterday(updatedAt) { return .yesterday }
        return .older
    }
}