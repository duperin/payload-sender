import AppKit
import Foundation
import PS5PayloadKit

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
    @Published var customPortText: String {
        didSet {
            UserDefaults.standard.set(customPortText, forKey: Self.customPortKey)
        }
    }

    let payloads = PayloadCatalog.all
    private let transferService = PayloadTransferService()
    private static let targetIPKey = "targetIP"
    private static let customPortKey = "customPort"

    init() {
        self.targetIP = UserDefaults.standard.string(forKey: Self.targetIPKey) ?? ""
        let savedCustomPort = UserDefaults.standard.string(forKey: Self.customPortKey) ?? "9021"
        self.customPortText = Self.normalizedPortText(savedCustomPort)
    }

    func send(_ payload: PayloadDefinition) {
        let trimmedIP = targetIP.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIP.isEmpty else {
            append(.init(kind: .failure, message: "Enter the console IP address before sending."))
            return
        }

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
        let trimmedIP = targetIP.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIP.isEmpty else {
            append(.init(kind: .failure, message: "Enter the console IP address before sending."))
            return
        }

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

    func clearLog() {
        events.removeAll()
        append(.init(kind: .info, message: "Log cleared."))
    }

    private func append(_ event: PayloadEvent) {
        events.append(event)
        if events.count > 80 {
            events.removeFirst(events.count - 80)
        }
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
}
