import Foundation
import SwiftData

class WordReplacementService {
    static let shared = WordReplacementService()

    private init() {}

    func applyReplacements(to text: String, using context: ModelContext) -> String {
        let isEnabled = UserDefaults.standard.object(
            forKey: PersonalDictionaryService.isCorrectionsEnabledKey
        ) as? Bool ?? true
        guard isEnabled else { return text }

        let entries = PersonalDictionaryService.entries(from: context)
        return PersonalDictionaryCorrector.correct(text, entries: entries)
    }
}
