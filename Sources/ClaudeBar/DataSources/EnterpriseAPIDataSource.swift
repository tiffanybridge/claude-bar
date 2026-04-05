import Foundation

// Fetches spending and usage data for Claude Enterprise accounts.
// Requires an Admin API key from an Enterprise org.
//
// NOTE: The exact Enterprise Analytics API endpoint and response shape should be
// verified against Anthropic's docs before using in production:
// https://support.claude.com/en/articles/13703965-claude-enterprise-analytics-api-reference-guide
struct EnterpriseAPIDataSource {

    private let baseURL = "https://api.anthropic.com"

    func fetch(account: Account) async throws -> EnterpriseUsage {
        let adminKey = try KeychainService.retrieve(for: account.id)

        // TODO: Confirm the exact endpoint path with Anthropic's Enterprise docs.
        // The endpoint below is a reasonable guess based on the API pattern;
        // update it once you've verified against your actual Enterprise account.
        var components = URLComponents(string: "\(baseURL)/v1/organizations/spend")!
        let (start, end) = currentBillingPeriod()
        components.queryItems = [
            URLQueryItem(name: "start_time", value: iso8601Formatter.string(from: start)),
            URLQueryItem(name: "end_time",   value: iso8601Formatter.string(from: end))
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

        let decoded = try JSONDecoder().decode(EnterpriseSpendResponse.self, from: data)
        return EnterpriseUsage(
            accountId: account.id,
            totalSpendUSD: decoded.total_spend_usd,
            spendLimitUSD: decoded.spend_limit_usd,
            periodStart: start,
            periodEnd: end,
            refreshedAt: .now
        )
    }

    // MARK: - Private helpers

    // Returns the start and end of the current calendar month as the billing period.
    // Adjust this if your Enterprise billing period differs.
    private func currentBillingPeriod() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let end = calendar.date(byAdding: .month, value: 1, to: start)!
        return (start, min(end, now))
    }
}

// MARK: - Response shape

// TODO: Update this struct to match the actual response from your Enterprise account.
private struct EnterpriseSpendResponse: Decodable {
    let total_spend_usd: Double
    let spend_limit_usd: Double?
}
