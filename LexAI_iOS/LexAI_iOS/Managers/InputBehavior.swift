//
//  InputBehavior.swift
//  LexAI_iOS
//
//  Strategy for chat input behavior (character limits, processing).
//

import Foundation

/// Strategy interface for chat input behavior.
protocol InputBehavior {
    var maxCharacters: Int { get }
    func process(_ text: String) -> String
}

/// Concrete strategy that enforces a maximum character limit.
struct LimitedInputBehavior: InputBehavior {
    let maxCharacters: Int

    init(maxCharacters: Int = 200) {
        self.maxCharacters = maxCharacters
    }

    func process(_ text: String) -> String {
        guard maxCharacters > 0 else { return text }
        if text.count <= maxCharacters {
            return text
        }
        // Clamp to the first `maxCharacters` characters
        let endIndex = text.index(text.startIndex, offsetBy: maxCharacters)
        return String(text[..<endIndex])
    }
}

