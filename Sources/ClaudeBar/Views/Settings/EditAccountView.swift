import SwiftUI

// Sheet for editing an existing account's settings.
// Only Claude Code accounts are editable for now (name, budget, projects, pricing).
struct EditAccountView: View {
    var account: Account
    var onSave: (Account) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var monthlyBudget: String
    @State private var costMultiplier: String
    @State private var filterProjects: Bool
    @State private var selectedSlugs: Set<String>

    init(account: Account, onSave: @escaping (Account) -> Void) {
        self.account = account
        self.onSave = onSave
        _name = State(initialValue: account.name)
        _monthlyBudget = State(initialValue: account.monthlyBudgetUSD.map { String($0) } ?? "")
        _costMultiplier = State(initialValue: String(account.costMultiplier))
        _filterProjects = State(initialValue: account.includedProjectSlugs != nil)
        _selectedSlugs = State(initialValue: Set(account.includedProjectSlugs ?? ProjectDiscovery.allSlugs()))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account name") {
                    TextField("Name", text: $name, prompt: Text("e.g. Work, Personal"))
                }

                if account.type == .claudeCode {
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

                    Section {
                        TextField("Multiplier", text: $costMultiplier, prompt: Text("1.0"))
                    } header: {
                        Text("Pricing adjustment")
                    } footer: {
                        Text("Leave at 1.0 to use retail pricing. If your actual spend is lower (e.g. Enterprise discount), enter a ratio. Example: if ClaudeBar estimates $58 but you actually spent $34, enter 0.59.")
                            .font(.caption)
                    }

                    Section {
                        Toggle("Limit to specific projects", isOn: $filterProjects)
                        if filterProjects {
                            ProjectPickerView(selectedSlugs: $selectedSlugs)
                        }
                    } header: {
                        Text("Projects")
                    } footer: {
                        if filterProjects {
                            Text("Only sessions from selected projects will count toward this account.")
                                .font(.caption)
                        } else {
                            Text("All local Claude Code sessions will be included.")
                                .font(.caption)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit \(account.type.displayName)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 300)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let budget = Double(monthlyBudget.trimmingCharacters(in: .whitespaces))
        let multiplier = max(0.01, Double(costMultiplier.trimmingCharacters(in: .whitespaces)) ?? 1.0)
        let slugs: [String]? = (account.type == .claudeCode && filterProjects)
            ? Array(selectedSlugs)
            : nil

        var updated = account
        updated.name = trimmedName
        updated.monthlyBudgetUSD = (account.type == .claudeCode) ? budget : nil
        updated.costMultiplier = (account.type == .claudeCode) ? multiplier : 1.0
        updated.includedProjectSlugs = slugs

        onSave(updated)
        dismiss()
    }
}
