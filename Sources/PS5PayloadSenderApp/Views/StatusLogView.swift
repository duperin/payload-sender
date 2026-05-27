import PS5PayloadKit
import SwiftUI

struct StatusLogView: View {
    let events: [PayloadEvent]
    let clearAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Status", systemImage: "waveform.path.ecg")
                    .font(.headline)
                Spacer()
                Button(action: clearAction) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Clear log")
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(events) { event in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Image(systemName: symbol(for: event.kind))
                                    .foregroundStyle(color(for: event.kind))
                                    .frame(width: 18)

                                Text(event.date, style: .time)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 66, alignment: .leading)

                                Text(event.message)
                                    .font(.callout)
                                    .foregroundStyle(event.kind == .failure ? .primary : .secondary)
                                    .textSelection(.enabled)

                                Spacer(minLength: 0)
                            }
                            .id(event.id)
                        }
                    }
                    .padding(12)
                }
                .frame(minHeight: 190)
                .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onChange(of: events.last?.id) { _, id in
                    guard let id else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func symbol(for kind: PayloadEvent.Kind) -> String {
        switch kind {
        case .info:
            return "circle.dotted"
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "xmark.octagon.fill"
        }
    }

    private func color(for kind: PayloadEvent.Kind) -> Color {
        switch kind {
        case .info:
            return .secondary
        case .success:
            return .green
        case .failure:
            return .red
        }
    }
}
