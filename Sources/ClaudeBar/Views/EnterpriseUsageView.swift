import SwiftUI

// Detail rows for an Enterprise account.
// Shows spending vs. limit, and a budget-pacing indicator.
struct EnterpriseUsageView: View {
    let usage: EnterpriseUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Spend vs. limit summary
            if let limit = usage.spendLimitUSD {
                UsageRow(
                    label: "Spend this period",
                    value: "\(TokenCostEstimator.formatUSD(usage.totalSpendUSD)) / \(TokenCostEstimator.formatUSD(limit))"
                )
            } else {
                UsageRow(
                    label: "Spend this period",
                    value: TokenCostEstimator.formatUSD(usage.totalSpendUSD)
                )
            }

            // Spend progress bar
            if let pct = usage.percentUsed {
                HStack(spacing: 4) {
                    Text("Spend")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)
                    UsageBar(
                        value: pct,
                        tint: usage.isAheadOfPace ? .orange : .accentColor
                    )
                    Text(String(format: "%.0f%%", pct * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }

                // Month-elapsed progress bar
                HStack(spacing: 4) {
                    Text("Period")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)
                    UsageBar(
                        value: usage.percentOfPeriodElapsed,
                        tint: .secondary
                    )
                    Text(String(format: "%.0f%%", usage.percentOfPeriodElapsed * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }

                // Pace indicator
                HStack(spacing: 4) {
                    Image(systemName: usage.isAheadOfPace ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(usage.isAheadOfPace ? .orange : .green)
                        .font(.caption2)
                    Text(usage.isAheadOfPace ? "Ahead of pace" : "On track")
                        .font(.caption2)
                        .foregroundStyle(usage.isAheadOfPace ? .orange : .secondary)
                }
                .padding(.top, 2)
            }

            // Billing period dates
            UsageRow(
                label: "Period",
                value: "\(usage.periodStart.formatted(.dateTime.month().day())) – \(usage.periodEnd.formatted(.dateTime.month().day()))"
            )
        }
    }
}
