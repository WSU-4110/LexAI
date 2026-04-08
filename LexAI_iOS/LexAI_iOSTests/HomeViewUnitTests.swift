//
//  HomeViewUnitTests.swift
//  LexAI_iOS
//
//  Made for Unit Testing - CSC 4110 Assignment 5
//  Made by Leah Hashwi

import XCTest
@testable import LexAI_iOS

final class HomeViewUnitTests: XCTestCase {

    var viewModel: HomeViewModel!

    //To re-do every time
    override func setUp() {
        super.setUp()
        viewModel = HomeViewModel()
    }

    //To clean up after
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    //Unit Test 1-Tests that ViewModel starts with the sidebar closed and the tool bar is visisble
    func testInitialState() {
        XCTAssertFalse(viewModel.isSidebarOpen,
                       "Sidebar should be closed on launch")
        XCTAssertTrue(viewModel.showToolbar,
                      "Toolbar should be visible on launch")
    }

    //Unit Test 2-Tests that doing toggleSidebar() once opens sidebar and hides toolbar
    func testToggleSidebarOpens() {
        viewModel.toggleSidebar()

        XCTAssertTrue(viewModel.isSidebarOpen,
                      "Sidebar should be open after one toggle")
        XCTAssertFalse(viewModel.showToolbar,
                       "Toolbar should be hidden when sidebar is open")
    }

    
    

    //Unit Test 3-Tests tapping  dark overlay to close the sidebar
    func testCloseSidebarViaOverlay() {
        viewModel.openSidebar()
        XCTAssertTrue(viewModel.isSidebarOpen, "Precondition: sidebar should be open")

        viewModel.closeSidebar()

        XCTAssertFalse(viewModel.isSidebarOpen,
                       "Sidebar should close when overlay is tapped")
        XCTAssertTrue(viewModel.showToolbar,
                      "Toolbar should reappear when sidebar is closed via overlay")
    }

    //Unit Test 4-Tests sidebar's off-screen offset when closed
    func testSidebarOffsetWhenClosed() {
        let offset = viewModel.sidebarOffset()

        XCTAssertEqual(offset, -400,
                       "Sidebar offset should be -400 (off-screen) when closed")
    }

    //Unit Test 5-Tests sidebars on-screen offset when open
    func testSidebarOffsetWhenOpen() {
        viewModel.openSidebar()
        let offset = viewModel.sidebarOffset()

        XCTAssertEqual(offset, -10,
                       "Sidebar offset should be -10 (on-screen) when open")
    }

    //Unit Test 6-Tests that dim overlay is shown only when sidebar is open
    func testOverlayVisibilityMatchesSidebarState() {
        XCTAssertFalse(viewModel.shouldShowOverlay(),
                       "Overlay should not show when sidebar is closed")

        viewModel.openSidebar()
        XCTAssertTrue(viewModel.shouldShowOverlay(),
                      "Overlay should show when sidebar is open")

        viewModel.closeSidebar()
        XCTAssertFalse(viewModel.shouldShowOverlay(),
                       "Overlay should hide again after sidebar closes")
    }

    //Unit Test 7-Tests that the "hamburger" button is only visible when the sidebar is closed
    func testToolbarButtonVisibilityInverseOfSidebar() {
        XCTAssertTrue(viewModel.shouldShowToolbarButton(),
                      "Toolbar button should be visible when sidebar is closed")

        viewModel.openSidebar()
        XCTAssertFalse(viewModel.shouldShowToolbarButton(),
                       "Toolbar button should be hidden when sidebar is open")
    }
}
