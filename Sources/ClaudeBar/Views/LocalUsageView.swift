import SwiftUI

struct LocalUsageView: View {
    let usage: LocalFileUsage
    var monthlyBudget: Double?

    private var monthElapsedFraction: Double {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let end   = cal.date(byAdding: .month, value: 1, to: start)!
        return min(now.timeIntervalSince(start) / end.timeIntervalSince(start), 1.0)
    }

    private var spendFraction: Double? {
        guard let budget = monthlyBudget, budget > 0 else { return nil }
        return min(usage.estimatedCostUSD / budget, 1.0)
    }

    private var isAheadOfPace: Bool {
        guard let sf = spendFraction else { return false }
        return sf > monthElapsedFraction
    }

    // Projects sorted by estimated cost this month, highest first
    private var projectsBySpend: [(slug: String, cost: Double)] {
        usage.projectBreakdown
            .map { slug, tokens in
                let cost = TokenCostEstimator.estimateTotal(
                    // estimateTotal expects a model→usage dict; we only have total tokens
                    // per project, so we use the top model as a proxy for pricing
                    [topModelName: tokens]
                )
                return (slug: slug, cost: cost)
            }
            .sorted { $0.cost > $1.cost }
    }

    private var topModelName: String {
        usage.modelBreakdown.max(by: { $0.value.total < $1.value.total })?.key ?? "claude-sonnet-4-6"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Budget + pace bars (only when budget is configured)
            if let budget = monthlyBudget {
                let sf = spendFraction ?? 0
                UsageRow(
                    label: "This month",
                    value: "\(TokenCostEstimator.formatUSD(usage.estimatedCostUSD)) / \(TokenCostEstimator.formatUSD(budget))"
                )
                HStack(spacing: 4) {
                    Text("Spend")
                        .font(.caption2).foregroundStyle(.secondary)
                        .frame(width: 38, alignment: .leading)
                    UsageBar(value: sf, tint: isAheadOfPace ? .orange : .accentColor)
                    Text(String(format: "%.0f%%", sf * 100))
                        .font(.caption2).foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }
                HStack(spacing: 4) {
                    Text("Month")
                        .font(.caption2).foregroundStyle(.secondary)
                        .frame(width: 38, alignment: .leading)
                    UsageBar(value: monthElapsedFraction, tint: .secondary)
                    Text(String(format: "%.0f%%", monthElapsedFraction * 100))
                        .font(.caption2).foregroundStyle(.secondary)
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
            }

            // Project spend breakdown (show when there's more than one project)
            if projectsBySpend.count > 1 {
                Divider().padding(.vertical, 2)
                Text("By project (this month)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                let shown = projectsBySpend.prefix(5)
                ForEach(shown, id: \.slug) { item in
                    HStack {
                        Text(ProjectDiscovery.displayName(for: item.slug))
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Text(TokenCostEstimator.formatUSD(item.cost))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(item.cost > 0 ? .primary : .secondary)
                    }
                }

                if projectsBySpend.count > 5 {
                    Text("+ \(projectsBySpend.count - 5) more projects")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Token windows
            Divider().padding(.vertical, 2)
            UsageRow(
                label: "Last 5 hours",
                value: usage.last5Hours.formattedTotal + " tokens",
                subtitle: resetSubtitle
            )
            UsageRow(
                label: "Last 7 days",
                value: usage.last7Days.formattedTotal + " tokens"
            )
        }
    }

    private var resetSubtitle: String? {
        guard let remaining = usage.timeUntil5HourReset() else { return nil }
        return "Resets in \(formatTimeRemaining(remaining))"
    }
}

// MARK: - Shared sub-components

struct UsageRow: View {
    let label: String
    let value: String
    var subtitle: String? = nil

    var body: some View {
        HStack(alignment: .top) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(value).font(.caption).fontWeight(.medium)
                if let subtitle {
                    Text(subtitle).font(.caption2).foregroundStyle(.secondary)
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
                RoundedRectangle(cornerRadius: 3).fill(.secondary.opacity(0.2))
                RoundedRectangle(cornerRadius: 3)
                    .fill(tint)
                    .frame(width: geo.size.width * max(value, 0))
            }
        }
        .frame(height: 5)
    }
}
