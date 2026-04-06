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
struct LocalFileUsage {
    let accountId: UUID
    let last5Hours: TokenUsage          // Rolling 5-hour rate-limit window (Pro)
    let last24Hours: TokenUsage
    let last7Days: TokenUsage
    let thisMonth: TokenUsage           // Current calendar month
    let lastActivity: Date?
    let modelBreakdown: [String: TokenUsage]    // per model, this month
    let projectBreakdown: [String: TokenUsage]  // per project slug, this month
    let estimatedCostUSD: Double                // based on thisMonth
    let refreshedAt: Date

    func timeUntil5HourReset() -> TimeInterval? {
        guard let last = lastActivity else { return nil }
        let remaining = last.addingTimeInterval(5 * 3600).timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }
}

// Usage data fetched from the Anthropic Admin API.
struct APIUsage {
    let accountId: UUID
    let last7Days: TokenUsage
    let estimatedCostUSD: Double
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
