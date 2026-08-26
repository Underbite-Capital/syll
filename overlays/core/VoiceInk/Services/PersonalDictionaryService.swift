import Foundation
import SwiftData

struct PersonalDictionaryEntry: Codable, Hashable, Sendable {
    let preferredText: String
    let aliases: [String]

    var recognitionTerms: [String] {
        PersonalDictionaryService.uniqueCaseInsensitive([preferredText] + aliases)
    }
}

enum PersonalDictionaryService {
    static let isCorrectionsEnabledKey = "PersonalDictionaryCorrectionsEnabled"
    static let isRecognitionBoostingEnabledKey = "PersonalDictionaryRecognitionBoostingEnabled"
    static let recognitionCacheKey = "PersonalDictionaryRecognitionCache.v1"

    static func entries(
        from context: ModelContext,
        enabledOnly: Bool = true
    ) -> [PersonalDictionaryEntry] {
        let descriptor: FetchDescriptor<WordReplacement>
        if enabledOnly {
            descriptor = FetchDescriptor<WordReplacement>(
                predicate: #Predicate { $0.isEnabled }
            )
        } else {
            descriptor = FetchDescriptor<WordReplacement>()
        }

        guard let replacements = try? context.fetch(descriptor) else {
            return []
        }

        var entriesByPreferred: [String: PersonalDictionaryEntry] = [:]
        for replacement in replacements {
            guard let entry = entry(for: replacement) else { continue }
            let key = entry.preferredText.lowercased()

            if let existing = entriesByPreferred[key] {
                entriesByPreferred[key] = PersonalDictionaryEntry(
                    preferredText: existing.preferredText,
                    aliases: uniqueCaseInsensitive(existing.aliases + entry.aliases)
                )
            } else {
                entriesByPreferred[key] = entry
            }
        }

        return entriesByPreferred.values.sorted {
            $0.preferredText.localizedCaseInsensitiveCompare($1.preferredText) == .orderedAscending
        }
    }

    static func entry(for replacement: WordReplacement) -> PersonalDictionaryEntry? {
        let preferred = replacement.replacementText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !preferred.isEmpty else { return nil }

        let aliases = normalizedAliases(
            parseAliases(replacement.originalText),
            preferredText: preferred
        )
        return PersonalDictionaryEntry(preferredText: preferred, aliases: aliases)
    }

    static func parseAliases(_ text: String) -> [String] {
        text.split(whereSeparator: { character in
            character == "," || character.isNewline
        })
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    }

    static func aliasesText(for replacement: WordReplacement) -> String {
        guard let entry = entry(for: replacement) else { return "" }
        return entry.aliases.joined(separator: "\n")
    }

    @discardableResult
    static func saveTerm(
        preferredText: String,
        aliases: [String],
        replacing existing: WordReplacement? = nil,
        context: ModelContext
    ) -> String? {
        let preferred = preferredText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !preferred.isEmpty else {
            return String(localized: "Preferred spelling is required")
        }

        let previousPreferred = existing?.replacementText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let normalized = normalizedAliases(aliases, preferredText: preferred)
        let proposedTerms = Set(
            ([preferred] + normalized).map { $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) }
        )

