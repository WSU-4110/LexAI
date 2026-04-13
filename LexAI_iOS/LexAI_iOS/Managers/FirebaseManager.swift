//
//  AuthManager.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/16/26.
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
    
    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }

        // Ensure callable Functions can be tested without UI sign-in.
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

   

    // MARK: -chat storage - mirshod 3/13
    func saveChat(prompt: ChatPrompt, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()

        let data: [String: Any] = [
            "prompt": prompt.prompt,
            "documents": prompt.documents,
            "location": prompt.location,
            "language": prompt.language,
            "user": prompt.user,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("chatHistory").addDocument(data: data) { error in
            if let error = error {
                print("Error saving chat: \(error)")
                completion(false)
            } else{
                print("Chat successfully saved.")
                completion(true)
            }
        }
    }

    // MARK: - fetching chats (could be used in sidebar) - mirshod 3/24
    func fetchChats(userId: String, completion: @escaping ([ChatPrompt]) -> Void) {
        let db = Firestore.firestore()

        db.collection("chatHistory")
            .whereField("user", isEqualTo: userId)
            .getDocuments { snapshot, error in
                var chats: [ChatPrompt] = []

                if let documents = snapshot?.documents {
                    for doc in documents {
                        let data = doc.data()

                        let chat = ChatPrompt(
                            prompt: data["prompt"] as? String ?? "",
                            documents: data["documents"] as? [String] ?? [],
                            location: data["location"] as? String ?? "",
                            language: "",
                            user: data["user"] as? String ?? ""
                        )
                        chats.append(chat)
                    }
                }
                completion(chats)
            }
    }

    // MARK: - deleting a chat - mirshod 3/24
    func deleteChat(chatId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("chatHistory")
            .document(chatId)
            .delete { error in 
                completion(error == nil)
            }
    }

    // MARK - updating chat storage - mirshod 3/24
    func updateChat(chatId: String, newPrompt: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()

        db.collection("chatHistory")
            .document(chatId)
            .updateData(["prompt": newPrompt]) { error in
                completion(error == nil)
            }
    }
    
    
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
    
//    Import XCTests
//    Add the special tag over the Test function
//    Create a function definition that will call the function your testing with mock data
//    Test failures
//    Test successes
    
    
    @MainActor
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
            print("*****Successfully signed in")

        } catch {
            self.errorMessage = mapFirebaseError(error)
            print("SIGN IN ERROR: \(error)")  // Add this to see the real error
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
        case .emailAlreadyInUse:
            return "This email is already in use."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email."
        case .networkError:
            return "Network error. Please check your connection."
        case .tooManyRequests:
            return "Too many attempts. Please try again later."
        default:
            return error.localizedDescription
        }
    }
}


// struct for storing chats
struct ChatPrompt{
    let prompt: String
    let documents: [String]
    let location: String
    let language: String
    let user: String
}
