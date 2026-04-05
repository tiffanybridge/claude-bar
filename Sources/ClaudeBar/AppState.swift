import Foundation
import SwiftUI

// AppState is the single source of truth for the whole app.
// It holds the list of accounts, their current usage data, and controls refreshes.
// @MainActor ensures all updates happen on the main thread (required for UI updates).
@MainActor
class AppState: ObservableObject {

    @Published var usageByAccount: [UUID: AccountUsage] = [:]
    @Published var isRefreshing: Bool = false
    @Published var lastRefreshed: Date? = nil
    @Published var showSettings: Bool = false

    let accountStore: AccountStore
    private let refreshService = RefreshService()

    // Data sources (one per account type)
    private let localSource   = LocalFileDataSource()
    private let apiSource     = AnthropicAPIDataSource()
    private let enterpriseSource = EnterpriseAPIDataSource()

    init(accountStore: AccountStore) {
        self.accountStore = accountStore

        // Wire the refresh service to call fetchAll() on every tick
        refreshService.onRefresh = { [weak self] in
            await self?.fetchAll()
        }
        refreshService.start()
    }

    // MARK: - Text shown in the status bar icon

    // Returns a short string summarizing the most important number.
    // Shows tokens for local accounts, cost for API accounts.
    var statusBarText: String {
        guard !accountStore.accounts.isEmpty else { return "Claude" }

        // Sum up local token usage across all claudeCode accounts
        var totalTokens = TokenUsage()
        for account in accountStore.accounts where account.type == .claudeCode {
            if case .localFile(let usage) = usageByAccount[account.id] {
                totalTokens += usage.last5Hours
            }
        }

        if totalTokens.total > 0 {
            return "Claude  \(totalTokens.formattedTotal)"
        }

        // Fall back to total API cost if no local tokens yet
        var totalCost = 0.0
        for account in accountStore.accounts {
            switch usageByAccount[account.id] {
            case .apiUsage(let u):     totalCost += u.estimatedCostUSD
            case .enterprise(let u):   totalCost += u.totalSpendUSD
            case .localFile(let u):    totalCost += u.estimatedCostUSD
            default: break
            }
        }
        if totalCost > 0 {
            return "Claude  \(TokenCostEstimator.formatUSD(totalCost))"
        }

        return "Claude"
    }

    // MARK: - Fetching

    // Fetches usage data for all configured accounts concurrently.
    func fetchAll() async {
        guard !accountStore.accounts.isEmpty else { return }

        isRefreshing = true
        defer {
            isRefreshing = false
            lastRefreshed = .now
        }

        // Start all fetches concurrently using a task group
        await withTaskGroup(of: (UUID, AccountUsage).self) { group in
            for account in accountStore.accounts {
                let accountCopy = account
                group.addTask {
                    let result = await self.fetchUsage(for: accountCopy)
                    return (accountCopy.id, result)
                }
            }
            for await (id, usage) in group {
                usageByAccount[id] = usage
            }
        }
    }

    // Fetches usage for a single account.
    // Returns .error(...) instead of throwing, so one failing account
    // doesn't break the others.
    func fetchUsage(for account: Account) async -> AccountUsage {
        do {
            switch account.type {
            case .claudeCode:
                let usage = try await localSource.fetch(account: account)
                return .localFile(usage)
            case .anthropicAPI:
                let usage = try await apiSource.fetch(account: account)
                return .apiUsage(usage)
            case .enterprise:
                let usage = try await enterpriseSource.fetch(account: account)
                return .enterprise(usage)
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }

    // Called when an account is first added, so the UI shows data immediately.
    func fetchSingle(_ account: Account) async {
        usageByAccount[account.id] = .loading
        let result = await fetchUsage(for: account)
        usageByAccount[account.id] = result
    }
}
