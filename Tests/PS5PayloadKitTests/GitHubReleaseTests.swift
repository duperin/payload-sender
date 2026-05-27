import XCTest
@testable import PS5PayloadKit

final class GitHubReleaseTests: XCTestCase {
    func testDecodesReleaseAssets() throws {
        let json = """
        {
          "tag_name": "v1.2.3",
          "name": "Release 1.2.3",
          "assets": [
            {
              "name": "payload.zip",
              "browser_download_url": "https://example.com/payload.zip",
              "size": 42
            }
          ]
        }
        """.data(using: .utf8)!

        let release = try JSONDecoder().decode(GitHubRelease.self, from: json)

        XCTAssertEqual(release.versionLabel, "v1.2.3")
        XCTAssertEqual(release.assets.first?.name, "payload.zip")
        XCTAssertEqual(release.assets.first?.downloadURL.absoluteString, "https://example.com/payload.zip")
    }

    func testSelectsPayloadLikeAssetBeforeReadmeAssets() throws {
        let assets = [
            GitHubAsset(name: "source-code.zip", downloadURL: URL(string: "https://example.com/source.zip")!, size: 10),
            GitHubAsset(name: "kstuff-lite.elf", downloadURL: URL(string: "https://example.com/kstuff.elf")!, size: 20)
        ]

        let selected = try GitHubAssetSelector.selectBestAsset(from: assets)

        XCTAssertEqual(selected.name, "kstuff-lite.elf")
    }

    func testSelectsExplicitP2JBJavaScriptAssetBeforeElfLoader() throws {
        let assets = [
            GitHubAsset(name: "elfldr_1320_v5.elf", downloadURL: URL(string: "https://example.com/elfldr.elf")!, size: 20),
            GitHubAsset(name: "p2jb.js", downloadURL: URL(string: "https://example.com/p2jb.js")!, size: 30)
        ]

        let selected = try GitHubAssetSelector.selectBestAsset(from: assets, preferredFileName: "p2jb.js")

        XCTAssertEqual(selected.name, "p2jb.js")
    }

    func testSelectsExplicitElfArsenalAssetBeforeImages() throws {
        let assets = [
            GitHubAsset(name: "image.png", downloadURL: URL(string: "https://example.com/image.png")!, size: 20),
            GitHubAsset(name: "elf-arsenal.elf", downloadURL: URL(string: "https://example.com/elf-arsenal.elf")!, size: 30)
        ]

        let selected = try GitHubAssetSelector.selectBestAsset(from: assets, preferredFileName: "elf-arsenal.elf")

        XCTAssertEqual(selected.name, "elf-arsenal.elf")
    }
}
