//
//  AuthManager.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/16/26.
//

import Foundation
import Combine
import FirebaseAuth


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
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
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
