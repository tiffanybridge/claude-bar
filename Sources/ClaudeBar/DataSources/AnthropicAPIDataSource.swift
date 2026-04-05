import Foundation

// Fetches usage data from the Anthropic Usage & Cost API.
// Requires an Admin API key (starts with "sk-ant-admin...").
// You can create one at: https://console.anthropic.com/settings/admin-keys
struct AnthropicAPIDataSource {

    private let baseURL = "https://api.anthropic.com"

    func fetch(account: Account) async throws -> APIUsage {
        let adminKey = try KeychainService.retrieve(for: account.id)

        // Build the request for the current calendar month
        let (startTime, endTime) = currentMonthRange()
        var components = URLComponents(string: "\(baseURL)/v1/organizations/usage_report/messages")!
        components.queryItems = [
            URLQueryItem(name: "start_time", value: iso8601Formatter.string(from: startTime)),
            URLQueryItem(name: "end_time",   value: iso8601Formatter.string(from: endTime)),
            URLQueryItem(name: "time_bucket", value: "1d")  // one data point per day
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(adminKey,     forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw APIError.httpError(http.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(UsageReportResponse.self, from: data)
        return aggregate(decoded, accountId: account.id)
    }

    // MARK: - Private helpers

    private func aggregate(_ response: UsageReportResponse, accountId: UUID) -> APIUsage {
        var totals = TokenUsage()
        var breakdown: [String: TokenUsage] = [:]

        for entry in response.data {
            let usage = TokenUsage(
                inputTokens:         entry.input_tokens,
                outputTokens:        entry.output_tokens,
                cacheCreationTokens: entry.cache_creation_input_tokens ?? 0,
                cacheReadTokens:     entry.cache_read_input_tokens ?? 0
            )
            totals += usage
            let model = entry.model ?? "unknown"
            breakdown[model, default: TokenUsage()] += usage
        }

        let cost = TokenCostEstimator.estimateTotal(breakdown)
        return APIUsage(
            accountId: accountId,
            thisMonthTokens: totals,
            estimatedCostUSD: cost,
            modelBreakdown: breakdown,
            refreshedAt: .now
        )
    }

    private func currentMonthRange() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        return (startOfMonth, min(startOfNextMonth, now))
    }
}

// MARK: - Response shapes

// The Anthropic usage report API returns a list of daily usage entries.
private struct UsageReportResponse: Decodable {
    let data: [UsageEntry]

    struct UsageEntry: Decodable {
        let model: String?
        let input_tokens: Int
        let output_tokens: Int
        let cache_creation_input_tokens: Int?
        let cache_read_input_tokens: Int?
    }
}

enum APIError: Error, LocalizedError {
    case unexpectedResponse
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .unexpectedResponse:       return "Received unexpected response from Anthropic API"
        case .httpError(let code, let body): return "API error \(code): \(body)"
        }
    }
}
