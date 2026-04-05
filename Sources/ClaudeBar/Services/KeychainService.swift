import Foundation
import Security

// Stores and retrieves API keys in the macOS Keychain.
// Keys are stored under a service name + the account's UUID,
// so each account has its own isolated Keychain entry.
struct KeychainService {

    private static let service = "com.claudebar.ClaudeBar"

    // Save (or overwrite) an API key for the given account ID.
    static func save(_ key: String, for accountId: UUID) throws {
        let data = Data(key.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: accountId.uuidString,
            kSecValueData:   data
        ]
        // Delete any existing entry first, then add the new one.
        // (SecItemUpdate is more complex; delete+add is simpler and reliable.)
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    // Retrieve an API key. Throws KeychainError.notFound if none is stored.
    static func retrieve(for accountId: UUID) throws -> String {
        let query: [CFString: Any] = [
            kSecClass:        kSecClassGenericPassword,
            kSecAttrService:  service,
            kSecAttrAccount:  accountId.uuidString,
            kSecReturnData:   true,
            kSecMatchLimit:   kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.notFound
        }
        return key
    }

    // Delete the stored key when an account is removed.
    static func delete(for accountId: UUID) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: accountId.uuidString
        ]
        SecItemDelete(query as CFDictionary)
    }

    // Check whether a key exists for an account (without reading the value).
    static func exists(for accountId: UUID) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: accountId.uuidString,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }
}

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case notFound

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status): return "Failed to save to Keychain (OSStatus \(status))"
        case .notFound:               return "No API key found in Keychain for this account"
        }
    }
}
