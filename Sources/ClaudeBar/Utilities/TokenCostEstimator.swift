import Foundation

// Estimates USD cost from token counts based on Anthropic's published pricing.
// Prices are per million tokens. Update this table when Anthropic changes pricing.
// Source: https://www.anthropic.com/pricing
struct TokenCostEstimator {

    // Pricing per million tokens (input / output / cache-write / cache-read)
    private struct ModelPricing {
        let inputPerMillion: Double
        let outputPerMillion: Double
        let cacheWritePerMillion: Double
        let cacheReadPerMillion: Double
    }

    private static let pricing: [String: ModelPricing] = [
        "claude-opus-4-6": ModelPricing(
            inputPerMillion: 15.00,
            outputPerMillion: 75.00,
            cacheWritePerMillion: 18.75,
            cacheReadPerMillion: 1.50
        ),
        "claude-sonnet-4-6": ModelPricing(
            inputPerMillion: 3.00,
            outputPerMillion: 15.00,
            cacheWritePerMillion: 3.75,
            cacheReadPerMillion: 0.30
        ),
        "claude-haiku-4-5": ModelPricing(
            inputPerMillion: 0.80,
            outputPerMillion: 4.00,
            cacheWritePerMillion: 1.00,
            cacheReadPerMillion: 0.08
        ),
        // Fallback for any model not in the table
        "default": ModelPricing(
            inputPerMillion: 3.00,
            outputPerMillion: 15.00,
            cacheWritePerMillion: 3.75,
            cacheReadPerMillion: 0.30
        )
    ]

    // Returns the estimated USD cost for a TokenUsage and a model name.
    static func estimate(_ usage: TokenUsage, model: String) -> Double {
        // Try exact match, then prefix match (e.g. "claude-sonnet-4"), then default
        let p = pricing[model]
            ?? pricing.first(where: { model.hasPrefix($0.key) })?.value
            ?? pricing["default"]!

        let input  = Double(usage.inputTokens)         / 1_000_000 * p.inputPerMillion
        let output = Double(usage.outputTokens)         / 1_000_000 * p.outputPerMillion
        let cWrite = Double(usage.cacheCreationTokens)  / 1_000_000 * p.cacheWritePerMillion
        let cRead  = Double(usage.cacheReadTokens)      / 1_000_000 * p.cacheReadPerMillion

        return input + output + cWrite + cRead
    }

    // Estimates total cost across a model breakdown dictionary
    static func estimateTotal(_ breakdown: [String: TokenUsage]) -> Double {
        breakdown.reduce(0.0) { sum, pair in
            sum + estimate(pair.value, model: pair.key)
        }
    }

    // Format a dollar amount as a short string, e.g. "$0.18" or "$45.20"
    static func formatUSD(_ amount: Double) -> String {
        if amount < 0.01 { return "< $0.01" }
        return String(format: "$%.2f", amount)
    }
}
