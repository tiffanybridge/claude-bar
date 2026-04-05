import Foundation

// The result of fetching usage for one account.
// Each account type produces a different variant.
enum AccountUsage {
    case loading                    // fetch is in progress
    case error(String)              // something went wrong
    case localFile(LocalFileUsage)  // Claude Code / Pro (reads ~/.claude/)
    case apiUsage(APIUsage)         // Anthropic API account
    case enterprise(EnterpriseUsage)// Enterprise org account
}

// Usage data parsed from local ~/.claude/projects/**/*.jsonl files.
// Covers Claude Code / Pro accounts.
struct LocalFileUsage {
    let accountId: UUID
    let last5Hours: TokenUsage      // The rolling 5-hour rate-limit window for Pro
    let last24Hours: TokenUsage
    let last7Days: TokenUsage
    let lastActivity: Date?         // Timestamp of the most recent assistant message
    let modelBreakdown: [String: TokenUsage]  // e.g. ["claude-sonnet-4-6": ...]
    let estimatedCostUSD: Double
    let refreshedAt: Date

    // Time remaining until the 5-hour window resets from the first message in it
    func timeUntil5HourReset() -> TimeInterval? {
        guard let last = lastActivity else { return nil }
        let windowStart = last.addingTimeInterval(-5 * 3600)
        let resetAt = windowStart.addingTimeInterval(5 * 3600)
        let remaining = resetAt.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }
}

// Usage data fetched from the Anthropic API.
struct APIUsage {
    let accountId: UUID
    let thisMonthTokens: TokenUsage
    let estimatedCostUSD: Double
    let modelBreakdown: [String: TokenUsage]
    let refreshedAt: Date
}

// Usage data fetched from the Enterprise Analytics API.
struct EnterpriseUsage {
    let accountId: UUID
    let totalSpendUSD: Double
    let spendLimitUSD: Double?       // nil if no spending limit is set
    let periodStart: Date
    let periodEnd: Date
    let refreshedAt: Date

    // What fraction of the budget has been spent (0.0 – 1.0)
    var percentUsed: Double? {
        guard let limit = spendLimitUSD, limit > 0 else { return nil }
        return min(totalSpendUSD / limit, 1.0)
    }

    // What fraction of the billing period has elapsed (0.0 – 1.0)
    var percentOfPeriodElapsed: Double {
        let total = periodEnd.timeIntervalSince(periodStart)
        let elapsed = Date().timeIntervalSince(periodStart)
        guard total > 0 else { return 0 }
        return min(elapsed / total, 1.0)
    }

    // True when spending pace exceeds the time elapsed in the period
    var isAheadOfPace: Bool {
        guard let pct = percentUsed else { return false }
        return pct > percentOfPeriodElapsed
    }
}