        if let allReplacements = try? context.fetch(FetchDescriptor<WordReplacement>()) {
            for other in allReplacements {
                if let existing,
                    other.persistentModelID == existing.persistentModelID
                {
                    continue
                }

                guard let otherEntry = entry(for: other) else { continue }
                let otherTerms = Set(
                    otherEntry.recognitionTerms.map {
                        $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    }
                )

                if let duplicate = proposedTerms.intersection(otherTerms).first {
                    let displayValue = ([preferred] + normalized).first {
                        $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) == duplicate
                    } ?? preferred
                    return String(
                        format: String(localized: "'%@' is already used by another dictionary entry"),
                        displayValue
                    )
                }
            }
        }

        let replacement = existing ?? WordReplacement(
            originalText: preferred,
            replacementText: preferred
        )
        replacement.originalText = storedOriginalText(preferredText: preferred, aliases: normalized)
        replacement.replacementText = preferred

        if existing == nil {
            context.insert(replacement)
        }

        ensureVocabularyWord(preferred, context: context)
        if let previousPreferred,
            previousPreferred.caseInsensitiveCompare(preferred) != .orderedSame
        {
            removeVocabularyWordIfUnused(
                previousPreferred,
                excluding: replacement,
                context: context
            )
        }

        do {
            try context.save()
            refreshRecognitionCache(from: context)
            return nil
        } catch {
            context.rollback()
            return String(
                format: String(localized: "Failed to save dictionary term: %@"),
                error.localizedDescription
            )
        }
    }

    static func deleteTerm(_ replacement: WordReplacement, context: ModelContext) throws {
        let preferred = replacement.replacementText.trimmingCharacters(in: .whitespacesAndNewlines)
        let allReplacements = (try? context.fetch(FetchDescriptor<WordReplacement>())) ?? []
        let isUsedElsewhere = allReplacements.contains { other in
            other.persistentModelID != replacement.persistentModelID
                && other.replacementText.caseInsensitiveCompare(preferred) == .orderedSame
        }

        context.delete(replacement)

        if !isUsedElsewhere,
            let vocabularyWords = try? context.fetch(FetchDescriptor<VocabularyWord>())
        {
            for word in vocabularyWords
            where word.word.caseInsensitiveCompare(preferred) == .orderedSame
            {
                context.delete(word)
            }
        }

        do {
            try context.save()
            refreshRecognitionCache(from: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    static func setEnabled(
        _ isEnabled: Bool,
        for replacement: WordReplacement,
        context: ModelContext
    ) throws {
        replacement.isEnabled = isEnabled
        do {
            try context.save()
            refreshRecognitionCache(from: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Converts VoiceInk's old split Vocabulary / Word Replacements stores into
    /// one usable surface without deleting either legacy model. Each vocabulary-only
    /// item gets a no-op replacement row, and every preferred spelling is kept in
    /// VocabularyWord for backup/import compatibility.
    @discardableResult
    static func migrateLegacyVocabulary(context: ModelContext) -> Bool {
        guard
            let vocabularyWords = try? context.fetch(FetchDescriptor<VocabularyWord>()),
            let replacements = try? context.fetch(FetchDescriptor<WordReplacement>())
        else {
            refreshRecognitionCache(from: context)
            return false
        }

        var didChange = false
        var canonicalKeys = Set(
            replacements.map {
                $0.replacementText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }.filter { !$0.isEmpty }
        )
        var vocabularyKeys = Set(
            vocabularyWords.map {
                $0.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }.filter { !$0.isEmpty }
        )

        for vocabularyWord in vocabularyWords {
            let preferred = vocabularyWord.word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !preferred.isEmpty else { continue }
            let key = preferred.lowercased()
            guard !canonicalKeys.contains(key) else { continue }

            context.insert(
                WordReplacement(
                    originalText: preferred,
                    replacementText: preferred,
                    isEnabled: true
                )
            )
            canonicalKeys.insert(key)
            didChange = true
        }

        for replacement in replacements {
            let preferred = replacement.replacementText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !preferred.isEmpty else { continue }
            let key = preferred.lowercased()
            guard !vocabularyKeys.contains(key) else { continue }

            context.insert(VocabularyWord(word: preferred))
            vocabularyKeys.insert(key)
            didChange = true
        }

        if didChange {
            do {
                try context.save()
            } catch {
                context.rollback()
                refreshRecognitionCache(from: context)
                return false
            }
        }

        refreshRecognitionCache(from: context)
        return didChange
    }

    static func refreshRecognitionCache(from context: ModelContext) {
        let currentEntries = entries(from: context)
        guard let data = try? JSONEncoder().encode(currentEntries) else { return }
        UserDefaults.standard.set(data, forKey: recognitionCacheKey)
    }

    static func cachedRecognitionEntries() -> [PersonalDictionaryEntry] {
        guard
            let data = UserDefaults.standard.data(forKey: recognitionCacheKey),
            let entries = try? JSONDecoder().decode([PersonalDictionaryEntry].self, from: data)
        else {
            return []
        }
        return entries
    }

    static func preferredTerms(from context: ModelContext) -> [String] {
        entries(from: context).map(\.preferredText)
    }

    static func promptVocabulary(from context: ModelContext) -> String {
        entries(from: context).map { entry in
            guard !entry.aliases.isEmpty else { return entry.preferredText }
            return "\(entry.preferredText) (may be heard as: \(entry.aliases.joined(separator: ", ")))"
        }.joined(separator: "\n")
    }

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

    private static func normalizedAliases(
        _ aliases: [String],
        preferredText: String
    ) -> [String] {
        let preferredKey = preferredText.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
        return uniqueCaseInsensitive(aliases).filter {
            $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                != preferredKey
        }
    }

    private static func storedOriginalText(
        preferredText: String,
        aliases: [String]
    ) -> String {
        uniqueCaseInsensitive([preferredText] + aliases).joined(separator: ", ")
    }

    private static func ensureVocabularyWord(_ preferredText: String, context: ModelContext) {
        let descriptor = FetchDescriptor<VocabularyWord>()
        guard let words = try? context.fetch(descriptor) else { return }
        if let existing = words.first(where: {
            $0.word.caseInsensitiveCompare(preferredText) == .orderedSame
        }) {
            existing.word = preferredText
            return
        }
        context.insert(VocabularyWord(word: preferredText))
    }

    private static func removeVocabularyWordIfUnused(
        _ preferredText: String,
        excluding replacement: WordReplacement,
        context: ModelContext
    ) {
        let replacements = (try? context.fetch(FetchDescriptor<WordReplacement>())) ?? []
        let isStillUsed = replacements.contains { other in
            other.persistentModelID != replacement.persistentModelID
                && other.replacementText.caseInsensitiveCompare(preferredText) == .orderedSame
        }
        guard !isStillUsed else { return }

        let words = (try? context.fetch(FetchDescriptor<VocabularyWord>())) ?? []
        for word in words
        where word.word.caseInsensitiveCompare(preferredText) == .orderedSame
        {
            context.delete(word)
        }
    }
}
