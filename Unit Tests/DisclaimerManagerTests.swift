import XCTest
@testable import LexAI_iOS

final class DisclaimerManagerTests: XCTestCase {
    
    //unit test 
    func testAcceptDisclaimer_SetsTrue() {
        let manager = DisclaimerManager()
        manager.acceptDisclaimer()
        XCTAssertTrue(manager.hasAccepted)
    }

    //unit test 
    func testResetDisclaimer_SetsFalse() {
        let manager = DisclaimerManager()
        
        manager.acceptDisclaimer()
        manager.resetDisclaimer()

        XCTAssertFalse(manager.hasAccepted)
    }

}