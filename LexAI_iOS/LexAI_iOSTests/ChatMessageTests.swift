import XCTest
@testable import LexAI_iOS

final class ChatMessageTests: XCTestCase {
    func testInitStoresFields() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let date = Date(timeIntervalSince1970: 123)

        let message = ChatMessage(id: id, text: "hello", isFromUser: true, date: date)

        XCTAssertEqual(message.id, id)
        XCTAssertEqual(message.text, "hello")
        XCTAssertEqual(message.isFromUser, true)
        XCTAssertEqual(message.date, date)
    }
}

