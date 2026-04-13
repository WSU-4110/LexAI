import XCTest
@testable import LexAI_iOS

final class ChatReplyErrorFormatterTests: XCTestCase {
    func testReplyErrorMessage_appendsLocalizedDescription() {
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "boom"])
        XCTAssertEqual(
            ChatReplyErrorFormatter.replyErrorMessage(for: error),
            "Reply error: boom"
        )
    }
}
