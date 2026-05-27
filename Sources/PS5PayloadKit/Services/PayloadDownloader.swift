import Foundation

public struct PayloadDownloader: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func download(from url: URL, to directory: URL, preferredName: String? = nil) async throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var request = URLRequest(url: url)
        request.setValue("PayloadSender", forHTTPHeaderField: "User-Agent")

        let (temporaryURL, response) = try await session.download(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw PayloadError.downloadFailed("server responded with HTTP \(code).")
        }

        let fileName = preferredName ?? url.lastPathComponent
        let destination = directory.appendingPathComponent(fileName.isEmpty ? "payload.bin" : fileName)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        return destination
    }
}
