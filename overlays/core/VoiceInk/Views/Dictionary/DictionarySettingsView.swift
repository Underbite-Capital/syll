import SwiftData
import SwiftUI

struct DictionarySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(PersonalDictionaryService.isCorrectionsEnabledKey)
    private var isCorrectionsEnabled = true
    @AppStorage(PersonalDictionaryService.isRecognitionBoostingEnabledKey)
    private var isRecognitionBoostingEnabled = false
    @State private var isShowingSettings = false

    private let dictionaryInfoMessage: LocalizedStringKey =
        "One personal dictionary now drives exact spellings, spoken aliases, cleanup protection, and optional local Parakeet recognition boosting."

    var body: some View {
        VStack(spacing: 0) {
            AppScreenHeader(title: "Personal Dictionary", infoMessage: dictionaryInfoMessage) {
                settingsButton
            }

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 18) {
                    behaviorSection
                    DictionaryGroupedSection {
                        WordReplacementView()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 640, minHeight: 520)
        .onAppear {
            PersonalDictionaryService.migrateLegacyVocabulary(context: modelContext)
        }
        .sidePanel(isPresented: $isShowingSettings) {
            DictionarySettingsPanel {
                isShowingSettings = false
            }
        }
    }

    private var settingsButton: some View {
        AppIconButton(
            systemName: "gearshape.fill",
            help: "Dictionary Settings"
        ) {
            isShowingSettings.toggle()
        }
    }

    private var behaviorSection: some View {
        DictionaryGroupedSection {
            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $isCorrectionsEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Correct spellings after transcription")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Replace spoken aliases and recurring mistakes with the preferred spelling in one non-cascading pass.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)

                Divider()

                Toggle(isOn: $isRecognitionBoostingEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Improve local Parakeet recognition")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Use acoustic vocabulary boosting before correction. The first use downloads an additional local model; failures always fall back to normal transcription.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)

                if isRecognitionBoostingEnabled {
                    Label(
                        "Boosting is intentionally limited to supported local FluidAudio batch paths. Streaming and other providers keep their ordinary behaviour.",
                        systemImage: "info.circle"
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct DictionaryGroupedSection<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.Surface.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.Border.control.opacity(0.16), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
