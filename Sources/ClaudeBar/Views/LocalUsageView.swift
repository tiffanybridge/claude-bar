import SwiftUI

// Detail rows for a Claude Code account.
// Shows rolling usage windows, estimated cost, and an optional budget bar.
struct LocalUsageView: View {
    let usage: LocalFileUsage
    var monthlyBudget: Double?  // nil = no budget configured

    // How far through the current calendar month we are (0.0 – 1.0)
    private var monthElapsedFraction: Double {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let end   = cal.date(byAdding: .month, value: 1, to: start)!
        let total = end.timeIntervalSince(start)
        let elapsed = now.timeIntervalSince(start)
        return min(elapsed / total, 1.0)
    }

    private var spendFraction: Double? {
        guard let budget = monthlyBudget, budget > 0 else { return nil }
        return min(usage.estimatedCostUSD / budget, 1.0)
    }

    private var isAheadOfPace: Bool {
        guard let sf = spendFraction else { return false }
        return sf > monthElapsedFraction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Budget section — only shown when a budget is configured
            if let budget = monthlyBudget {
                let sf = spendFraction ?? 0
                let paceColor: Color = isAheadOfPace ? .orange : .accentColor

                UsageRow(
                    label: "This month",
                    value: "\(TokenCostEstimator.formatUSD(usage.estimatedCostUSD)) / \(TokenCostEstimator.formatUSD(budget))"
                )

                HStack(spacing: 4) {
                    Text("Spend")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 38, alignment: .leading)
                    UsageBar(value: sf, tint: paceColor)
                    Text(String(format: "%.0f%%", sf * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }

                HStack(spacing: 4) {
                    Text("Month")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 38, alignment: .leading)
                    UsageBar(value: monthElapsedFraction, tint: .secondary)
                    Text(String(format: "%.0f%%", monthElapsedFraction * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }

                HStack(spacing: 4) {
                    Image(systemName: isAheadOfPace ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(isAheadOfPace ? .orange : .green)
                        .font(.caption2)
                    Text(isAheadOfPace ? "Ahead of pace" : "On track")
                        .font(.caption2)
                        .foregroundStyle(isAheadOfPace ? .orange : .secondary)
                }

                Divider().padding(.vertical, 2)
            }

            // Token windows
            UsageRow(
                label: "Last 5 hours",
                value: usage.last5Hours.formattedTotal + " tokens",
                subtitle: resetSubtitle
            )
            UsageRow(
                label: "Last 7 days",
                value: usage.last7Days.formattedTotal + " tokens"
            )

            // Cost (only shown when no budget is set, to avoid repetition)
            if monthlyBudget == nil && usage.estimatedCostUSD > 0 {
                UsageRow(
                    label: "Est. cost (7 days)",
                    value: TokenCostEstimator.formatUSD(usage.estimatedCostUSD)
                )
            }

            // Top model
            if let topModel = topModel {
                UsageRow(
                    label: "Top model",
                    value: topModel.name,
                    subtitle: topModel.tokens.formattedTotal + " tokens"
                )
            }
        }
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

// MARK: - Reusable sub-components (shared with other usage views)

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

struct UsageBar: View {
    let value: Double
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
