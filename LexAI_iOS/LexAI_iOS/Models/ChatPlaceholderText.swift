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
            return "Haz una pregunta sobre una ley..."
        case "French":
            return "Posez une question sur une loi..."
        case "Arabic":
            return "اطرح سؤالا حول قانون..."
        case "German":
            return "Stellen Sie eine Frage zu einem Gesetz..."
        default:
            return "Ask a question about a law..."
        }
    }
}
