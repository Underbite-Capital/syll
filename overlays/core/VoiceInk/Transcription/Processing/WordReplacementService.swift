import Foundation
import SwiftData

class WordReplacementService {
    static let shared = WordReplacementService()

    private init() {}

    func applyReplacements(to text: String, using context: ModelContext) -> String {
        let isEnabled = UserDefaults.standard.object(
            forKey: PersonalDictionaryService.isCorrectionsEnabledKey
        ) as? Bool ?? true

        let correctedText: String
        if isEnabled {
            let entries = PersonalDictionaryService.entries(from: context)
            correctedText = PersonalDictionaryCorrector.correct(text, entries: entries)
        } else {
            correctedText = text
        }

        // Syll's normal cleanup is local and deterministic. Optional VoiceInk AI
        // enhancement remains a separate downstream feature and is not required
        // for cleanup quality.
        return DeterministicDictationCleaner.clean(correctedText)
    }
}
