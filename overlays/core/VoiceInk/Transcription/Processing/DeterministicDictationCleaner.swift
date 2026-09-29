import Foundation

enum DeterministicDictationCleaner {
    static func clean(_ text: String) -> String {
        let original = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !original.isEmpty else { return original }

        // Cleanup never deletes utterance-leading words. Real-use evidence
        // (447 ordinary sessions, 2026-09-26…29) showed the former
        // sentence-opening "yeah so" strip removing the first two spoken words
        // of five dictations, which David experiences as first-word loss.
        var result = original

        // Remove only the small, high-confidence hesitation set already used by
        // VoiceInk. Deliberately exclude semantic hedges such as like, maybe,
        // probably, sort of, I think, and you know.
        result = replacing(
            pattern: #"(?i)(?<![\p{L}\p{M}\p{N}])(?:uh+|um+|uhm|umm|hmm+|hm|mmm|mm|mh|ehh+)(?![\p{L}\p{M}\p{N}])"#,
            in: result,
            with: " "
        )

        result = replacing(pattern: #"\s+([,.;:!?])"#, in: result, with: "$1")
        result = replacing(pattern: #",\s*,+"#, in: result, with: ",")
        result = replacing(pattern: #"\s+"#, in: result, with: " ")
        result = replacing(pattern: #"^[,;:]\s*"#, in: result, with: "")
        result = replacing(pattern: #"\s*[,;:]$"#, in: result, with: "")
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // Never let cleanup erase a whole utterance: if only punctuation
        // survives (for example "Mm-hmm." becoming "-."), keep the recognized
        // text instead. A genuine short utterance must stay deliverable.
        if result.range(of: #"[\p{L}\p{M}\p{N}]"#, options: .regularExpression) == nil {
            result = original
        }

        result = uppercaseFirstLetter(in: result)

        if let last = result.last, !".!?…".contains(last) {
            result.append(".")
        }
        return result
    }

    private static func replacing(pattern: String, in text: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
    }

    private static func uppercaseFirstLetter(in text: String) -> String {
        guard let index = text.firstIndex(where: { $0.isLetter }) else { return text }
        let next = text.index(after: index)
        return String(text[..<index]) + text[index..<next].uppercased() + String(text[next...])
    }
}
