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
    // Example: "/Users/you/dev" counts only projects in ~/dev/
    // Leave nil to count all local Claude Code sessions.
    var pathFilter: String?

    init(name: String, type: AccountType, pathFilter: String? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.pathFilter = pathFilter
    }
}
