import Foundation

enum PersonalDictionaryCorrector {
    private struct MatchCandidate {
        let range: NSRange
        let replacement: String
        let priority: Int
    }

    static func correct(
        _ text: String,
        entries: [PersonalDictionaryEntry]
    ) -> String {
        guard !text.isEmpty, !entries.isEmpty else { return text }

        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        var candidates: [MatchCandidate] = []
        var priority = 0

        for entry in entries {
            let aliases = PersonalDictionaryService.uniqueCaseInsensitive(
                [entry.preferredText] + entry.aliases
            ).sorted {
                $0.count > $1.count
            }

            for alias in aliases {
                guard let regex = try? NSRegularExpression(
                    pattern: boundedMatchPattern(for: alias),
                    options: [.caseInsensitive]
                ) else {
                    continue
                }

                for match in regex.matches(in: text, options: [], range: fullRange) {
                    candidates.append(
                        MatchCandidate(
                            range: match.range,
                            replacement: entry.preferredText,
                            priority: priority
                        )
                    )
                }
                priority += 1
            }
        }

        guard !candidates.isEmpty else { return text }

        candidates.sort { lhs, rhs in
            if lhs.range.location != rhs.range.location {
                return lhs.range.location < rhs.range.location
            }
            if lhs.range.length != rhs.range.length {
                return lhs.range.length > rhs.range.length
            }
            return lhs.priority < rhs.priority
        }

        var selected: [MatchCandidate] = []
        var occupiedUntil = -1
        for candidate in candidates {
            guard candidate.range.location >= occupiedUntil else { continue }
            selected.append(candidate)
            occupiedUntil = NSMaxRange(candidate.range)
        }

        let result = NSMutableString(string: text)
        for candidate in selected.reversed() {
            result.replaceCharacters(in: candidate.range, with: candidate.replacement)
        }
        return result as String
    }

    /// Case-sensitive count of exact preferred-spelling occurrences using the
    /// same boundary class as alias matching.
    static func boundedOccurrenceCount(of term: String, in text: String) -> Int {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !text.isEmpty else { return 0 }
        guard let regex = try? NSRegularExpression(
            pattern: boundedMatchPattern(for: trimmed),
            options: []
        ) else {
            return 0
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.numberOfMatches(in: text, options: [], range: range)
    }

    private static func boundedMatchPattern(for term: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: term)
        if usesWordBoundaries(for: term) {
            let wordCharacter = "[[\\p{L}\\p{M}\\p{N}]-[\\p{scx=Han}\\p{scx=Hiragana}\\p{scx=Katakana}\\p{scx=Hangul}\\p{scx=Thai}]]"
            return "(?<!\(wordCharacter))\(escaped)(?!\(wordCharacter))"
        }
        return escaped
    }

    private static func usesWordBoundaries(for text: String) -> Bool {
        let nonSpacedScripts: [ClosedRange<UInt32>] = [
            0x3040...0x309F,  // Hiragana
            0x30A0...0x30FF,  // Katakana
            0x4E00...0x9FFF,  // CJK Unified Ideographs
            0xAC00...0xD7AF,  // Hangul Syllables
            0x0E00...0x0E7F,  // Thai
        ]

        return !text.unicodeScalars.contains { scalar in
            nonSpacedScripts.contains { $0.contains(scalar.value) }
        }
    }
}
