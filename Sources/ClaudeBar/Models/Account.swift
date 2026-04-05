import Foundation

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

struct Account: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var type: AccountType

    // claudeCode only: if set, only sessions from these project slugs are counted.
    // nil means include all projects.
    var includedProjectSlugs: [String]?

    // claudeCode only: optional monthly spend limit in USD.
    // Meaningful for Enterprise-billed usage (e.g. $200/month allowance).
    // Leave nil for Pro accounts where flat-rate applies.
    var monthlyBudgetUSD: Double?

    init(name: String, type: AccountType,
         includedProjectSlugs: [String]? = nil,
         monthlyBudgetUSD: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.includedProjectSlugs = includedProjectSlugs
        self.monthlyBudgetUSD = monthlyBudgetUSD
    }
}
