import AppKit
import Foundation
import PS5PayloadKit

enum PayloadVersionState: Equatable {
    case loading
    case available(String)
    case unavailable

    var label: String {
        switch self {
        case .loading:
            return "Checking"
        case .available(let version):
            return version
        case .unavailable:
            return "Unavailable"
        }
    }
}

@MainActor
final class PayloadViewModel: ObservableObject {
    @Published var targetIP: String {
        didSet {
            UserDefaults.standard.set(targetIP, forKey: Self.targetIPKey)
        }
    }
    @Published private(set) var events: [PayloadEvent] = [
        PayloadEvent(kind: .info, message: "Enter the console IP address and choose a payload.")
    ]
    @Published private(set) var activePayloadID: String?
    @Published private(set) var isTestingConnection = false
    @Published private(set) var isRefreshingVersions = false
    @Published private(set) var versionStates: [PayloadDefinition.ID: PayloadVersionState] = [:]
    @Published var customPortText: String {
        didSet {
            UserDefaults.standard.set(customPortText, forKey: Self.customPortKey)
        }
    }

    let payloads = PayloadCatalog.all
    private let transferService = PayloadTransferService()
    private let releaseClient = GitHubReleaseClient()
    private var didRefreshVersions = false
    private static let targetIPKey = "targetIP"
    private static let customPortKey = "customPort"

    init() {
        self.targetIP = UserDefaults.standard.string(forKey: Self.targetIPKey) ?? ""
        let savedCustomPort = UserDefaults.standard.string(forKey: Self.customPortKey) ?? "9021"
        self.customPortText = Self.normalizedPortText(savedCustomPort)
    }

    func refreshPayloadVersions(force: Bool = false) async {
        guard force || !didRefreshVersions else { return }
        didRefreshVersions = true
        isRefreshingVersions = true

        for payload in payloads {
            versionStates[payload.id] = .loading
        }

        await withTaskGroup(of: (PayloadDefinition.ID, PayloadVersionState).self) { group in
            for payload in payloads {
                let releaseClient = releaseClient
                group.addTask {
                    let state = await Self.versionState(for: payload, releaseClient: releaseClient)
                    return (payload.id, state)
                }
            }

            for await (payloadID, state) in group {
                versionStates[payloadID] = state
            }
        }

        isRefreshingVersions = false
        if force {
            append(.init(kind: .success, message: "Payload versions refreshed."))
        }
    }

    func send(_ payload: PayloadDefinition) {
        guard let trimmedIP = validatedTargetIP() else { return }

        activePayloadID = payload.id
        append(.init(kind: .info, message: "Starting \(payload.name) transfer."))

        Task {
            await transferService.send(payload: payload, to: trimmedIP) { [weak self] event in
                Task { @MainActor in
                    self?.append(event)
                    if event.kind == .success || event.kind == .failure {
                        self?.activePayloadID = nil
                    }
                }
            }
        }
    }

    func chooseAndSendCustomPayload() {
        guard let trimmedIP = validatedTargetIP() else { return }

        let panel = NSOpenPanel()
        panel.title = "Choose Custom Payload"
        let selectedPort = Self.port(from: customPortText)
        customPortText = "\(selectedPort)"

        panel.message = "Select a payload file to send to port \(selectedPort)."
        panel.prompt = "Send"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let file = panel.url else {
            append(.init(kind: .info, message: "Custom payload selection cancelled."))
            return
        }

        sendCustomPayload(file: file, to: trimmedIP, port: selectedPort)
    }

    func sendDroppedCustomPayload(file: URL) {
        guard let trimmedIP = validatedTargetIP() else { return }
        let selectedPort = Self.port(from: customPortText)
        customPortText = "\(selectedPort)"
        sendCustomPayload(file: file, to: trimmedIP, port: selectedPort)
    }

    func testConnection() {
        guard let trimmedIP = validatedTargetIP() else { return }
        guard !isTestingConnection else { return }

        let ports = Array(Set(payloads.map(\.port) + [Self.port(from: customPortText)])).sorted()
        isTestingConnection = true
        append(.init(kind: .info, message: "Testing connection to \(trimmedIP)."))

        Task {
            let sender = TCPPayloadSender()
            var results: [String] = []

            for port in ports {
                do {
                    try sender.testConnection(to: trimmedIP, port: port, timeout: 2)
                    results.append("\(port): open")
                } catch {
                    results.append("\(port): closed")
                }
            }

            await MainActor.run {
                append(.init(kind: .info, message: "Connection test: \(results.joined(separator: ", "))."))
                isTestingConnection = false
            }
        }
    }

    func clearLog() {
        events.removeAll()
        append(.init(kind: .info, message: "Log cleared."))
    }

    private func sendCustomPayload(file: URL, to trimmedIP: String, port selectedPort: Int) {
        activePayloadID = "custom-payload"
        append(.init(kind: .info, message: "Starting custom payload transfer: \(file.lastPathComponent)."))

        Task {
            await transferService.sendCustomFile(file: file, to: trimmedIP, port: selectedPort) { [weak self] event in
                Task { @MainActor in
                    self?.append(event)
                    if event.kind == .success || event.kind == .failure {
                        self?.activePayloadID = nil
                    }
                }
            }
        }
    }

    private func append(_ event: PayloadEvent) {
        events.append(event)
        if events.count > 80 {
            events.removeFirst(events.count - 80)
        }
    }

    private func validatedTargetIP() -> String? {
        let trimmedIP = targetIP.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIP.isEmpty else {
            append(.init(kind: .failure, message: "Enter the console IP address before continuing."))
            return nil
        }

        guard IPv4AddressValidator.isValid(trimmedIP) else {
            append(.init(kind: .failure, message: "Enter a valid IPv4 address."))
            return nil
        }

        return trimmedIP
    }

    static func normalizedPortText(_ text: String) -> String {
        let digits = text.filter(\.isNumber)
        guard let port = Int(digits), !digits.isEmpty else {
            return "9021"
        }
        return "\(PortValidator.clamped(port))"
    }

    private static func port(from text: String) -> Int {
        let digits = text.filter(\.isNumber)
        guard let port = Int(digits), !digits.isEmpty else {
            return 9021
        }
        return PortValidator.clamped(port)
    }

    private static func versionState(for payload: PayloadDefinition, releaseClient: GitHubReleaseClient) async -> PayloadVersionState {
        do {
            switch payload.source {
            case .latestGitHubRelease(let owner, let repository):
                let release = try await releaseClient.latestRelease(owner: owner, repository: repository)
                return .available(release.versionLabel)

            case .latestForgejoRelease(let baseURL, let owner, let repository):
                let release = try await releaseClient.latestForgejoRelease(baseURL: baseURL, owner: owner, repository: repository)
                return .available(release.versionLabel)

            case .directFile:
                return .available(payload.fixedVersionLabel ?? "Fixed")
            }
        } catch {
            return .unavailable
        }
    }
}
