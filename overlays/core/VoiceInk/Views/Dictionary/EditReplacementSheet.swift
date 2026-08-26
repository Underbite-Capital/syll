import SwiftData
import SwiftUI

struct EditReplacementSheet: View {
    let replacement: WordReplacement
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss
    @State private var preferredText: String
    @State private var aliasesText: String
    @State private var showAlert = false
    @State private var alertMessage = ""

    init(replacement: WordReplacement, modelContext: ModelContext) {
        self.replacement = replacement
        self.modelContext = modelContext
        _preferredText = State(initialValue: replacement.replacementText)
        _aliasesText = State(
            initialValue: PersonalDictionaryService.aliasesText(for: replacement)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            form
        }
        .frame(width: 520, height: 430)
        .alert("Personal Dictionary", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var header: some View {
        HStack {
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.escape, modifiers: [])

            Spacer()

            Text("Edit Dictionary Term")
                .font(.headline)

            Spacer()

            Button("Save", action: saveChanges)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(preferredText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: [])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Preferred spelling")
                    .font(.system(size: 13, weight: .semibold))
                TextField("Underbite", text: $preferredText)
                    .textFieldStyle(.roundedBorder)
                Text("This exact form is used in the final transcript and supplied to cleanup as the spelling authority.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Spoken aliases and recurring mistakes")
                    .font(.system(size: 13, weight: .semibold))
                TextEditor(text: $aliasesText)
                    .font(.body)
                    .frame(minHeight: 135)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppTheme.Border.control, lineWidth: 1)
                    )
                Text("Enter one alias per line, or separate them with commas.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
    }

    private func saveChanges() {
        let aliases = PersonalDictionaryService.parseAliases(aliasesText)
        if let error = PersonalDictionaryService.saveTerm(
            preferredText: preferredText,
            aliases: aliases,
            replacing: replacement,
            context: modelContext
        ) {
            alertMessage = error
            showAlert = true
            return
        }
        dismiss()
    }
}
