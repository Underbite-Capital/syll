import SwiftData
import SwiftUI

struct WordReplacementView: View {
    @Query private var wordReplacements: [WordReplacement]
    @Environment(\.modelContext) private var modelContext

    @State private var preferredText = ""
    @State private var aliasesText = ""
    @State private var searchText = ""
    @State private var editingReplacement: WordReplacement?
    @State private var showAlert = false
    @State private var alertMessage = ""

    private var visibleReplacements: [WordReplacement] {
        let sorted = wordReplacements.sorted {
            $0.replacementText.localizedCaseInsensitiveCompare($1.replacementText) == .orderedAscending
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }

        return sorted.filter { replacement in
            replacement.replacementText.localizedCaseInsensitiveContains(query)
                || replacement.originalText.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            intro
            addForm

            if !wordReplacements.isEmpty {
                Divider()
                searchField
                entriesList
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            PersonalDictionaryService.migrateLegacyVocabulary(context: modelContext)
        }
        .sheet(item: $editingReplacement) { replacement in
            EditReplacementSheet(replacement: replacement, modelContext: modelContext)
        }
        .alert("Personal Dictionary", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Terms and spoken aliases")
                .font(.system(size: 15, weight: .semibold))
            Text("Enter the spelling you want, then the ways VoiceInk commonly hears it. Aliases are optional.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private var addForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Preferred spelling — e.g. Underbite", text: $preferredText)
                    .textFieldStyle(.roundedBorder)

                TextField("Spoken aliases — e.g. under bite, underbyte", text: $aliasesText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addTerm)

                Button(action: addTerm) {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(preferredText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Text("Aliases can be separated with commas. The preferred spelling itself is always protected and boosted.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    private var searchField: some View {
        TextField("Search dictionary", text: $searchText)
            .textFieldStyle(.roundedBorder)
    }

    private var entriesList: some View {
        LazyVStack(spacing: 0) {
            ForEach(visibleReplacements, id: \.persistentModelID) { replacement in
                PersonalDictionaryRow(
                    replacement: replacement,
                    onEnabledChange: { isEnabled in
                        setEnabled(isEnabled, for: replacement)
                    },
                    onEdit: {
                        editingReplacement = replacement
                    },
                    onDelete: {
                        deleteTerm(replacement)
                    }
                )

                if replacement.persistentModelID != visibleReplacements.last?.persistentModelID {
                    Divider()
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No dictionary terms yet",
            systemImage: "character.book.closed",
            description: Text("Add a preferred spelling above. You can attach aliases now or later.")
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func addTerm() {
        let aliases = PersonalDictionaryService.parseAliases(aliasesText)
        if let error = PersonalDictionaryService.saveTerm(
            preferredText: preferredText,
            aliases: aliases,
            context: modelContext
        ) {
            alertMessage = error
            showAlert = true
            return
        }

        preferredText = ""
        aliasesText = ""
    }

    private func setEnabled(_ isEnabled: Bool, for replacement: WordReplacement) {
        do {
            try PersonalDictionaryService.setEnabled(
                isEnabled,
                for: replacement,
                context: modelContext
            )
        } catch {
            alertMessage = String(
                format: String(localized: "Failed to update dictionary term: %@"),
                error.localizedDescription
            )
            showAlert = true
        }
    }

    private func deleteTerm(_ replacement: WordReplacement) {
        do {
            try PersonalDictionaryService.deleteTerm(replacement, context: modelContext)
        } catch {
            alertMessage = String(
                format: String(localized: "Failed to remove dictionary term: %@"),
                error.localizedDescription
            )
            showAlert = true
        }
    }
}

private struct PersonalDictionaryRow: View {
    let replacement: WordReplacement
    let onEnabledChange: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var entry: PersonalDictionaryEntry? {
        PersonalDictionaryService.entry(for: replacement)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Toggle(
                "",
                isOn: Binding(
                    get: { replacement.isEnabled },
                    set: onEnabledChange
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry?.preferredText ?? replacement.replacementText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(replacement.isEnabled ? .primary : .secondary)

                if let aliases = entry?.aliases, !aliases.isEmpty {
                    Text("Heard as: \(aliases.joined(separator: ", "))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    Text("Exact spelling only")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Edit dictionary term")

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Remove dictionary term")
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 2)
    }
}
