import Foundation

public struct PayloadTransferService: Sendable {
    private let releaseClient: GitHubReleaseClient
    private let downloader: PayloadDownloader
    private let extractor: PayloadExtractor
    private let sender: TCPPayloadSender
    private let baseDirectory: URL

    public init(
        releaseClient: GitHubReleaseClient = GitHubReleaseClient(),
        downloader: PayloadDownloader = PayloadDownloader(),
        extractor: PayloadExtractor = PayloadExtractor(),
        sender: TCPPayloadSender = TCPPayloadSender(),
        baseDirectory: URL = PayloadTransferService.defaultBaseDirectory()
    ) {
        self.releaseClient = releaseClient
        self.downloader = downloader
        self.extractor = extractor
        self.sender = sender
        self.baseDirectory = baseDirectory
    }

    public func send(
        payload: PayloadDefinition,
        to host: String,
        eventHandler: @escaping @Sendable (PayloadEvent) -> Void
    ) async {
        do {
            eventHandler(.init(kind: .info, message: "Preparing \(payload.name)."))
            let file = try await resolvePayloadFile(payload: payload, eventHandler: eventHandler)
            eventHandler(.init(kind: .info, message: "Connecting to \(host):\(payload.port)."))
            try sender.send(file: file, to: host, port: payload.port)
            eventHandler(.init(kind: .success, message: "\(payload.name) sent successfully."))
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            eventHandler(.init(kind: .failure, message: "\(payload.name): \(message)"))
        }
    }

    public func sendCustomFile(
        file: URL,
        to host: String,
        port: Int = 9021,
        eventHandler: @escaping @Sendable (PayloadEvent) -> Void
    ) async {
        let payload = PayloadDefinition.custom(file: file, port: port)
        do {
            eventHandler(.init(kind: .info, message: "Preparing \(file.lastPathComponent)."))
            eventHandler(.init(kind: .info, message: "Connecting to \(host):\(payload.port)."))
            try sender.send(file: file, to: host, port: payload.port)
            eventHandler(.init(kind: .success, message: "\(file.lastPathComponent) sent successfully."))
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            eventHandler(.init(kind: .failure, message: "\(file.lastPathComponent): \(message)"))
        }
    }

    private func resolvePayloadFile(
        payload: PayloadDefinition,
        eventHandler: @escaping @Sendable (PayloadEvent) -> Void
    ) async throws -> URL {
        let payloadDirectory = baseDirectory.appendingPathComponent(payload.id, isDirectory: true)
        try FileManager.default.createDirectory(at: payloadDirectory, withIntermediateDirectories: true)

        switch payload.source {
        case .directFile(let url):
            eventHandler(.init(kind: .info, message: "Downloading direct file."))
            let downloaded = try await downloader.download(from: url, to: payloadDirectory, preferredName: url.lastPathComponent)
            return try extractor.payloadFile(from: downloaded, workDirectory: payloadDirectory, preferredFileName: payload.preferredFileName)

        case .latestGitHubRelease(let owner, let repository):
            eventHandler(.init(kind: .info, message: "Checking the latest release from \(owner)/\(repository)."))
            let release = try await releaseClient.latestRelease(owner: owner, repository: repository)
            let asset = try GitHubAssetSelector.selectBestAsset(from: release.assets, preferredFileName: payload.preferredFileName)
            let releaseDirectory = payloadDirectory.appendingPathComponent(release.versionLabel, isDirectory: true)
            eventHandler(.init(kind: .info, message: "Downloading \(asset.name) (\(release.versionLabel))."))
            let downloaded = try await downloader.download(from: asset.downloadURL, to: releaseDirectory, preferredName: asset.name)
            eventHandler(.init(kind: .info, message: "Locating payload file."))
            return try extractor.payloadFile(from: downloaded, workDirectory: releaseDirectory, preferredFileName: payload.preferredFileName)

        case .latestForgejoRelease(let baseURL, let owner, let repository):
            eventHandler(.init(kind: .info, message: "Checking the latest release from \(owner)/\(repository)."))
            let release = try await releaseClient.latestForgejoRelease(baseURL: baseURL, owner: owner, repository: repository)
            let asset = try GitHubAssetSelector.selectBestAsset(from: release.assets, preferredFileName: payload.preferredFileName)
            let releaseDirectory = payloadDirectory.appendingPathComponent(release.versionLabel, isDirectory: true)
            eventHandler(.init(kind: .info, message: "Downloading \(asset.name) (\(release.versionLabel))."))
            let downloaded = try await downloader.download(from: asset.downloadURL, to: releaseDirectory, preferredName: asset.name)
            eventHandler(.init(kind: .info, message: "Locating payload file."))
            return try extractor.payloadFile(from: downloaded, workDirectory: releaseDirectory, preferredFileName: payload.preferredFileName)
        }
    }

    public static func defaultBaseDirectory() -> URL {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return (applicationSupport ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("PayloadSender", isDirectory: true)
            .appendingPathComponent("Payloads", isDirectory: true)
    }
}
