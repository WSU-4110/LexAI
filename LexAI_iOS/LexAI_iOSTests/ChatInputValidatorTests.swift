import XCTest
@testable import LexAI_iOS

final class ChatInputValidatorTests: XCTestCase {
    func testTrimmedMessage_stripsLeadingAndTrailingWhitespaceAndNewlines() {
        XCTAssertEqual(ChatInputValidator.trimmedMessage("  hello  "), "hello")
        XCTAssertEqual(ChatInputValidator.trimmedMessage("\n\t hello \n"), "hello")
        XCTAssertEqual(ChatInputValidator.trimmedMessage("no extra"), "no extra")
    }

    func testTrimmedMessage_preservesInternalSpacing() {
        XCTAssertEqual(ChatInputValidator.trimmedMessage("  a  b  c  "), "a  b  c")
    }

    func testShouldSendMessage_trimsAndRejectsWhitespaceOnly() {
        XCTAssertFalse(ChatInputValidator.shouldSendMessage(""))
        XCTAssertFalse(ChatInputValidator.shouldSendMessage("   "))
        XCTAssertFalse(ChatInputValidator.shouldSendMessage("\n\t  "))
        XCTAssertTrue(ChatInputValidator.shouldSendMessage("hello"))
        XCTAssertTrue(ChatInputValidator.shouldSendMessage("  hello  "))
    }
}

