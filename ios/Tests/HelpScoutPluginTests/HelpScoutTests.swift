import XCTest
@testable import HelpScoutPlugin

class HelpScoutTests: XCTestCase {
    func testHexDataParsing() {
        XCTAssertEqual(Data(hexString: "0a0B ff"), Data([0x0A, 0x0B, 0xFF]))
        XCTAssertNil(Data(hexString: "abc"))
        XCTAssertNil(Data(hexString: "zz"))
    }

    func testColorParsing() {
        XCTAssertNotNil(UIColor(hexString: "#617DEC"))
        XCTAssertNotNil(UIColor(hexString: "fff"))
        XCTAssertNil(UIColor(hexString: "not-a-color"))
    }

    func testSessionAttributeLimit() {
        let implementation = HelpScout()
        let tooMany = Dictionary(uniqueKeysWithValues: (0..<21).map { ("key\($0)", "value") })
        XCTAssertFalse(implementation.setSessionAttributes(tooMany))
        XCTAssertTrue(implementation.setSessionAttributes(["plan": "pro"]))
        XCTAssertEqual(implementation.getSessionAttributes(), ["plan": "pro"])
    }

    func testRequiresInitialization() {
        XCTAssertThrowsError(try HelpScout().open(signature: nil, from: nil))
    }
}
