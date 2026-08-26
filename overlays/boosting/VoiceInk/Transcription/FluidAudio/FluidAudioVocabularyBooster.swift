import FluidAudio
import Foundation
import os.log

/// Optional, fail-open acoustic vocabulary boosting for supported FluidAudio
/// batch paths. The dictionary UI and deterministic correction remain useful
/// even when this adapter is disabled or cannot prepare its CTC model.
actor FluidAudioVocabularyBooster {
    static let shared = FluidAudioVocabularyBooster()

    private struct VocabularyFile: Encodable {
        let alpha: Float
        let terms: [VocabularyTerm]
    }

    private struct VocabularyTerm: Encodable {
        let text: String
        let weight: Float
        let aliases: [String]?
    }

    private let logger = Logger(
        subsystem: "com.prakashjoshipax.voiceink",
        category: "FluidAudioVocabularyBooster"
    )
    private var cachedConfiguration: Data?
    private var cachedSession: VocabularyBoostingSession?

    private init() {}

    func rescore(
        text: String,
        tokenTimings: [TokenTiming]?,
        audioSamples: [Float]
    ) async -> String {
        guard UserDefaults.standard.bool(
            forKey: PersonalDictionaryService.isRecognitionBoostingEnabledKey
        ) else {
            return text
        }
        guard let tokenTimings, !tokenTimings.isEmpty, !audioSamples.isEmpty else {
            return text
        }

        let entries = PersonalDictionaryService.cachedRecognitionEntries()
        guard !entries.isEmpty else { return text }

        do {
            let session = try await session(for: entries)
            let output = await session.rescore(
                text: text,
                tokenTimings: tokenTimings,
                audioSamples: audioSamples
            )
            return output?.text ?? text
        } catch {
            logger.warning(
                "Vocabulary boosting unavailable; using ordinary transcription: \(error.localizedDescription, privacy: .public)"
            )
            return text
        }
    }

    private func session(
        for entries: [PersonalDictionaryEntry]
    ) async throws -> VocabularyBoostingSession {
        let vocabularyFile = VocabularyFile(
            alpha: 1.0,
            terms: entries.map { entry in
                VocabularyTerm(
                    text: entry.preferredText,
                    weight: 10.0,
                    aliases: entry.aliases.isEmpty ? nil : entry.aliases
                )
            }
        )
        let configuration = try JSONEncoder().encode(vocabularyFile)

        if configuration == cachedConfiguration,
            let cachedSession
        {
            return cachedSession
        }

        let vocabularyURL = try writeVocabulary(configuration)
        let loaded = try await CustomVocabularyContext.loadWithCtcTokens(
            from: vocabularyURL.path
        )
        let prepared = try await VocabularyBoostingSession(
            vocabulary: loaded.vocab,
            ctcModels: loaded.models,
            config: VocabularyBoostingSession.itnDefaultConfig
        )

        cachedConfiguration = configuration
        cachedSession = prepared
        logger.info("Vocabulary boosting prepared with \(entries.count, privacy: .public) terms")
        return prepared
    }

    private func writeVocabulary(_ data: Data) throws -> URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let directory = applicationSupport
            .appendingPathComponent("VoiceInk", isDirectory: true)
            .appendingPathComponent("PersonalDictionary", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let url = directory.appendingPathComponent("fluid-audio-vocabulary.json")
        try data.write(to: url, options: .atomic)
        return url
    }
}
