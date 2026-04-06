import SwiftUI

// Detail rows for an Anthropic API console account.
// Shows last 7 days of token usage and estimated cost.
struct APIUsageView: View {
    let usage: APIUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            UsageRow(
                label: "Last 7 days",
                value: usage.last7Days.formattedTotal + " tokens"
            )
            UsageRow(
                label: "Est. cost (7 days)",
                value: TokenCostEstimator.formatUSD(usage.estimatedCostUSD)
            )
        }
    }
}
