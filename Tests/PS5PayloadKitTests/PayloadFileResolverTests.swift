import XCTest
@testable import PS5PayloadKit

final class PayloadFileResolverTests: XCTestCase {
    func testPrefersElfFilesBeforeBinFiles() throws {
        let files = [
            URL(fileURLWithPath: "/tmp/readme.txt"),
            URL(fileURLWithPath: "/tmp/etaHEN.bin"),
            URL(fileURLWithPath: "/tmp/payload.elf")
        ]

        let selected = try PayloadFileResolver.selectPayloadFile(from: files)

        XCTAssertEqual(selected.lastPathComponent, "payload.elf")
    }

    func testPrefersExplicitPayloadFileNameBeforeElfFiles() throws {
        let files = [
            URL(fileURLWithPath: "/tmp/elfldr_1320_v5.elf"),
            URL(fileURLWithPath: "/tmp/p2jb.js")
        ]

        let selected = try PayloadFileResolver.selectPayloadFile(from: files, preferredFileName: "p2jb.js")

        XCTAssertEqual(selected.lastPathComponent, "p2jb.js")
    }

    func testFallsBackToBinFileWhenElfIsUnavailable() throws {
        let files = [
            URL(fileURLWithPath: "/tmp/notes.md"),
            URL(fileURLWithPath: "/tmp/kstuff.bin")
        ]

        let selected = try PayloadFileResolver.selectPayloadFile(from: files)

        XCTAssertEqual(selected.lastPathComponent, "kstuff.bin")
    }

    func testThrowsWhenNoPayloadFileExists() {
        let files = [
            URL(fileURLWithPath: "/tmp/notes.md"),
            URL(fileURLWithPath: "/tmp/archive.zip")
        ]

        XCTAssertThrowsError(try PayloadFileResolver.selectPayloadFile(from: files)) { error in
            XCTAssertEqual(error as? PayloadError, .payloadFileNotFound)
        }
    }
}
