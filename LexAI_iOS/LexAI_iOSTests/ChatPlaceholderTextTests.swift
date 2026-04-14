import XCTest
@testable import LexAI_iOS

final class ChatPlaceholderTextTests: XCTestCase {
    func testPlaceholderForSelectedLanguage_returnsExpectedStrings() {
        XCTAssertEqual(ChatPlaceholderText.placeholder(forSelectedLanguage: "English"), "Ask a question about a law...")
        XCTAssertEqual(ChatPlaceholderText.placeholder(forSelectedLanguage: "Spanish"), "Haz una pregunta sobre una ley...")
        XCTAssertEqual(ChatPlaceholderText.placeholder(forSelectedLanguage: "French"), "Posez une question sur une loi...")
        XCTAssertEqual(ChatPlaceholderText.placeholder(forSelectedLanguage: "Arabic"), "اطرح سؤالا حول قانون...")
        XCTAssertEqual(ChatPlaceholderText.placeholder(forSelectedLanguage: "German"), "Stellen Sie eine Frage zu einem Gesetz...")
        XCTAssertEqual(ChatPlaceholderText.placeholder(forSelectedLanguage: "Unknown"), "Ask a question about a law...")
    }
}
