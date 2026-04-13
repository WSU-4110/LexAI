//
//  AuthViewTests.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 3/31/26.
//

import XCTest
@testable import LexAI_iOS


class AuthFormValidatorTests: XCTestCase {

    
    func testValidSignUpForm() {
        let result = AuthFormValidator.isFormValid(
            email: "user@example.com",
            password: "password123",
            confirmPassword: "password123",
            isSignUpMode: true
        )
        XCTAssertTrue(result, "Form should be valid when email is non-empty, password >= 6 chars, and passwords match in sign-up mode")
    }

    
    func testSignUpFailsWithMismatchedPasswords() {
        let result = AuthFormValidator.isFormValid(
            email: "user@example.com",
            password: "password123",
            confirmPassword: "differentPassword",
            isSignUpMode: true
        )
        XCTAssertFalse(result, "Form should be invalid when passwords do not match in sign-up mode")
    }

    
    func testFormInvalidWithEmptyEmail() {
        let result = AuthFormValidator.isFormValid(
            email: "",
            password: "password123",
            confirmPassword: "password123",
            isSignUpMode: true
        )
        XCTAssertFalse(result, "Form should be invalid when email is empty")
    }

    
    func testFormInvalidWithShortPassword() {
        let result = AuthFormValidator.isFormValid(
            email: "user@example.com",
            password: "12345",
            confirmPassword: "12345",
            isSignUpMode: true
        )
        XCTAssertFalse(result, "Form should be invalid when password has fewer than 6 characters")
    }

    
    func testValidSignInForm() {
        let result = AuthFormValidator.isFormValid(
            email: "user@example.com",
            password: "password123",
            confirmPassword: "",
            isSignUpMode: false
        )
        XCTAssertTrue(result, "Form should be valid in sign-in mode with valid email and password, regardless of confirmPassword")
    }

    
    func testSignInInvalidWithEmptyEmail() {
        let result = AuthFormValidator.isFormValid(
            email: "",
            password: "password123",
            confirmPassword: "",
            isSignUpMode: false
        )
        XCTAssertFalse(result, "Form should be invalid in sign-in mode when email is empty")
    }
}
