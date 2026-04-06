import Foundation

// Fetches usage data from the Anthropic Usage API.
// Requires an Admin API key (starts with "sk-ant-admin...").
// Create one at: console.anthropic.com/settings/admin-keys
// Note: Admin keys are only available for accounts with an Organization set up.
struct AnthropicAPIDataSource {

    private let baseURL = "https://api.anthropic.com"

    func fetch(account: Account) async throws -> APIUsage {
        let adminKey = try KeychainService.retrieve(for: account.id)

        let now = Date()
        let sevenDaysAgo = now.addingTimeInterval(-7 * 24 * 3600)

        var components = URLComponents(string: "\(baseURL)/v1/organizations/usage_report/messages")!
        components.queryItems = [
            URLQueryItem(name: "starting_at",  value: iso8601Formatter.string(from: sevenDaysAgo)),
            URLQueryItem(name: "ending_at",    value: iso8601Formatter.string(from: now)),
            URLQueryItem(name: "bucket_width", value: "1d")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")
        request.setValue(adminKey,            forHTTPHeaderField: "x-api-key")
        request.setValue("application/json",  forHTTPHeaderField: "accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw APIError.httpError(http.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(UsageReportResponse.self, from: data)
        return aggregate(decoded, accountId: account.id, refreshedAt: now)
    }

    // MARK: - Private helpers

    private func aggregate(_ response: UsageReportResponse, accountId: UUID, refreshedAt: Date) -> APIUsage {
        var totals = TokenUsage()

        // The API returns daily buckets; each bucket has a `results` array.
        // Without group_by, each bucket has exactly one result entry.
        for bucket in response.data {
            for entry in bucket.results {
                totals += TokenUsage(
                    inputTokens:         entry.uncached_input_tokens,
                    outputTokens:        entry.output_tokens,
                    cacheCreationTokens: 0,  // not exposed at summary level
                    cacheReadTokens:     entry.cache_read_input_tokens ?? 0
                )
            }
        }

        let cost = TokenCostEstimator.estimate(totals, model: "default")
        return APIUsage(
            accountId: accountId,
            last7Days: totals,
            estimatedCostUSD: cost,
            refreshedAt: refreshedAt
        )
    }
}

// MARK: - Response shapes

// The usage report API returns daily buckets, each containing a results array.
private struct UsageReportResponse: Decodable {
    let data: [DailyBucket]

    struct DailyBucket: Decodable {
        let starting_at: String
        let results: [ResultEntry]
    }

    struct ResultEntry: Decodable {
        let uncached_input_tokens: Int
        let output_tokens: Int
        let cache_read_input_tokens: Int?
    }
}

enum APIError: Error, LocalizedError {
    case unexpectedResponse
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .unexpectedResponse:
            return "Received unexpected response from Anthropic API"
        case .httpError(let code, let body):
            return "API error \(code): \(body)"
        }
    }
}
