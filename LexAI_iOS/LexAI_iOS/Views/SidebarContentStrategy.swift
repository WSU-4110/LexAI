// Created by Sara 03/24/2026 for HW4
// Implements the Strategy Pattern for sidebar chat loading.
// Defines a common interface (SidebarContentStrategy) for retrieving chat data.
// MockSidebarStrategy provides sample data for testing and development.
// FirebaseSidebarStrategy is intended for real database integration.
// Enables SidebarView to switch data sources without modifying UI logic.

protocol SidebarContentStrategy {
    func loadChats() async -> [String]
}

class MockSidebarStrategy: SidebarContentStrategy {
    func loadChats() async -> [String] {
        return (1...14).map { "Example #\($0)" }
    }
}

class FirebaseSidebarStrategy: SidebarContentStrategy {
    func loadChats() async -> [String] {
        // TODO: fetch from Firestore
        return []
    }
}
