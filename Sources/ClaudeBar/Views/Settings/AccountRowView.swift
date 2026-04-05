import SwiftUI

// A single row in the Settings account list.
struct AccountRowView: View {
    @EnvironmentObject var accountStore: AccountStore
    @EnvironmentObject var appState: AppState
    let account: Account

    @State private var showingEdit = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: account.type.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .fontWeight(.medium)
                Text(account.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let slugs = account.includedProjectSlugs {
                    Text("\(slugs.count) project\(slugs.count == 1 ? "" : "s") selected")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                if account.type == .claudeCode && account.costMultiplier != 1.0 {
                    Text(String(format: "%.2f× pricing adjustment", account.costMultiplier))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Show a "key stored" badge for accounts that require an API key
            if account.type != .claudeCode {
                let hasKey = KeychainService.exists(for: account.id)
                Label(hasKey ? "Key stored" : "No key", systemImage: hasKey ? "key.fill" : "key")
                    .font(.caption2)
                    .foregroundStyle(hasKey ? .green : .red)
            }

            // Edit button
            Button {
                showingEdit = true
            } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Edit account")

            // Delete button
            Button(role: .destructive) {
                accountStore.remove(account)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .help("Remove account")
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEdit) {
            EditAccountView(account: account) { updated in
                accountStore.update(updated)
                Task { await appState.fetchSingle(updated) }
            }
        }
    }
}
