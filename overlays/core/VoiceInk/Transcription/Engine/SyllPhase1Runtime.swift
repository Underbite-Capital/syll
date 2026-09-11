import Foundation

/// Frozen Phase 1 runtime: one local model, deterministic cleanup, paste output.
/// ModeConfig is retained only as an internal compatibility value for the upstream pipeline.
@MainActor
enum SyllPhase1Runtime {
    static let modelName = "parakeet-tdt-0.6b-v3"

    private static let compatibilityMode = ModeConfig(
        name: "Syll Phase 1",
        isAIEnhancementEnabled: false,
        selectedTranscriptionModelName: modelName,
        isRealtimeTranscriptionEnabled: false,
        selectedLanguage: "en",
        useClipboardContext: false,
        useSelectedTextContext: false,
        useScreenCapture: false,
        isTextFormattingEnabled: true,
        outputMode: .paste,
        autoSendKey: .none,
        isEnabled: false
    )

    static func transcriptionConfiguration(
        manager: TranscriptionModelManager
    ) -> TranscriptionRuntimeConfiguration? {
        guard let model = manager.allAvailableModels.first(where: {
            $0.name == modelName && $0.provider == .fluidAudio
        }), manager.usableModels.contains(where: {
            $0.name == modelName && $0.provider == .fluidAudio
        }) else { return nil }

        return TranscriptionRuntimeConfiguration(
            mode: compatibilityMode,
            model: model,
            language: TranscriptionLanguageSupport.validLanguageOrFallback(
                "en", for: model, realtimeEnabled: false),
            isRealtimeEnabled: false
        )
    }

    static let formatting = TranscriptionFormattingConfiguration(
        mode: nil,
        isTextFormattingEnabled: true
    )

    static let output = OutputRuntimeConfiguration(
        mode: nil,
        outputMode: .paste,
        autoSendKey: .none,
        customCommand: nil
    )
}
