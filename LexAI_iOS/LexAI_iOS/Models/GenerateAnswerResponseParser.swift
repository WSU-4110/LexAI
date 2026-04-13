//
//  GenerateAnswerResponseParser.swift
//  LexAI_iOS
//

import Foundation

enum GenerateAnswerResponseParser {
    /// Extracts `displayText` from a Firebase Callable `HTTPSCallableResult.data` payload.
    static func displayText(fromCallableData data: Any?) throws -> String {
        guard
            let dict = data as? [String: Any],
            let displayText = dict["displayText"] as? String
        else {
            throw NSError(domain: "LexAI.GenerateAnswer", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid reply response payload",
            ])
        }
        return displayText
    }
}
