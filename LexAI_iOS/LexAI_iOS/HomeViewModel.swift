//
//  HomeViewModel.swift
//  LexAI_iOS
//
//  Made for Unit Testing- CSC 4110 Assignment 5
//  Made by Leah Hashwi
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var isSidebarOpen: Bool = false
    @Published var showToolbar: Bool = true

    //sidebar
    //Toggles the sidebar open/closed and syncs toolbar visibility
    func toggleSidebar() {
        isSidebarOpen.toggle()
        showToolbar.toggle()
    }
    //Open and close
    func openSidebar() {
        isSidebarOpen = true
        showToolbar = false
    }
    
    func closeSidebar() {
        isSidebarOpen = false
        showToolbar = true
    }

    //Returns the horizontal offset for the sidebar based on its open state
    func sidebarOffset() -> CGFloat {
        return isSidebarOpen ? -10 : -400
    }

    //Returns whether the dimming should be visible
    func shouldShowOverlay() -> Bool {
        return isSidebarOpen
    }

    //Returns whether toolbar "hamburger" button should be visible
    func shouldShowToolbarButton() -> Bool {
        return showToolbar
    }
}
