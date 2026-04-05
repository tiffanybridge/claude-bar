import Foundation

// The three types of Claude accounts this app can track.
// Each type pulls data from a different source.
enum AccountType: String, Codable, CaseIterable {
    case claudeCode = "claude_code"
    case anthropicAPI = "anthropic_api"
    case enterprise = "enterprise"

    var displayName: String {
        switch self {
        case .claudeCode:   return "Claude Code / Pro"
        case .anthropicAPI: return "Anthropic API"
        case .enterprise:   return "Enterprise"
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
    var name: String          // User-chosen label, e.g. "Personal", "Work API"
    var type: AccountType
    // Only used for claudeCode accounts; nil means use the default path ~/.claude/projects
    var customPath: String?

    init(name: String, type: AccountType, customPath: String? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.customPath = customPath
    }

    // The filesystem path to scan for JSONL usage files
    var claudeProjectsPath: String {
        customPath ?? (NSHomeDirectory() + "/.claude/projects")
    }
}
