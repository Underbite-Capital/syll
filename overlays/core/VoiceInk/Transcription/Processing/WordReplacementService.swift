import Foundation
import SwiftData

class WordReplacementService {
    static let shared = WordReplacementService()

    private init() {}

    func applyReplacements(to text: String, using context: ModelContext) -> String {
        let isEnabled = UserDefaults.standard.object(
            forKey: PersonalDictionaryService.isCorrectionsEnabledKey
        ) as? Bool ?? true

        // Normalize generic dictation before resolving user-authoritative spellings.
        // Correction is last so sentence casing cannot rewrite a preferred term.
        let cleanedText = DeterministicDictationCleaner.clean(text)
        if isEnabled {
            let entries = PersonalDictionaryService.entries(from: context)
            return PersonalDictionaryCorrector.correct(cleanedText, entries: entries)
        }
        return cleanedText
    }
}
