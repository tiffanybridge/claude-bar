import Foundation

// The three types of Claude accounts this app can track.
// Each type pulls data from a different source.
enum AccountType: String, Codable, CaseIterable {
    case claudeCode = "claude_code"
    case anthropicAPI = "anthropic_api"
    case enterprise = "enterprise"

    var displayName: String {
        switch self {
        case .claudeCode:   return "Claude Code"
        case .anthropicAPI: return "Anthropic API"
        case .enterprise:   return "Enterprise (Admin)"
        }
    }

    var systemImage: String {
        switch self {
        case .claudeCode:   return "terminal"
        case .anthropicAPI: return "key.horizontal"
        case .enterprise:   return "building.2"
        }
    }
}

// One configured account. Stored in UserDefaults.
// Secrets (API keys) are stored separately in the Keychain, referenced by `id`.
struct Account: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String          // User-chosen label, e.g. "Personal", "Work"
    var type: AccountType

    // Optional path filter for claudeCode accounts.
    // When set, only sessions from projects inside this directory are counted.
    var pathFilter: String?

    // Optional monthly spend limit in USD. When set, the UI shows current
    // estimated spend as a percentage of this budget.
    // Example: $20 for a Claude Pro subscription, or whatever your monthly allowance is.
    var monthlyBudgetUSD: Double?

    init(name: String, type: AccountType, pathFilter: String? = nil, monthlyBudgetUSD: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.pathFilter = pathFilter
        self.monthlyBudgetUSD = monthlyBudgetUSD
    }
}
