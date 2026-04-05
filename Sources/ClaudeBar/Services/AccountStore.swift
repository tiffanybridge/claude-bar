import Foundation

// Persists the list of configured accounts to UserDefaults.
// The Account structs contain no secrets — only UUIDs that map to Keychain entries.
class AccountStore: ObservableObject {

    @Published var accounts: [Account] = [] {
        didSet { save() }
    }

    private let userDefaultsKey = "com.claudebar.accounts"

    init() {
        load()
    }

    func add(_ account: Account) {
        accounts.append(account)
    }

    // Removes an account and also deletes its API key from the Keychain.
    func remove(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        KeychainService.delete(for: account.id)
    }

    func update(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([Account].self, from: data)
        else { return }
        accounts = decoded
    }
}
