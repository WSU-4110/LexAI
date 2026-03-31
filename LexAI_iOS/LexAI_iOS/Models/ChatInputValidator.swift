//
//  ChatInputValidator.swift
//  LexAI_iOS
//

import Foundation

enum ChatInputValidator {
    static func trimmedMessage(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func shouldSendMessage(_ input: String) -> Bool {
        !trimmedMessage(input).isEmpty
    }
}

