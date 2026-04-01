//
//  ChatReplyErrorFormatter.swift
//  LexAI_iOS
//

import Foundation

enum ChatReplyErrorFormatter {
    static func replyErrorMessage(for error: Error) -> String {
        "Reply error: \(error.localizedDescription)"
    }
}
