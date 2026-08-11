import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject private var store = SettingsStore.shared
    @State private var trusted = AXIsProcessTrusted()

    private let permissionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ScrollHot")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $store.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            Text("Remaps a click of the scroll-wheel button to a keyboard shortcut.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Shortcut")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HotKeyRecorderView(hotKey: $store.hotKey)
                    .frame(height: 36)
            }

            if !trusted {
                Label("Grant Accessibility permission in System Settings for ScrollHot to work.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if let lastFired = store.lastFired {
                Text("Last fired \(lastFired.formatted(date: .omitted, time: .standard))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Quit ScrollHot") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 300)
        .onReceive(permissionTimer) { _ in
            trusted = AXIsProcessTrusted()
        }
    }
}
