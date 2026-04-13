//
//  FirebaseManager.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/16/26.
//  Extended with session/message persistence — Sprint 4
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager: ObservableObject {

    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
        if Auth.auth().currentUser == nil {
            Task { @MainActor in
                do {
                    _ = try await Auth.auth().signInAnonymously()
                } catch {
                    self.errorMessage = self.mapFirebaseError(error)
                }
            }
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Firestore path helpers

    private var uid: String? { Auth.auth().currentUser?.uid }

    private func sessionsRef() -> CollectionReference? {
        guard let uid else { return nil }
        return db.collection("users").document(uid).collection("sessions")
    }

    private func messagesRef(sessionId: String) -> CollectionReference? {
        return sessionsRef()?.document(sessionId).collection("messages")
    }

    // MARK: - Session: Create

    func createSession(_ session: ChatSession) {
        guard let ref = sessionsRef() else { return }
        var data: [String: Any] = [
            "title": session.title,
            "preview": session.preview,
            "createdAt": Timestamp(date: session.createdAt)
        ]
        if let tag = session.tag { data["tag"] = tag.rawValue }
        ref.document(session.id.uuidString).setData(data)
    }

    // MARK: - Session: Load all (for sidebar)

    func loadSessions(completion: @escaping ([ChatSession]) -> Void) {
        guard let ref = sessionsRef() else { completion([]); return }

        ref.order(by: "createdAt", descending: true).getDocuments { snapshot, error in
            if let error { print("loadSessions error: \(error)"); completion([]); return }

            let sessions: [ChatSession] = snapshot?.documents.compactMap { doc in
                let d = doc.data()
                return ChatSession(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    title: d["title"] as? String ?? "Conversation",
                    preview: d["preview"] as? String ?? "",
                    tag: (d["tag"] as? String).flatMap { SessionTag(rawValue: $0) },
                    createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )
            } ?? []

            DispatchQueue.main.async { completion(sessions) }
        }
    }

    // MARK: - Session: Update title/preview/tag

    func updateSession(_ session: ChatSession) {
        guard let ref = sessionsRef() else { return }
        var data: [String: Any] = [
            "title": session.title,
            "preview": session.preview
        ]
        if let tag = session.tag { data["tag"] = tag.rawValue }
        ref.document(session.id.uuidString).updateData(data)
    }

    // MARK: - Session: Rename

    func renameSession(_ session: ChatSession, to title: String) {
        guard let ref = sessionsRef() else { return }
        ref.document(session.id.uuidString).updateData(["title": title])
    }

    // MARK: - Session: Delete (+ all messages)

    func deleteSession(_ session: ChatSession) {
        guard let ref = sessionsRef() else { return }
        let sessionDoc = ref.document(session.id.uuidString)
        sessionDoc.collection("messages").getDocuments { snapshot, _ in
            let batch = self.db.batch()
            snapshot?.documents.forEach { batch.deleteDocument($0.reference) }
            batch.deleteDocument(sessionDoc)
            batch.commit()
        }
    }

    // MARK: - Message: Save

    func saveMessage(_ message: ChatMessage, to session: ChatSession) {
        guard let ref = messagesRef(sessionId: session.id.uuidString) else { return }
        ref.document(message.id.uuidString).setData([
            "text": message.text,
            "isFromUser": message.isFromUser,
            "date": Timestamp(date: message.date)
        ])
    }

    // MARK: - Message: Load all for a session

    func loadMessages(for session: ChatSession, completion: @escaping ([ChatMessage]) -> Void) {
        guard let ref = messagesRef(sessionId: session.id.uuidString) else { completion([]); return }

        ref.order(by: "date", descending: false).getDocuments { snapshot, error in
            if let error { print("loadMessages error: \(error)"); completion([]); return }

            let messages: [ChatMessage] = snapshot?.documents.compactMap { doc in
                let d = doc.data()
                guard let text = d["text"] as? String,
                      let isFromUser = d["isFromUser"] as? Bool else { return nil }
                return ChatMessage(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    text: text,
                    isFromUser: isFromUser,
                    date: (d["date"] as? Timestamp)?.dateValue() ?? Date()
                )
            } ?? []

            DispatchQueue.main.async { completion(messages) }
        }
    }

    // MARK: - Legacy: single-prompt chat history (kept for backwards compatibility)

    func saveChat(prompt: ChatPrompt, completion: @escaping (Bool) -> Void) {
        let data: [String: Any] = [
            "prompt": prompt.prompt,
            "documents": prompt.documents,
            "location": prompt.location,
            "language": prompt.language,
            "user": prompt.user,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("chatHistory").addDocument(data: data) { error in
            completion(error == nil)
        }
    }

    func fetchChats(userId: String, completion: @escaping ([ChatPrompt]) -> Void) {
        db.collection("chatHistory")
            .whereField("user", isEqualTo: userId)
            .getDocuments { snapshot, _ in
                let chats: [ChatPrompt] = snapshot?.documents.compactMap { doc in
                    let d = doc.data()
                    return ChatPrompt(
                        prompt: d["prompt"] as? String ?? "",
                        documents: d["documents"] as? [String] ?? [],
                        location: d["location"] as? String ?? "",
                        language: d["language"] as? String ?? "",
                        user: d["user"] as? String ?? ""
                    )
                } ?? []
                completion(chats)
            }
    }

    func deleteChat(chatId: String, completion: @escaping (Bool) -> Void) {
        db.collection("chatHistory").document(chatId).delete { error in
            completion(error == nil)
        }
    }

    func updateChat(chatId: String, newPrompt: String, completion: @escaping (Bool) -> Void) {
        db.collection("chatHistory").document(chatId)
            .updateData(["prompt": newPrompt]) { error in
                completion(error == nil)
            }
    }

    // MARK: - Auth

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = mapFirebaseError(error)
        }
        isLoading = false
    }

    @MainActor
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = mapFirebaseError(error)
        }
        isLoading = false
    }

    @MainActor
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private func mapFirebaseError(_ error: Error) -> String {
        let nsError = error as NSError
        guard let errorCode = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        switch errorCode {
        case .emailAlreadyInUse: return "This email is already in use."
        case .invalidEmail:      return "Please enter a valid email address."
        case .weakPassword:      return "Password must be at least 6 characters."
        case .wrongPassword:     return "Incorrect password. Please try again."
        case .userNotFound:      return "No account found with this email."
        case .networkError:      return "Network error. Please check your connection."
        case .tooManyRequests:   return "Too many attempts. Please try again later."
        default:                 return error.localizedDescription
        }
    }
}

// MARK: - Models

struct ChatPrompt {
    let prompt: String
    let documents: [String]
    let location: String
    let language: String
    let user: String
}
