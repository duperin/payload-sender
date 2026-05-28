import PS5PayloadKit
import SwiftUI
import UniformTypeIdentifiers

struct PayloadButtonGrid: View {
    let payloads: [PayloadDefinition]
    let activePayloadID: String?
    let isRefreshingVersions: Bool
    let versionStates: [PayloadDefinition.ID: PayloadVersionState]
    @Binding var customPortText: String
    let refreshVersionsAction: () -> Void
    let action: (PayloadDefinition) -> Void
    let customAction: () -> Void
    let customDropAction: (URL) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 210), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Payloads", systemImage: "shippingbox.fill")
                    .font(.headline)
                Spacer()
                Button(action: refreshVersionsAction) {
                    if isRefreshingVersions {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(isRefreshingVersions)
                .help("Refresh payload versions")
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ForEach(payloads) { payload in
                    Button {
                        action(payload)
                    } label: {
                        HStack(spacing: 12) {
                            versionChip(for: payload)
                                .frame(width: 64, alignment: .leading)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(payload.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(payload.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if activePayloadID == payload.id {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .frame(minHeight: 72)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(activePayloadID == payload.id ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.08))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(activePayloadID != nil)
                    .help("Download and send \(payload.name)")
                }

                HStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Custom payload")
                            .font(.headline)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Text("Port")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("9021", text: $customPortText)
                                .textFieldStyle(.plain)
                                .font(.caption.monospacedDigit())
                                .frame(width: 48)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                                .onChange(of: customPortText) { _, newValue in
                                    let digits = newValue.filter(\.isNumber)
                                    if digits != newValue {
                                        customPortText = digits
                                    }
                                }
                                .onSubmit {
                                    customPortText = normalizedPortText(customPortText)
                                }
                        }
                    }

                    Spacer()

                    if activePayloadID == "custom-payload" {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button(action: customAction) {
                            Image(systemName: "paperplane.fill")
                        }
                        .buttonStyle(.borderless)
                        .disabled(activePayloadID != nil)
                        .help("Choose and send a custom payload file")
                    }
                }
                .padding(14)
                .frame(minHeight: 72)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(activePayloadID == "custom-payload" ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.08))
                }
                .disabled(activePayloadID != nil)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleCustomPayloadDrop(providers)
                }
                .help("Drop a custom payload file here or choose one with the send button")
            }
        }
    }

    private func normalizedPortText(_ text: String) -> String {
        let digits = text.filter(\.isNumber)
        guard let port = Int(digits), !digits.isEmpty else {
            return "9021"
        }
        return "\(PortValidator.clamped(port))"
    }

    private func handleCustomPayloadDrop(_ providers: [NSItemProvider]) -> Bool {
        guard activePayloadID == nil,
              let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?
            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else if let itemURL = item as? URL {
                url = itemURL
            } else {
                url = nil
            }

            guard let url else { return }
            Task { @MainActor in
                customDropAction(url)
            }
        }

        return true
    }

    @ViewBuilder
    private func versionChip(for payload: PayloadDefinition) -> some View {
        if let state = versionStates[payload.id] {
            HStack(spacing: 4) {
                if state == .loading {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.55)
                        .frame(width: 8, height: 8)
                }

                Text(state.label)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(state == .unavailable ? .secondary : Color.accentColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                (state == .unavailable ? Color.secondary.opacity(0.12) : Color.accentColor.opacity(0.14)),
                in: Capsule()
            )
            .help(state == .unavailable ? "Version could not be checked" : "Latest available version")
        } else {
            Text("--")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.12), in: Capsule())
                .help("Version pending")
        }
    }
}
