import Foundation

public struct GitHubRelease: Decodable, Sendable {
    public let tagName: String?
    public let name: String?
    public let assets: [GitHubAsset]

    public var versionLabel: String {
        tagName ?? name ?? "latest"
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case assets
    }
}

public struct GitHubAsset: Decodable, Equatable, Sendable {
    public let name: String
    public let downloadURL: URL
    public let size: Int?

    public init(name: String, downloadURL: URL, size: Int?) {
        self.name = name
        self.downloadURL = downloadURL
        self.size = size
    }

    enum CodingKeys: String, CodingKey {
        case name
        case downloadURL = "browser_download_url"
        case size
    }
}
