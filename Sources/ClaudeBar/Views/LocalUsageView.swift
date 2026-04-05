import SwiftUI

// Detail rows for a Claude Code / Pro account.
// Shows raw token counts for each time window and the reset countdown.
struct LocalUsageView: View {
    let usage: LocalFileUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            UsageRow(
                label: "Last 5 hours",
                value: usage.last5Hours.formattedTotal + " tokens",
                subtitle: resetSubtitle
            )
            UsageRow(
                label: "Last 7 days",
                value: usage.last7Days.formattedTotal + " tokens"
            )
            if let topModel {
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

// MARK: - Shared sub-components (used by API and Enterprise views too)

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
