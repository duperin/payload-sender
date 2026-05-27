import Foundation

public struct GitHubReleaseClient: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func latestRelease(owner: String, repository: String) async throws -> GitHubRelease {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repository)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("PayloadSender", forHTTPHeaderField: "User-Agent")

        return try await fetchRelease(request: request, serviceName: "GitHub")
    }

    public func latestForgejoRelease(baseURL: URL, owner: String, repository: String) async throws -> GitHubRelease {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("v1")
            .appendingPathComponent("repos")
            .appendingPathComponent(owner)
            .appendingPathComponent(repository)
            .appendingPathComponent("releases")
            .appendingPathComponent("latest")

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("PayloadSender", forHTTPHeaderField: "User-Agent")

        return try await fetchRelease(request: request, serviceName: "Forgejo")
    }

    private func fetchRelease(request: URLRequest, serviceName: String) async throws -> GitHubRelease {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw PayloadError.downloadFailed("\(serviceName) responded with HTTP \(code).")
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }
}

public enum GitHubAssetSelector {
    private static let allowedExtensions = ["elf", "bin", "js", "zip", "7z", "tar", "gz"]
    private static let ignoredFragments = ["source", "readme", "debug", "symbols"]

    public static func selectBestAsset(from assets: [GitHubAsset], preferredFileName: String? = nil) throws -> GitHubAsset {
        guard !assets.isEmpty else {
            throw PayloadError.noReleaseAssets
        }

        if let preferredFileName,
           let preferred = assets.first(where: { $0.name.caseInsensitiveCompare(preferredFileName) == .orderedSame }) {
            return preferred
        }

        let candidates = assets.filter { asset in
            let lowercase = asset.name.lowercased()
            let extensionMatch = allowedExtensions.contains { lowercase.hasSuffix(".\($0)") }
            let ignored = ignoredFragments.contains { lowercase.contains($0) }
            return extensionMatch && !ignored
        }

        if let direct = candidates.first(where: { name in
            let lowercase = name.name.lowercased()
            return lowercase.hasSuffix(".elf") || lowercase.hasSuffix(".bin") || lowercase.hasSuffix(".js")
        }) {
            return direct
        }

        if let archive = candidates.first {
            return archive
        }

        throw PayloadError.payloadAssetNotFound
    }
}
