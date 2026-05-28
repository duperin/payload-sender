import SwiftUI

struct NetworkTargetView: View {
    @Binding var targetIP: String
    let isTesting: Bool
    let testAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Destination", systemImage: "network")
                .font(.headline)

            HStack(spacing: 12) {
                TextField("Console IP, e.g. 192.168.1.45", text: $targetIP)
                    .textFieldStyle(.plain)
                    .font(.system(.title3, design: .monospaced))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button(action: testAction) {
                    if isTesting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "network")
                    }
                }
                .buttonStyle(.borderless)
                .frame(width: 32, height: 32)
                .disabled(isTesting)
                .help("Test connection")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
