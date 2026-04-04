//
//  SideBarHeadache.swift
//  LexAI_iOSTests
//
//  Created by Sara Al-hachami on 4/1/26.
//  Made for Unit Testing - CSC 4110 Assignment 5
//
import Foundation
import Combine
import SwiftUI
class SidebarViewModel: ObservableObject {
    //  UI State
    @Published var isOpen: Bool = false
    // MARK: - Sidebar Controls
    // Toggle sidebar open/close
    func toggleSidebar() {
        isOpen.toggle()
    }
    // Open sidebar
    func openSidebar() {
        isOpen = true
    }
    // Close sidebar
    func closeSidebar() {
        isOpen = false
    }
    // MARK: - UI Helpers (used in SwiftUI views)
    // Controls slide animation position
    func sidebarOffset() -> CGFloat {
        return isOpen ? 0 : -300
    }
    // Controls background dim overlay
    func shouldShowOverlay() -> Bool {
        return isOpen
    }
    // Optional: disable interaction behind sidebar
    func shouldDisableBackground() -> Bool {
        return isOpen
    }
}
