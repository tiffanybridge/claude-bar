import SwiftUI

// Detail rows for a Claude Code / Pro account.
// Shows rolling usage windows and estimated cost.
struct LocalUsageView: View {
    let usage: LocalFileUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 5-hour window — the Claude Pro rate-limit window
            UsageRow(
                label: "Last 5 hours",
                value: usage.last5Hours.formattedTotal + " tokens",
                subtitle: resetSubtitle
            )

            UsageBar(
                value: last5HourFraction,
                tint: last5HourFraction > 0.85 ? .red : .accentColor
            )

            // 7-day window
            UsageRow(
                label: "Last 7 days",
                value: usage.last7Days.formattedTotal + " tokens"
            )

            // Estimated cost
            if usage.estimatedCostUSD > 0 {
                UsageRow(
                    label: "Est. cost (7 days)",
                    value: TokenCostEstimator.formatUSD(usage.estimatedCostUSD)
                )
            }

            // Model breakdown (collapsed to top model to save space)
            if let topModel = topModel {
                UsageRow(
                    label: "Top model",
                    value: topModel.name,
                    subtitle: topModel.tokens.formattedTotal + " tokens"
                )
            }
        }
    }

    // The fraction of the 5-hour window used. Approximation: we compare
    // the 5-hour token count against the 7-day average per 5-hour window.
    private var last5HourFraction: Double {
        let avg = usage.last7Days.total > 0
            ? Double(usage.last7Days.total) / (7 * 24 / 5)  // avg per 5h period over 7 days
            : 0
        guard avg > 0 else { return min(Double(usage.last5Hours.total) / 50_000, 1.0) }
        return min(Double(usage.last5Hours.total) / avg, 1.0)
    }

    private var resetSubtitle: String? {
        guard let remaining = usage.timeUntil5HourReset() else { return nil }
        return "Resets in \(formatTimeRemaining(remaining))"
    }

    private var topModel: (name: String, tokens: TokenUsage)? {
        usage.modelBreakdown
            .max(by: { $0.value.total < $1.value.total })
            .map { ($0.key, $0.value) }
    }
}

// MARK: - Reusable sub-components

// A label + value row, with an optional smaller subtitle below the value.
struct UsageRow: View {
    let label: String
    let value: String
    var subtitle: String? = nil

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// A thin horizontal progress bar.
struct UsageBar: View {
    let value: Double   // 0.0 – 1.0
    var tint: Color = .accentColor

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.secondary.opacity(0.2))
                RoundedRectangle(cornerRadius: 3)
                    .fill(tint)
                    .frame(width: geo.size.width * max(value, 0))
            }
        }
        .frame(height: 5)
    }
}
