import Foundation

enum AccountType: String, Codable, CaseIterable {
    case claudeCode = "claude_code"
    case anthropicAPI = "anthropic_api"
    case enterprise = "enterprise"

    var displayName: String {
        switch self {
        case .claudeCode:   return "Claude Code"
        case .anthropicAPI: return "Anthropic Console"
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

struct Account: Identifiable, Equatable {
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

    // claudeCode only: multiplier applied to the retail-price cost estimate.
    // Default 1.0 = use retail pricing as-is.
    // Set to < 1.0 if your Enterprise discount makes actual spend lower than estimated
    // (e.g. 0.59 if ClaudeBar estimates $58 but your actual bill is $34).
    var costMultiplier: Double

    init(name: String, type: AccountType,
         includedProjectSlugs: [String]? = nil,
         monthlyBudgetUSD: Double? = nil,
         costMultiplier: Double = 1.0) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.includedProjectSlugs = includedProjectSlugs
        self.monthlyBudgetUSD = monthlyBudgetUSD
        self.costMultiplier = costMultiplier
    }
}

// Custom Codable so existing stored accounts (which lack costMultiplier) decode
// without error — missing key falls back to 1.0.
extension Account: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, type, includedProjectSlugs, monthlyBudgetUSD, costMultiplier
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                   = try c.decode(UUID.self,        forKey: .id)
        name                 = try c.decode(String.self,      forKey: .name)
        type                 = try c.decode(AccountType.self, forKey: .type)
        includedProjectSlugs = try c.decodeIfPresent([String].self,  forKey: .includedProjectSlugs)
        monthlyBudgetUSD     = try c.decodeIfPresent(Double.self,    forKey: .monthlyBudgetUSD)
        costMultiplier       = try c.decodeIfPresent(Double.self,    forKey: .costMultiplier) ?? 1.0
    }
}
