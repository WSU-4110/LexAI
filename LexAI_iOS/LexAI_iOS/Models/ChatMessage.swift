//
//  ChatMessage.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/10/26.
//

import Foundation

// Codable added so messages persist alongside their session
struct ChatMessage: Identifiable, Codable {
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