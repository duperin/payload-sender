import Foundation

public struct PayloadExtractor: Sendable {
    public init() {}

    public func payloadFile(from downloadedFile: URL, workDirectory: URL, preferredFileName: String? = nil) throws -> URL {
        let extensionName = downloadedFile.pathExtension.lowercased()
        if extensionName == "elf" || extensionName == "bin" || extensionName == "js" {
            return downloadedFile
        }

        let extractionDirectory = workDirectory.appendingPathComponent("extracted", isDirectory: true)
        if FileManager.default.fileExists(atPath: extractionDirectory.path) {
            try FileManager.default.removeItem(at: extractionDirectory)
        }
        try FileManager.default.createDirectory(at: extractionDirectory, withIntermediateDirectories: true)

        if extensionName == "zip" {
            try run("/usr/bin/ditto", arguments: ["-x", "-k", downloadedFile.path, extractionDirectory.path])
        } else if extensionName == "tar" || downloadedFile.lastPathComponent.lowercased().hasSuffix(".tar.gz") || extensionName == "gz" {
            try run("/usr/bin/tar", arguments: ["-xf", downloadedFile.path, "-C", extractionDirectory.path])
        } else {
            throw PayloadError.extractionFailed("unsupported format: \(downloadedFile.lastPathComponent).")
        }

        return try PayloadFileResolver.selectPayloadFile(
            from: PayloadFileResolver.recursiveFiles(under: extractionDirectory),
            preferredFileName: preferredFileName
        )
    }

    private func run(_ launchPath: String, arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        let errorPipe = Pipe()
        process.standardError = errorPipe
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw PayloadError.extractionFailed(message?.isEmpty == false ? message! : "process exited with code \(process.terminationStatus).")
        }
    }
}
