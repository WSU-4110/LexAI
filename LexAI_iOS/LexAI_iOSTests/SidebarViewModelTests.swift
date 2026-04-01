//
//  SidebarViewModelTests.swift
//  LexAI_iOS
//
//  Created for CSC-4110 Assignment 5: Unit Testing
// Sara Al-hachami 03/31/26

import XCTest
@testable import LexAI_iOS

final class SidebarViewModelTests: XCTestCase {

    // Setup

    var vm: SidebarViewModel!

    override func setUp() {
        super.setUp()
        vm = SidebarViewModel()
    }

    override func tearDown() {
        vm = nil
        super.tearDown()
    }

    //  Test 1: newSession() adds a session to the list

    func testNewSessionIncreasesSessionCount() {
        let countBefore = vm.sessions.count
        vm.newSession()
        XCTAssertEqual(vm.sessions.count, countBefore + 1,
                       "Session count should increase by 1 after calling newSession()")
    }

    // Test 2: newSession() sets the new session as active

    func testNewSessionSetsActiveSessionID() {
        let newSession = vm.newSession()
        XCTAssertEqual(vm.activeSessionID, newSession.id,
                       "activeSessionID should be updated to the newly created session's ID")
    }

    //Test 3: newSession() inserts at the front of the list

    func testNewSessionInsertedAtFront() {
        let newSession = vm.newSession()
        XCTAssertEqual(vm.sessions.first?.id, newSession.id,
                       "New session should be inserted at index 0 (front of the list)")
    }

    //  Test 4: delete(_:) removes the session from the list

    func testDeleteSessionRemovesItFromList() {
        let newSession = vm.newSession()
        let countBefore = vm.sessions.count
        vm.delete(newSession)
        XCTAssertEqual(vm.sessions.count, countBefore - 1,
                       "Session count should decrease by 1 after deleting a session")
        XCTAssertFalse(vm.sessions.contains(where: { $0.id == newSession.id }),
                       "Deleted session should no longer exist in the sessions list")
    }

    // Test 5: delete(_:) updates activeSessionID when active session is deleted

    func testDeleteActiveSessionUpdatesActiveSessionID() {
        let newSession = vm.newSession()
        // newSession is now active
        XCTAssertEqual(vm.activeSessionID, newSession.id)
        vm.delete(newSession)
        XCTAssertNotEqual(vm.activeSessionID, newSession.id,
                          "activeSessionID should no longer point to the deleted session")
    }

    //  Test 6: togglePin(_:) sets isPinned to true on an unpinned session

    func testTogglePinPinsAnUnpinnedSession() {
        let newSession = vm.newSession()
        XCTAssertFalse(vm.sessions.first!.isPinned, "New session should start unpinned")
        vm.togglePin(newSession)
        XCTAssertTrue(vm.sessions.first!.isPinned,
                      "isPinned should be true after togglePin() on an unpinned session")
    }

    // Test 7: togglePin(_:) unpins an already pinned session

    func testTogglePinUnpinsAPinnedSession() {
        let newSession = vm.newSession()
        vm.togglePin(newSession)   // pin it
        vm.togglePin(newSession)   // unpin it
        XCTAssertFalse(vm.sessions.first!.isPinned,
                       "isPinned should be false after toggling pin twice")
    }

    //  Test 8: toggleStar(_:) sets isStarred to true on an unstarred session

    func testToggleStarStarsAnUnstarredSession() {
        let newSession = vm.newSession()
        XCTAssertFalse(vm.sessions.first!.isStarred, "New session should start unstarred")
        vm.toggleStar(newSession)
        XCTAssertTrue(vm.sessions.first!.isStarred,
                      "isStarred should be true after toggleStar() on an unstarred session")
    }

    // Test 9: toggleStar(_:) unstars an already starred session

    func testToggleStarUnstarsAStarredSession() {
        let newSession = vm.newSession()
        vm.toggleStar(newSession)   // star it
        vm.toggleStar(newSession)   // unstar it
        XCTAssertFalse(vm.sessions.first!.isStarred,
                       "isStarred should be false after toggling star twice")
    }

    // Test 10: appendMessage(_:to:) adds a message to the correct session

    func testAppendMessageAddsMessageToSession() {
        let newSession = vm.newSession()
        let message = ChatMessage(text: "Is my landlord allowed to enter without notice?", isFromUser: true)
        vm.appendMessage(message, to: newSession.id)
        let updated = vm.sessions.first(where: { $0.id == newSession.id })!
        XCTAssertEqual(updated.messages.count, 1,
                       "Session should contain exactly 1 message after appending one")
        XCTAssertEqual(updated.messages.first?.text, message.text,
                       "Appended message text should match the original message")
    }

    // Test 11: appendMessage(_:to:) updates preview with last AI message

    func testAppendMessageUpdatesPreviewWithAIResponse() {
        let newSession = vm.newSession()
        let userMsg = ChatMessage(text: "Hello", isFromUser: true)
        let aiMsg   = ChatMessage(text: "Yes, Michigan law requires 24-hour notice.", isFromUser: false)
        vm.appendMessage(userMsg, to: newSession.id)
        vm.appendMessage(aiMsg,   to: newSession.id)
        let updated = vm.sessions.first(where: { $0.id == newSession.id })!
        XCTAssertEqual(updated.preview, String(aiMsg.text.prefix(60)),
                       "Preview should be set to the first 60 characters of the last AI message")
    }

    // Test 12: updateSession(id:messages:) replaces all messages on a session

    func testUpdateSessionReplacesMessages() {
        let newSession = vm.newSession()
        let initialMsg  = ChatMessage(text: "First message", isFromUser: true)
        let replacedMsg = ChatMessage(text: "Replaced message", isFromUser: true)
        vm.appendMessage(initialMsg, to: newSession.id)
        vm.updateSession(id: newSession.id, messages: [replacedMsg])
        let updated = vm.sessions.first(where: { $0.id == newSession.id })!
        XCTAssertEqual(updated.messages.count, 1,
                       "Session should have exactly 1 message after updateSession()")
        XCTAssertEqual(updated.messages.first?.text, replacedMsg.text,
                       "Session messages should be fully replaced by the new array")
    }

    // Test 13: updateSession(id:messages:) updates preview from last AI message

    func testUpdateSessionUpdatesPreview() {
        let newSession = vm.newSession()
        let aiMsg = ChatMessage(text: "You have the right to request repairs in writing.", isFromUser: false)
        vm.updateSession(id: newSession.id, messages: [aiMsg])
        let updated = vm.sessions.first(where: { $0.id == newSession.id })!
        XCTAssertEqual(updated.preview, String(aiMsg.text.prefix(60)),
                       "Preview should reflect the last AI message after updateSession()")
    }
}
