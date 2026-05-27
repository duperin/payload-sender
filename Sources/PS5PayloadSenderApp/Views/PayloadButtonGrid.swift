import PS5PayloadKit
import SwiftUI

struct PayloadButtonGrid: View {
    let payloads: [PayloadDefinition]
    let activePayloadID: String?
    @Binding var customPortText: String
    let action: (PayloadDefinition) -> Void
    let customAction: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 210), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Payloads", systemImage: "shippingbox.fill")
                .font(.headline)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ForEach(payloads) { payload in
                    Button {
                        action(payload)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: iconName(for: payload))
                                .font(.title3.weight(.semibold))
                                .frame(width: 28)

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
            }
        }
    }

    private func iconName(for payload: PayloadDefinition) -> String {
        payload.port == 50000 ? "bolt.horizontal.circle.fill" : "terminal.fill"
    }

    private func normalizedPortText(_ text: String) -> String {
        let digits = text.filter(\.isNumber)
        guard let port = Int(digits), !digits.isEmpty else {
            return "9021"
        }
        return "\(PortValidator.clamped(port))"
    }
}
