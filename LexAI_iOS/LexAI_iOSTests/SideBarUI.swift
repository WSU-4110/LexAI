//
//  SideBarUI.swift
//  Created by Sara 04/01/2026
//
import XCTest
@testable import LexAI_iOS
final class SidebarViewModelTests: XCTestCase {
    var vm: SidebarViewModel!
    override func setUp() {
        super.setUp()
        vm = SidebarViewModel()
    }
    override func tearDown() {
        vm = nil
        super.tearDown()
    }
    func testNewSessionIncreasesSessionCount() {
        let countBefore = vm.sessions.count
        vm.newSession()
        XCTAssertEqual(vm.sessions.count, countBefore + 1)
    }
    func testNewSessionSetsActiveSessionID() {
        vm.newSession()
        let newSession = vm.sessions.first!
        XCTAssertEqual(vm.activeSessionID, newSession.id)
    }
    func testNewSessionInsertedAtFront() {
        vm.newSession()
        let newSession = vm.sessions.first!
        XCTAssertEqual(vm.sessions.first?.id, newSession.id)
    }
    func testDeleteSessionRemovesItFromList() {
        vm.newSession()
        let session = vm.sessions.first!
        let countBefore = vm.sessions.count
        vm.delete(session)
        XCTAssertEqual(vm.sessions.count, countBefore - 1)
    }
}
