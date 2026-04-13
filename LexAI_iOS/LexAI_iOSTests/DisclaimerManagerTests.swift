import XCTest
@testable import LexAI_iOS

@MainActor
final class DisclaimerManagerTests: XCTestCase {
    
    var sut: DisclaimerManager!
    
    override func setUp() {
        super.setUp()
        sut = DisclaimerManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    //unit test 
    func testAcceptDisclaimer_SetsTrue() {
        // When
        sut.acceptDisclaimer()
        
        // Then
        XCTAssertTrue(sut.hasAccepted, "hasAccepted should be true after calling acceptDisclaimer()")
    }

    //unit test 
    func testResetDisclaimer_SetsFalse() {
        // Given
        sut.acceptDisclaimer()
        
        // When
        sut.resetDisclaimer()

        // Then
        XCTAssertFalse(sut.hasAccepted, "hasAccepted should be false after calling resetDisclaimer()")
    }
    
    // Additional test for initial state
    func testInitialState_IsFalse() {
        // Then
        XCTAssertFalse(sut.hasAccepted, "hasAccepted should be false initially")
    }

}
