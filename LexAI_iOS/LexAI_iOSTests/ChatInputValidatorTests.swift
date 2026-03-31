import XCTest
@testable import LexAI_iOS

final class ChatInputValidatorTests: XCTestCase {
    func testShouldSendMessage_trimsAndRejectsWhitespaceOnly() {
        XCTAssertFalse(ChatInputValidator.shouldSendMessage(""))
        XCTAssertFalse(ChatInputValidator.shouldSendMessage("   "))
        XCTAssertFalse(ChatInputValidator.shouldSendMessage("\n\t  "))
        XCTAssertTrue(ChatInputValidator.shouldSendMessage("hello"))
        XCTAssertTrue(ChatInputValidator.shouldSendMessage("  hello  "))
    }
}

