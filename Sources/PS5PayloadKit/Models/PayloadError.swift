import Foundation

public enum PayloadError: Error, Equatable, LocalizedError {
    case invalidIP
    case noReleaseAssets
    case payloadAssetNotFound
    case payloadFileNotFound
    case downloadFailed(String)
    case extractionFailed(String)
    case connectionFailed(String)
    case sendFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidIP:
            return "Invalid destination IP."
        case .noReleaseAssets:
            return "The release does not include downloadable assets."
        case .payloadAssetNotFound:
            return "No compatible payload asset was found in the release."
        case .payloadFileNotFound:
            return "No .elf, .bin, or .js payload file was found in the download."
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .extractionFailed(let message):
            return "Payload extraction failed: \(message)"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .sendFailed(let message):
            return "Send failed: \(message)"
        }
    }
}
