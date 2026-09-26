import Foundation

// The evaluation CLI compiles Syll's unchanged cleaner and corrector sources.
// Only their SwiftData-backed entry lookup is replaced by explicit JSON input.
struct PersonalDictionaryEntry {
    let preferredText: String
    let aliases: [String]
}

enum PersonalDictionaryService {
    static func uniqueCaseInsensitive(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for rawValue in values {
            let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { continue }
            let key = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            guard seen.insert(key).inserted else { continue }
            result.append(value)
        }
        return result
    }
}
