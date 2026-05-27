import PS5PayloadKit
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PayloadViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color.accentColor.opacity(0.10),
                    Color(nsColor: .controlBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                header
                NetworkTargetView(targetIP: $viewModel.targetIP)
                PayloadButtonGrid(
                    payloads: viewModel.payloads,
                    activePayloadID: viewModel.activePayloadID,
                    versionStates: viewModel.versionStates,
                    customPortText: $viewModel.customPortText,
                    action: viewModel.send,
                    customAction: viewModel.chooseAndSendCustomPayload
                )
                StatusLogView(events: viewModel.events, clearAction: viewModel.clearLog)
            }
            .padding(24)
        }
        .task {
            await viewModel.refreshPayloadVersions()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            HeaderAppIcon()
                .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text("Payload Sender")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
            }

            Spacer()
        }
    }
}

private struct HeaderAppIcon: View {
    var body: some View {
        if let url = Bundle.main.url(forResource: "AppIconSource", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color.accentColor)
        }
    }
}
