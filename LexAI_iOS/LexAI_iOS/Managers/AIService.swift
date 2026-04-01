//
//  AIService.swift
//  LexAI_iOS
//

import Foundation

enum AIServiceError: Error {
    case invalidAPIKey
    case invalidResponse
    case httpStatus(Int)
    case emptyContent
    case decodingFailed
}

final class AIService {
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    // sendMessage sends system + user messages to the AI API.
    // API key is securely loaded from Info.plist via xcconfig.
    func sendMessage(system: String, user: String) async throws -> String {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
        // without a key we refuse to phone home; dignity intact (S)
        guard !apiKey.isEmpty else {
            throw AIServiceError.invalidAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // system sets the tone, user actually asks; classic division of labor (S)
        let payload = ChatCompletionRequest(
            model: "gpt-4o-mini",
            messages: [
                ChatCompletionRequest.Message(role: "system", content: system),
                ChatCompletionRequest.Message(role: "user", content: user)
            ]
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw AIServiceError.httpStatus(http.statusCode)
        }

        let decoded: ChatCompletionResponse
        do {
            decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        } catch {
            throw AIServiceError.decodingFailed
        }

        guard let content = decoded.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw AIServiceError.emptyContent
        }

        return content
    }

    /// Streams assistant tokens via Server-Sent Events. Caller owns threading for `onToken`.
    func streamMessage(system: String, user: String, onToken: @escaping (String) -> Void) async throws {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
        // same key check as the one shot path; consistency is the least we can do (S)
        guard !apiKey.isEmpty else {
            throw AIServiceError.invalidAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ChatCompletionStreamRequest(
            model: "gpt-4o-mini",
            stream: true,
            messages: [
                ChatCompletionRequest.Message(role: "system", content: system),
                ChatCompletionRequest.Message(role: "user", content: user)
            ]
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw AIServiceError.httpStatus(http.statusCode)
        }

        // SSE lines are chatty; we ignore the boring ones on purpose (S)
        for try await line in bytes.lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard trimmed.hasPrefix("data: ") else { continue }

            let afterPrefix = trimmed.dropFirst(6).trimmingCharacters(in: .whitespacesAndNewlines)
            // polite way for the server to hang up without drama (S)
            if afterPrefix == "[DONE]" {
                break
            }

            guard let data = afterPrefix.data(using: .utf8) else { continue }

            let chunk: StreamChunk
            do {
                chunk = try JSONDecoder().decode(StreamChunk.self, from: data)
            } catch {
                continue
            }

            guard let content = chunk.choices?.first?.delta?.content else { continue }
            let piece = content
            guard !piece.isEmpty else { continue }

            // caller decides threading; we just deliver the syllables (S)
            onToken(piece)
        }
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [Message]

    struct Message: Encodable {
        let role: String
        let content: String
    }
}

private struct ChatCompletionStreamRequest: Encodable {
    let model: String
    let stream: Bool
    let messages: [ChatCompletionRequest.Message]
}

private struct StreamChunk: Decodable {
    let choices: [Choice]?

    struct Choice: Decodable {
        let delta: Delta?
    }

    struct Delta: Decodable {
        let content: String?
    }
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String?
    }
}
