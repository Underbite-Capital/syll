import Foundation

/// A deliberately conservative guard around dictation cleanup. Rejection is
/// expected to fall through to VoiceInk's already-corrected transcript rather
/// than blocking delivery or asking a second model to judge the first.
enum CleanupOutputValidator {
    static func isCleanupPrompt(_ promptTitle: String?) -> Bool {
        guard let promptTitle else { return false }
        let normalized = promptTitle.lowercased()
        return normalized.contains("cleanup") || normalized.contains("clean dictation")
    }

    static func validatedText(
        candidate: String,
        source: String,
        promptTitle: String?,
        protectedTerms: [String]
    ) throws -> String {
        let trimmedCandidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isCleanupPrompt(promptTitle) else { return trimmedCandidate }

        if trimmedCandidate.isEmpty {
            throw rejection("the model returned no text")
        }

        if trimmedCandidate.contains("```") {
            throw rejection("the model wrapped the result in a code fence")
        }

        let lowered = trimmedCandidate.lowercased()
        let assistantPreambles = [
            "sure,", "sure!", "certainly,", "certainly!", "of course,",
            "here's the", "here is the", "i've cleaned", "i have cleaned",
        ]
        if assistantPreambles.contains(where: { lowered.hasPrefix($0) }) {
            throw rejection("the model answered instead of returning only the dictation")
        }

        let sourceWordCount = wordCount(source)
        let candidateWordCount = wordCount(trimmedCandidate)
        if sourceWordCount >= 4 {
            let ratio = Double(candidateWordCount) / Double(max(1, sourceWordCount))
            if ratio < 0.35 || ratio > 1.70 {
                throw rejection("the output changed length implausibly")
            }
        }

        let sourceNumbers = numericTokens(in: source)
        let candidateNumbers = numericTokens(in: trimmedCandidate)
        if !sourceNumbers.isSubset(of: candidateNumbers) {
            throw rejection("one or more numbers changed or disappeared")
        }

        for term in protectedTerms where source.contains(term) {
            if !trimmedCandidate.contains(term) {
                throw rejection("the protected spelling '\(term)' changed or disappeared")
            }
        }

        return trimmedCandidate
    }

    private static func rejection(_ reason: String) -> EnhancementError {
        EnhancementError.customError("Cleanup output rejected because \(reason). Using the corrected transcript instead.")
    }

    private static func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace }).count
    }

    private static func numericTokens(in text: String) -> Set<String> {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?<![\p{L}\p{N}])[-+]?\d(?:[\d.,:/\-]*\d)?%?(?![\p{L}\p{N}])"#
        ) else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return Set(regex.matches(in: text, range: range).compactMap { match in
            guard let swiftRange = Range(match.range, in: text) else { return nil }
            return String(text[swiftRange])
        })
    }
}
