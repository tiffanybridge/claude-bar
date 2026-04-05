import SwiftUI

// A two-step sheet for adding a new account.
// Step 1: choose the account type.
// Step 2: fill in the details (name, API key, etc.).
struct AddAccountView: View {
    var onSave: (Account) -> Void

    @Environment(\.dismiss) private var dismiss

    // Step tracking: nil = type picker, non-nil = detail form for chosen type
    @State private var selectedType: AccountType? = nil

    // Shared form fields
    @State private var name: String = ""
    @State private var apiKey: String = ""
    @State private var customPath: String = ""
    @State private var saveError: String? = nil

    var body: some View {
        NavigationStack {
            if let type = selectedType {
                detailForm(for: type)
                    .navigationTitle("Add \(type.displayName)")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Back") { selectedType = nil }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") { save(type: type) }
                                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
            } else {
                typePicker
                    .navigationTitle("Add Account")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }
                        }
                    }
            }
        }
        .frame(minWidth: 380, minHeight: 260)
    }

    // MARK: - Step 1: Type picker

    private var typePicker: some View {
        List {
            ForEach(AccountType.allCases, id: \.self) { type in
                Button {
                    // Pre-fill the name with a sensible default
                    name = type.displayName
                    selectedType = type
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: type.systemImage)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.displayName)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            Text(typeDescription(type))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Step 2: Detail form

    @ViewBuilder
    private func detailForm(for type: AccountType) -> some View {
        Form {
            Section("Account details") {
                TextField("Name", text: $name, prompt: Text("e.g. My Personal Account"))
            }

            switch type {
            case .claudeCode:
                Section {
                    TextField(
                        "Custom path (optional)",
                        text: $customPath,
                        prompt: Text("~/.claude/projects")
                    )
                } header: {
                    Text("Claude projects folder")
                } footer: {
                    Text("Leave blank to use the default ~/.claude/projects location.")
                        .font(.caption)
                }

            case .anthropicAPI:
                Section {
                    SecureField("Admin API key", text: $apiKey, prompt: Text("sk-ant-admin..."))
                } header: {
                    Text("Anthropic Admin API key")
                } footer: {
                    Text("Create an Admin API key at console.anthropic.com/settings/admin-keys.")
                        .font(.caption)
                }

            case .enterprise:
                Section {
                    SecureField("Admin API key", text: $apiKey, prompt: Text("sk-ant-admin..."))
                } header: {
                    Text("Enterprise Admin API key")
                } footer: {
                    Text("Must be a Primary Owner or Admin of your Enterprise org.")
                        .font(.caption)
                }
            }

            if let error = saveError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Save logic

    private func save(type: AccountType) {
        saveError = nil
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let path = customPath.trimmingCharacters(in: .whitespaces)

        let account = Account(
            name: trimmedName,
            type: type,
            customPath: path.isEmpty ? nil : path
        )

        // Save the API key to Keychain before handing off the account
        if type != .claudeCode {
            let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
            guard !trimmedKey.isEmpty else {
                saveError = "Please enter an API key."
                return
            }
            do {
                try KeychainService.save(trimmedKey, for: account.id)
            } catch {
                saveError = error.localizedDescription
                return
            }
        }

        onSave(account)
        dismiss()
    }

    // MARK: - Helpers

    private func typeDescription(_ type: AccountType) -> String {
        switch type {
        case .claudeCode:
            return "Reads ~/.claude/ usage logs. No API key needed."
        case .anthropicAPI:
            return "Tracks API token costs. Requires an Admin API key."
        case .enterprise:
            return "Tracks spending vs. limits. Requires an Enterprise Admin key."
        }
    }
}
