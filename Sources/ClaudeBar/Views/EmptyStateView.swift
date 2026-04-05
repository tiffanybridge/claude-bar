import SwiftUI

// Shown when no accounts have been configured yet.
struct EmptyStateView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("No accounts yet")
                .font(.subheadline)
                .fontWeight(.medium)

            Text("Add a Claude Code, API, or Enterprise account to start tracking usage.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Account") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
