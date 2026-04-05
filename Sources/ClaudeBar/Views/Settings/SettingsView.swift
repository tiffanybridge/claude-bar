import SwiftUI

// The main Settings window. Lists all configured accounts and lets you add/remove them.
struct SettingsView: View {
    @EnvironmentObject var accountStore: AccountStore
    @EnvironmentObject var appState: AppState
    @State private var showingAddAccount = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Window title bar area
            HStack {
                Text("ClaudeBar Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    showingAddAccount = true
                } label: {
                    Label("Add Account", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()

            Divider()

            if accountStore.accounts.isEmpty {
                // Placeholder when no accounts exist
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No accounts configured")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Click \"Add Account\" to get started.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(accountStore.accounts) { account in
                        AccountRowView(account: account)
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountView { newAccount in
                accountStore.add(newAccount)
                Task { await appState.fetchSingle(newAccount) }
            }
        }
    }
}
