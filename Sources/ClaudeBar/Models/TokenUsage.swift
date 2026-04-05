import Foundation

// Represents token counts for a given time period or context.
// Claude charges for input, output, and two flavors of cache tokens.
struct TokenUsage {
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var cacheCreationTokens: Int = 0  // tokens written into the cache
    var cacheReadTokens: Int = 0      // tokens read from the cache (cheaper)

    // The two totals you care about most
    var total: Int { inputTokens + outputTokens }
    var totalWithCache: Int { total + cacheCreationTokens + cacheReadTokens }

    // Combine two TokenUsage values
    static func + (lhs: TokenUsage, rhs: TokenUsage) -> TokenUsage {
        TokenUsage(
            inputTokens:          lhs.inputTokens          + rhs.inputTokens,
            outputTokens:         lhs.outputTokens          + rhs.outputTokens,
            cacheCreationTokens:  lhs.cacheCreationTokens   + rhs.cacheCreationTokens,
            cacheReadTokens:      lhs.cacheReadTokens       + rhs.cacheReadTokens
        )
    }

    static func += (lhs: inout TokenUsage, rhs: TokenUsage) {
        lhs = lhs + rhs
    }

    // Format total tokens as a short string, e.g. "12.4k" or "1.2M"
    var formattedTotal: String {
        let n = totalWithCache
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000     { return String(format: "%.1fk", Double(n) / 1_000) }
        return "\(n)"
    }
}
