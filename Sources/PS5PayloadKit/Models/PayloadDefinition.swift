import Foundation

public struct PayloadDefinition: Identifiable, Hashable, Sendable {
    public enum Source: Hashable, Sendable {
        case latestGitHubRelease(owner: String, repository: String)
        case latestForgejoRelease(baseURL: URL, owner: String, repository: String)
        case directFile(URL)
    }

    public let id: String
    public let name: String
    public let port: Int
    public let source: Source
    public let detail: String
    public let preferredFileName: String?
    public let fixedVersionLabel: String?

    public init(
        id: String,
        name: String,
        port: Int,
        source: Source,
        detail: String,
        preferredFileName: String? = nil,
        fixedVersionLabel: String? = nil
    ) {
        self.id = id
        self.name = name
        self.port = port
        self.source = source
        self.detail = detail
        self.preferredFileName = preferredFileName
        self.fixedVersionLabel = fixedVersionLabel
    }

    public static func custom(file: URL, port: Int = 9021) -> PayloadDefinition {
        PayloadDefinition(
            id: "custom-payload",
            name: "Custom payload",
            port: port,
            source: .directFile(file),
            detail: "Port \(port)",
            preferredFileName: file.lastPathComponent,
            fixedVersionLabel: "Local"
        )
    }
}

public enum PayloadCatalog {
    public static let all: [PayloadDefinition] = [
        PayloadDefinition(
            id: "p2jb-y2jb",
            name: "P2JB-Y2JB",
            port: 50000,
            source: .latestGitHubRelease(owner: "matem6", repository: "P2JB-Y2JB-Porting"),
            detail: "Port 50000",
            preferredFileName: "p2jb.js"
        ),
        PayloadDefinition(
            id: "kstuff-lite",
            name: "kstuff-lite",
            port: 9021,
            source: .latestGitHubRelease(owner: "EchoStretch", repository: "kstuff-lite"),
            detail: "Port 9021"
        ),
        PayloadDefinition(
            id: "shadowmountplus",
            name: "ShadowMountPlus",
            port: 9021,
            source: .latestGitHubRelease(owner: "drakmor", repository: "ShadowMountPlus"),
            detail: "Port 9021"
        ),
        PayloadDefinition(
            id: "elf-arsenal",
            name: "Elf Arsenal",
            port: 9021,
            source: .latestForgejoRelease(
                baseURL: URL(string: "https://git.etawen.dev")!,
                owner: "soniciso",
                repository: "elf-arsenal"
            ),
            detail: "Port 9021",
            preferredFileName: "elf-arsenal.elf"
        ),
        PayloadDefinition(
            id: "etahen-26b",
            name: "etaHEN 2.6B",
            port: 9021,
            source: .directFile(URL(string: "https://raw.githubusercontent.com/zecoxao/zecoxao.github.io/main/luasauce/payloads/etaHEN-2.6B.bin")!),
            detail: "Port 9021",
            fixedVersionLabel: "2.6B"
        )
    ]
}
