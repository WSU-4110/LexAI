import XCTest
@testable import LexAI_iOS

final class ChatPlaceholderTextTests: XCTestCase {
    func testPlaceholderForSelectedLanguage_returnsExpectedStrings() {
        XCTAssertEqual(ChatPlaceholderText.placeholder(forSelectedLanguage: "English"), "Message...")
        XCTAssertEqual(ChatPlaceholderText.placeholder(forSelectedLanguage: "Spanish"), "Mensaje...")
        XCTAssertEqual(ChatPlaceholderText.placeholder(forSelectedLanguage: "French"), "Message...")
        XCTAssertEqual(ChatPlaceholderText.placeholder(forSelectedLanguage: "Arabic"), "رسالة...")
        XCTAssertEqual(ChatPlaceholderText.placeholder(forSelectedLanguage: "German"), "Nachricht...")
        XCTAssertEqual(ChatPlaceholderText.placeholder(forSelectedLanguage: "Unknown"), "Message...")
    }
}
