import SwiftUI

// Lets the user choose which Claude Code projects to include in an account.
// Shows all detected project directories with toggle switches.
struct ProjectPickerView: View {
    // The set of currently selected slugs. Binding so the parent can read it.
    @Binding var selectedSlugs: Set<String>
    @State private var searchText = ""

    private let allSlugs = ProjectDiscovery.allSlugs()

    private var filteredSlugs: [String] {
        guard !searchText.isEmpty else { return allSlugs }
        return allSlugs.filter {
            ProjectDiscovery.displayName(for: $0)
                .localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Select all / none shortcuts
            HStack {
                Button("Select all") { selectedSlugs = Set(allSlugs) }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Button("Select none") { selectedSlugs = [] }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)

            if allSlugs.isEmpty {
                Text("No Claude Code projects found on this machine.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                List(filteredSlugs, id: \.self) { slug in
                    Toggle(isOn: Binding(
                        get: { selectedSlugs.contains(slug) },
                        set: { on in
                            if on { selectedSlugs.insert(slug) }
                            else  { selectedSlugs.remove(slug) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(ProjectDiscovery.displayName(for: slug))
                                .font(.caption)
                            Text(slug)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Filter projects")
                .frame(minHeight: 160, maxHeight: 260)
            }

            Text("\(selectedSlugs.count) of \(allSlugs.count) projects selected")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 4)
        }
    }
}
