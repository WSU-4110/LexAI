import XCTest
@testable import LexAI_iOS

final class GenerateAnswerResponseParserTests: XCTestCase {
    func testDisplayText_parsesSuccessAndRejectsInvalidPayloads() throws {
        XCTAssertEqual(
            try GenerateAnswerResponseParser.displayText(fromCallableData: ["displayText": "Hola"]),
            "Hola"
        )

        XCTAssertThrowsError(try GenerateAnswerResponseParser.displayText(fromCallableData: nil as Any?)) { error in
            let ns = error as NSError
            XCTAssertEqual(ns.domain, "LexAI.GenerateAnswer")
            XCTAssertEqual(ns.code, 1)
        }

        XCTAssertThrowsError(try GenerateAnswerResponseParser.displayText(fromCallableData: "not a dict"))

        XCTAssertThrowsError(
            try GenerateAnswerResponseParser.displayText(fromCallableData: ["displayText": 123])
        )
    }
}
