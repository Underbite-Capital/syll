import Foundation
import SwiftData
import SwiftUI

class CustomVocabularyService {
    static let shared = CustomVocabularyService()

    private init() {}

    func getCustomVocabulary(from context: ModelContext) -> String {
        let vocabulary = PersonalDictionaryService.promptVocabulary(from: context)
        guard !vocabulary.isEmpty else { return "" }
        return "Important Vocabulary:\n\(vocabulary)"
    }

    func getPreferredTerms(from context: ModelContext) -> [String] {
        PersonalDictionaryService.preferredTerms(from: context)
    }
}
