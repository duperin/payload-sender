import XCTest
@testable import PS5PayloadKit

final class CustomPayloadTests: XCTestCase {
    func testCustomPayloadUsesPort9021AndSelectedFileName() {
        let file = URL(fileURLWithPath: "/tmp/custom-payload.bin")

        let payload = PayloadDefinition.custom(file: file)

        XCTAssertEqual(payload.id, "custom-payload")
        XCTAssertEqual(payload.name, "Custom payload")
        XCTAssertEqual(payload.port, 9021)
        XCTAssertEqual(payload.preferredFileName, "custom-payload.bin")
    }

    func testCustomPayloadCanUseUserSelectedPort() {
        let file = URL(fileURLWithPath: "/tmp/custom-payload.bin")

        let payload = PayloadDefinition.custom(file: file, port: 1337)

        XCTAssertEqual(payload.port, 1337)
        XCTAssertEqual(payload.detail, "Port 1337")
    }

    func testPortValidatorClampsToValidTCPRange() {
        XCTAssertEqual(PortValidator.clamped(-1), 1)
        XCTAssertEqual(PortValidator.clamped(0), 1)
        XCTAssertEqual(PortValidator.clamped(9021), 9021)
        XCTAssertEqual(PortValidator.clamped(70000), 65535)
    }

    func testIPv4ValidatorAcceptsOnlyIPv4Addresses() {
        XCTAssertTrue(IPv4AddressValidator.isValid("192.168.1.45"))
        XCTAssertTrue(IPv4AddressValidator.isValid("127.0.0.1"))
        XCTAssertFalse(IPv4AddressValidator.isValid(""))
        XCTAssertFalse(IPv4AddressValidator.isValid("console.local"))
        XCTAssertFalse(IPv4AddressValidator.isValid("999.168.1.45"))
    }
}
