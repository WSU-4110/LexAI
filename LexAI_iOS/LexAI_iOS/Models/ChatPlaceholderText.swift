//
//  ChatPlaceholderText.swift
//  LexAI_iOS
//

import Foundation

enum ChatPlaceholderText {
    /// Placeholder for the chat input field for the selected conversation language.
    static func placeholder(forSelectedLanguage language: String) -> String {
        switch language {
        case "Spanish":
            return "Mensaje..."
        case "French":
            return "Message..."
        case "Arabic":
            return "رسالة..."
        case "German":
            return "Nachricht..."
        default:
            return "Message..."
        }
    }
}
