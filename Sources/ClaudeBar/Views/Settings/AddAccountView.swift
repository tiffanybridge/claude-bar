import SwiftUI

// A two-step sheet for adding a new account.
// Step 1: choose the account type.
// Step 2: fill in the details.
struct AddAccountView: View {
    var onSave: (Account) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: AccountType? = nil
    @State private var name: String = ""
    @State private var apiKey: String = ""
    @State private var monthlyBudget: String = ""
    @State private var costMultiplier: String = "1.0"
    @State private var selectedSlugs: Set<String> = Set(ProjectDiscovery.allSlugs())
    @State private var filterProjects: Bool = false
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
        .frame(minWidth: 420, minHeight: 300)
    }

    // MARK: - Step 1: Type picker

    private var typePicker: some View {
        List {
            ForEach(AccountType.allCases, id: \.self) { type in
                Button {
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
            Section("Account name") {
                TextField("Name", text: $name, prompt: Text("e.g. Work, Personal"))
            }

            switch type {
            case .claudeCode:
                // Monthly budget — optional, intended for Enterprise-billed usage
                Section {
                    HStack {
                        Text("$").foregroundStyle(.secondary)
                        TextField("Amount", text: $monthlyBudget, prompt: Text("e.g. 200"))
                    }
                } header: {
                    Text("Monthly spend limit (optional)")
                } footer: {
                    Text("Set this if your Claude Code usage is billed to an Enterprise account with a monthly allowance. Leave blank for flat-rate Pro accounts.")
                        .font(.caption)
                }

                // Pricing adjustment multiplier
                Section {
                    TextField("Multiplier", text: $costMultiplier, prompt: Text("1.0"))
                } header: {
                    Text("Pricing adjustment (optional)")
                } footer: {
                    Text("Leave at 1.0 to use retail pricing. If your actual spend is lower (e.g. Enterprise discount), enter a ratio. Example: if ClaudeBar estimates $58 but you actually spent $34, enter 0.59.")
                        .font(.caption)
                }

                // Project selection
                Section {
                    Toggle("Limit to specific projects", isOn: $filterProjects)
                    if filterProjects {
                        ProjectPickerView(selectedSlugs: $selectedSlugs)
                    }
                } header: {
                    Text("Projects")
                } footer: {
                    if filterProjects {
                        Text("Only sessions from selected projects will count toward this account. Use this to separate work and personal usage.")
                            .font(.caption)
                    } else {
                        Text("All local Claude Code sessions will be included.")
                            .font(.caption)
                    }
                }

            case .anthropicAPI:
                Section {
                    SecureField("Admin API key", text: $apiKey, prompt: Text("sk-ant-admin..."))
                } header: {
                    Text("Anthropic Admin API key")
                } footer: {
                    Text("Requires an Admin API key, not a standard API key. Create one at console.anthropic.com/settings/admin-keys. Admin keys are only available if your account has an Organization set up.")
                        .font(.caption)
                }

            case .enterprise:
                Section {
                    SecureField("Admin API key", text: $apiKey, prompt: Text("sk-ant-admin..."))
                } header: {
                    Text("Enterprise Admin API key")
                } footer: {
                    Text("Requires Primary Owner or Admin role in your Enterprise org.")
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

    // MARK: - Save

    private func save(type: AccountType) {
        saveError = nil
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let budget = Double(monthlyBudget.trimmingCharacters(in: .whitespaces))
        let multiplier = Double(costMultiplier.trimmingCharacters(in: .whitespaces)) ?? 1.0
        let slugs: [String]? = (type == .claudeCode && filterProjects)
            ? Array(selectedSlugs)
            : nil

        let account = Account(
            name: trimmedName,
            type: type,
            includedProjectSlugs: slugs,
            monthlyBudgetUSD: (type == .claudeCode) ? budget : nil,
            costMultiplier: (type == .claudeCode) ? max(0.01, multiplier) : 1.0
        )

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
            return "Reads local ~/.claude/ logs. Choose specific projects to separate work and personal."
        case .anthropicAPI:
            return "Shows last 7 days of token usage and estimated cost. Requires an Admin API key."
        case .enterprise:
            return "Tracks org spend vs. limits. Requires org Owner or Admin access."
        }
    }
}
