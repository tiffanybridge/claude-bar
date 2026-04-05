import SwiftUI

// The root dropdown panel that appears when you click the menu bar icon.
// Shows all configured accounts, each in its own section.
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountStore: AccountStore
    @EnvironmentObject var settingsManager: SettingsWindowManager

    var body: some View {
        VStack(spacing: 0) {
            // Header row with title, refresh button, and settings gear
            HStack {
                Text("Claude Usage")
                    .font(.headline)
                Spacer()
                if appState.isRefreshing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button {
                        Task { await appState.fetchAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .help("Refresh all accounts")
                }
                Button {
                    settingsManager.open(appState: appState, accountStore: accountStore)
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Account list, or empty state if none are configured
            if accountStore.accounts.isEmpty {
                EmptyStateView()
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(accountStore.accounts) { account in
                            AccountSectionView(account: account)
                            if account.id != accountStore.accounts.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 480)
            }

            // Footer: last-refreshed timestamp
            if let refreshed = appState.lastRefreshed {
                Divider()
                Text("Updated \(refreshed, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Divider()

            // Quit button at the bottom
            Button("Quit ClaudeBar") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 6)
        }
        .task {
            // Fetch all accounts when the panel first opens, if we haven't yet
            if appState.lastRefreshed == nil {
                await appState.fetchAll()
            }
        }
    }
}
