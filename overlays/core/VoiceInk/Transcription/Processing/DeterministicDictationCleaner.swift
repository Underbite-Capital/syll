import Foundation

enum DeterministicDictationCleaner {
    static func clean(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { return result }

        // A sentence-opening "yeah so" is overwhelmingly dictation scaffolding in
        // this interaction. Do not remove either word elsewhere in the sentence.
        result = replacing(
            pattern: #"(?i)^\s*yeah\s*,?\s+so\s*,?\s+"#,
            in: result,
            with: ""
        )

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
        result = result.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters.subtracting(CharacterSet(charactersIn: ".!?"))))

        guard !result.isEmpty else { return result }
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
        return text[..<index] + text[index..<next].uppercased() + text[next...]
    }
}
