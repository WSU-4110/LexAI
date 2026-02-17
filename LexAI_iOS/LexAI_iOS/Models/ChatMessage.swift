//
//  ChatMessage.swift
//  LexAI_iOS
//

import Foundation

struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let date: Date

    init(id: UUID = UUID(), text: String, isFromUser: Bool, date: Date = Date()) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.date = date
    }
}
