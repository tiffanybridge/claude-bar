import SwiftUI

// Detail rows for an Anthropic API account.
// Shows this month's token consumption and estimated cost.
struct APIUsageView: View {
    let usage: APIUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            UsageRow(
                label: "This month (tokens)",
                value: usage.thisMonthTokens.formattedTotal
            )
            UsageRow(
                label: "Est. cost this month",
                value: TokenCostEstimator.formatUSD(usage.estimatedCostUSD)
            )

            // Per-model cost breakdown
            if !usage.modelBreakdown.isEmpty {
                Divider()
                    .padding(.vertical, 2)
                Text("By model")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ForEach(
                    usage.modelBreakdown.sorted(by: { $0.value.total > $1.value.total }),
                    id: \.key
                ) { model, tokens in
                    UsageRow(
                        label: shortModelName(model),
                        value: tokens.formattedTotal,
                        subtitle: TokenCostEstimator.formatUSD(
                            TokenCostEstimator.estimate(tokens, model: model)
                        )
                    )
                }
            }
        }
    }

    // Strips the "claude-" prefix so the model name fits in the narrow panel.
    // "claude-sonnet-4-6" → "Sonnet 4.6"
    private func shortModelName(_ full: String) -> String {
        let name = full
            .replacingOccurrences(of: "claude-", with: "")
            .replacingOccurrences(of: "-", with: " ")
        // Capitalise the first letter
        return name.prefix(1).uppercased() + name.dropFirst()
    }
}
