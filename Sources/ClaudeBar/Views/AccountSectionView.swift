import SwiftUI

// One collapsible section for a single account in the dropdown panel.
struct AccountSectionView: View {
    @EnvironmentObject var appState: AppState
    let account: Account

    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            // The detail rows depend on what kind of usage data we have
            Group {
                switch appState.usageByAccount[account.id] {
                case .localFile(let usage):
                    LocalUsageView(usage: usage, monthlyBudget: account.monthlyBudgetUSD)
                case .apiUsage(let usage):
                    APIUsageView(usage: usage)
                case .enterprise(let usage):
                    EnterpriseUsageView(usage: usage)
                case .loading:
                    HStack {
                        ProgressView().scaleEffect(0.7)
                        Text("Loading…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                case .error(let message):
                    Label(message, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.vertical, 4)
                case nil:
                    Text("No data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: account.type.systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(account.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                // Show account type badge
                Text(account.type.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.15), in: Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}
