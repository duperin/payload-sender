import Foundation

public struct PayloadEvent: Identifiable, Equatable, Sendable {
    public enum Kind: String, Sendable {
        case info
        case success
        case failure
    }

    public let id: UUID
    public let date: Date
    public let kind: Kind
    public let message: String

    public init(id: UUID = UUID(), date: Date = Date(), kind: Kind, message: String) {
        self.id = id
        self.date = date
        self.kind = kind
        self.message = message
    }
}
