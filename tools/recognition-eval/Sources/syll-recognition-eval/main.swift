import FluidAudio
import Foundation

private struct DictionaryEntry: Codable {
    let preferredText: String
    let aliases: [String]
}

private struct EvaluationRow: Encodable {
    let sourceRevision: String
    let fluidAudioRevision: String
    let audioPath: String
    let strategy: String
    let model: String
    let vocabularySupplied: Bool
    let audioDurationSeconds: Double
    let inferenceLatencySeconds: Double
    let realtimeFactor: Double
    let speedupFactor: Double
    let rawTranscript: String
    let strategyTranscript: String
    let ctcAppliedTerms: [String]
    let normalizedTranscript: String
    let cleanupAndDictionaryText: String
}

@main
private enum RecognitionEvaluation {
    static func main() async throws {
        let args = Array(CommandLine.arguments.dropFirst())
        guard args.count >= 2, args[0] == "--audio" else {
            fputs("Usage: syll-recognition-eval --audio FILE [--dictionary JSON] [--trailing-silence-ms 0|250|500 | --no-language-hint | --ctc-rescore]\n", stderr)
            exit(2)
        }
        let audioURL = URL(fileURLWithPath: args[1]).standardizedFileURL
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            fputs("Audio file does not exist: \(audioURL.path)\n", stderr)
            exit(2)
        }
        func option(_ name: String) -> String? {
            guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        let trailingMs = Int(option("--trailing-silence-ms") ?? "0") ?? -1
        guard [0, 250, 500].contains(trailingMs) else {
            fputs("Trailing silence must be 0, 250, or 500 ms\n", stderr)
            exit(2)
        }
        let useCTC = args.contains("--ctc-rescore")
        let noLanguageHint = args.contains("--no-language-hint")
        guard [useCTC, noLanguageHint, trailingMs > 0].filter({ $0 }).count <= 1 else {
            fputs("Select one experimental strategy at a time\n", stderr)
            exit(2)
        }
        let dictionary: [DictionaryEntry]
        if let path = option("--dictionary") {
            dictionary = try JSONDecoder().decode([DictionaryEntry].self, from: Data(contentsOf: URL(fileURLWithPath: path)))
        } else {
            dictionary = []
        }
        guard dictionary.count <= 100 else {
            fputs("Evaluation vocabulary is capped at 100 preferred terms\n", stderr)
            exit(2)
        }
        guard !useCTC || !dictionary.isEmpty else {
            fputs("CTC rescoring requires --dictionary\n", stderr)
            exit(2)
        }
        if useCTC {
            let directory = CtcModels.defaultCacheDirectory(for: .ctc110m)
            guard CtcModels.modelsExist(at: directory) else {
                fputs("CTC 110M model is not locally installed at \(directory.path); no download attempted\n", stderr)
                exit(3)
            }
        }

        // Match Syll's effective core path: int8 Parakeet v3, ASRConfig.default,
        // fresh TDT decoder state, and its English script hint. Load before timing
        // so the latency is release-to-text inference rather than model startup.
        let models = try await AsrModels.load(
            from: AsrModels.defaultCacheDirectory(for: .v3),
            configuration: nil,
            version: .v3,
            encoderPrecision: .int8
        )
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        let languageHint: Language? = noLanguageHint ? nil : .english
        var ctcConfiguration: (vocab: CustomVocabularyContext, spotter: CtcKeywordSpotter,
                               rescorer: VocabularyRescorer)?
        if useCTC {
            let directory = CtcModels.defaultCacheDirectory(for: .ctc110m)
            let ctcModels = try await CtcModels.load(from: directory)
            let tokenizer = try await CtcTokenizer.load(from: directory)
            let terms = dictionary.compactMap { entry -> CustomVocabularyTerm? in
                let ids = tokenizer.encode(entry.preferredText)
                guard !ids.isEmpty else { return nil }
                return CustomVocabularyTerm(text: entry.preferredText, aliases: entry.aliases, ctcTokenIds: ids)
            }
            let vocab = CustomVocabularyContext(terms: terms)
            let spotter = CtcKeywordSpotter(models: ctcModels, blankId: ctcModels.vocabulary.count)
            let rescorer = try await VocabularyRescorer.create(
                spotter: spotter, vocabulary: vocab, ctcModelDirectory: directory
            )
            ctcConfiguration = (vocab, spotter, rescorer)
        }
        var decoderState = TdtDecoderState.make(decoderLayers: await manager.decoderLayerCount)
        let start = ProcessInfo.processInfo.systemUptime
        let result: ASRResult
        let audioDuration: Double
        if trailingMs == 0 {
            // This is Syll's exact file-based transcribe call.
            result = try await manager.transcribe(audioURL, decoderState: &decoderState, language: languageHint)
            audioDuration = result.duration
        } else {
            // Controlled preprocessing experiment; not the shipping path.
            let converter = AudioConverter()
            let samples = try converter.resampleAudioFile(audioURL)
            audioDuration = Double(samples.count) / 16_000
            let padded = samples + [Float](repeating: 0, count: trailingMs * 16)
            result = try await manager.transcribe(padded, decoderState: &decoderState, language: languageHint)
        }
        var strategyText = result.text
        var appliedTerms: [String] = []
        if let ctcConfiguration {
            let converter = AudioConverter()
            let samples = try converter.resampleAudioFile(audioURL)
            let spotted = try await ctcConfiguration.spotter.spotKeywordsWithLogProbs(
                audioSamples: samples, customVocabulary: ctcConfiguration.vocab
            )
            let config = ContextBiasingConstants.rescorerConfig(forVocabSize: dictionary.count)
            let rescored = ctcConfiguration.rescorer.ctcTokenRescore(
                transcript: result.text,
                tokenTimings: result.tokenTimings ?? [],
                logProbs: spotted.logProbs,
                frameDuration: spotted.frameDuration,
                cbw: config.cbw,
                minSimilarity: max(config.minSimilarity, ctcConfiguration.vocab.minSimilarity)
            )
            strategyText = rescored.text
            appliedTerms = rescored.replacements.filter(\.shouldReplace).compactMap(\.replacementWord)
        }
        let elapsed = ProcessInfo.processInfo.systemUptime - start
        let normalized = TextNormalizer.shared.normalizeSentence(strategyText)
        let cleaned = DeterministicDictationCleaner.clean(normalized)
        let final = PersonalDictionaryCorrector.correct(
            cleaned,
            entries: dictionary.map { PersonalDictionaryEntry(preferredText: $0.preferredText, aliases: $0.aliases) }
        )
        let row = EvaluationRow(
            sourceRevision: ProcessInfo.processInfo.environment["SYLL_PRODUCT_SOURCE_REVISION"] ?? "unknown",
            fluidAudioRevision: "c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7",
            audioPath: audioURL.path,
            strategy: useCTC ? "tdt-plus-ctc-rescore" : (noLanguageHint ? "no-language-hint" : (trailingMs == 0 ? "syll-core" : "trailing-silence-\(trailingMs)ms")),
            model: "parakeet-tdt-0.6b-v3-int8",
            vocabularySupplied: useCTC,
            audioDurationSeconds: audioDuration,
            inferenceLatencySeconds: elapsed,
            realtimeFactor: elapsed / audioDuration,
            speedupFactor: audioDuration / elapsed,
            rawTranscript: result.text,
            strategyTranscript: strategyText,
            ctcAppliedTerms: appliedTerms,
            normalizedTranscript: normalized,
            cleanupAndDictionaryText: final
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        print(String(data: try encoder.encode(row), encoding: .utf8)!)
    }
}
