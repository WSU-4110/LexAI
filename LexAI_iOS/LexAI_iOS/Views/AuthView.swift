//
//  SignInUp.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 2/10/26.
//

import SwiftUI

struct AuthView: View {
    
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUpMode = true
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case email, password, confirmPassword
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    
                    
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.top, geo.size.height * 0.08)
                        
                        Text(isSignUpMode ? "Create Account" : "Welcome Back")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text(isSignUpMode
                             ? "Sign up to get started"
                             : "Sign in to continue")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 40)
                
                    
                    VStack(spacing: 20) {
                        
                        // Error banner
                        if let error = authManager.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                
                                TextField("you@example.com", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .email)
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .email ? Color.accentColor : .clear, lineWidth: 2)
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                
                                SecureField("Min. 6 characters", text: $password)
                                    .textContentType(isSignUpMode ? .newPassword : .password)
                                    .focused($focusedField, equals: .password)
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .password ? Color.accentColor : .clear, lineWidth: 2)
                            )
                        }
                        
                        if isSignUpMode {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirm Password")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                
                                HStack {
                                    Image(systemName: "lock.rotation")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    
                                    SecureField("Re-enter password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .focused($focusedField, equals: .confirmPassword)
                                }
                                .padding(14)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .confirmPassword ? Color.accentColor : .clear, lineWidth: 2)
                                )
                                
                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    Text("Passwords do not match")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        Button {
                            submit()
                        } label: {
                            Group {
                                if authManager.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUpMode ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 30)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 14))
                        .controlSize(.large)
                        .disabled(!isFormValid || authManager.isLoading)
                        
                        HStack(spacing: 4) {
                            Text(isSignUpMode
                                 ? "Already have an account?"
                                 : "Don't have an account?")
                                .foregroundStyle(Color("grape"))
                            
                            Button(isSignUpMode ? "Sign In" : "Sign Up") {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isSignUpMode.toggle()
                                    authManager.errorMessage = nil
                                    confirmPassword = ""
                                }
                            }
                            .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .padding(.top, 4)
                    }
                    .padding(24)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
                    .padding(.horizontal, 20)
                }
                .frame(minHeight: geo.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(
            LinearGradient(
                colors: [Color("grape"), Color("grape").opacity(0.7), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
    
    
    private var isFormValid: Bool {
        let baseValid = !email.isEmpty && password.count >= 6
        if isSignUpMode {
            return baseValid && password == confirmPassword
        }
        return baseValid
    }
    
    private func submit() {
        focusedField = nil
        Task {
            if isSignUpMode {
                await authManager.signUp(email: email, password: password)
            } else {
                await authManager.signIn(email: email, password: password)
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}



