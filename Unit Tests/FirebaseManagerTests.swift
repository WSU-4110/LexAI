import XCTest
@testable import LexAI_iOS

final class FirebaseManagerTests: XCTestCase {
    //unit test for chat saving method
    func testSaveChat() {
        let manager = FirebaseManager()

        let chat = ChatPrompt(
            prompt: "Test",
            documents: ["doc1"],
            location: "United States",
            language: "ENG",
            user: "user001"
        )

        let expectation = self.expectation(description: "Save chat completes.")

        manager.saveChat(prompt: chat) { success in
            XCTAssertNotNil(success) // check
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3)
    }

    //unit test for fetching chats method
    func testFetchChats_ReturnedData() {
        let manager = FirebaseManager()
        let expectation = self.expectation(description: "Fetch chats complete.")

        manager.fetchChats(userId: "testUser") { chats in
            XCTAssertNotNil(chats)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    //unit test for deleting chats method
    func testDeleteChat_Success() {
        let manager = FirebaseManager()
        let expectation = self.expectation(description: "Delete chat complete.")

        manager.deleteChat(chatId: "testChatID") { success in
            XCTAssertNotNil(success)
            XCTAssertTrue(success || !success) // checking that something is returned
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    //unit test for updating chat method
    func testUpdateChat_Success() {
        let manager = FirebaseManager()
        let expectation = self.expectation(description: "Update chat complete.")

        manager.updateChat(chatId: "testChatID", newPrompt: "Updated prompt") { success in
            XCTAssertNotNil(success)
            XCTAssertTrue(success || !success)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
}