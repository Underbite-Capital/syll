import Foundation

enum SyllCommandRegistry {
    static func interpret(_ transcript: String) -> SyllCommandInterpretation {
        let normalized = normalize(transcript)
        guard !normalized.isEmpty else { return .unmatched }

        if normalized == "git status" {
            return .command(.gitStatus)
        }
        if normalized == "copy branch" {
            return .command(.copyBranch)
        }
        if normalized == "open iqs staging" {
            return .command(.openAlias(.iqsStaging))
        }

        let portPatterns: [(prefixes: [String], command: (SyllPort) -> SyllCommand, name: String)] = [
            (["what's on port ", "whats on port ", "what is on port "], SyllCommand.inspectPort, "inspect-port"),
            (["kill port "], SyllCommand.killPort, "kill-port"),
            (["open localhost "], SyllCommand.openLocalhost, "open-localhost"),
        ]

        for pattern in portPatterns {
            guard let prefix = pattern.prefixes.first(where: { normalized.hasPrefix($0) }) else { continue }
            let argument = String(normalized.dropFirst(prefix.count))
            guard let parsed = SpokenPortNumber.parse(argument) else {
                return .invalid(
                    description: "\(pattern.name)(port: \(argument))",
                    reason: "Invalid port; nothing executed"
                )
            }
            guard let port = SyllPort(parsed) else {
                return .invalid(
                    description: "\(pattern.name)(port: \(parsed))",
                    reason: "Port must be between 1 and 65535; nothing executed"
                )
            }
            return .command(pattern.command(port))
        }

        if normalized.hasPrefix("open ") {
            let alias = String(normalized.dropFirst("open ".count))
            return .invalid(
                description: "open-alias(name: \(alias))",
                reason: "Unknown navigation alias; nothing executed"
            )
        }

        return .unmatched
    }

    static func normalize(_ transcript: String) -> String {
        var normalized = transcript
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased(with: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "[‘’ʼ]", with: "'", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        while let last = normalized.unicodeScalars.last,
            CharacterSet(charactersIn: ".,!?;:").contains(last)
        {
            normalized.unicodeScalars.removeLast()
            normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return normalized.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}

private enum SpokenPortNumber {
    private static let small: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4,
        "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
        "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
        "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17,
        "eighteen": 18, "nineteen": 19,
    ]
    private static let tens: [String: Int] = [
        "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
        "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90,
    ]

    static func parse(_ value: String) -> Int? {
        if value.contains(","),
            value.range(of: #"^[0-9]{1,3}(,[0-9]{3})+$"#, options: .regularExpression) == nil
        {
            return nil
        }
        let digitValue = value.replacingOccurrences(of: ",", with: "")
        if !digitValue.isEmpty,
            digitValue.allSatisfy(\.isNumber),
            let digits = Int(digitValue)
        {
            return digits
        }

        let tokens = value.split(separator: " ").map(String.init).filter { $0 != "and" }
        guard !tokens.isEmpty else { return nil }

        if let thousandIndex = tokens.firstIndex(of: "thousand") {
            guard tokens.lastIndex(of: "thousand") == thousandIndex,
                thousandIndex > 0,
                let thousands = parseUnderThousand(Array(tokens[..<thousandIndex])),
                thousands > 0
            else { return nil }

            let remainderTokens = Array(tokens[tokens.index(after: thousandIndex)...])
            let remainder = remainderTokens.isEmpty ? 0 : parseUnderThousand(remainderTokens)
            guard let remainder else { return nil }
            return thousands * 1_000 + remainder
        }

        return parseUnderThousand(tokens)
    }

    private static func parseUnderThousand(_ tokens: [String]) -> Int? {
        guard !tokens.isEmpty else { return nil }
        var index = 0
        var value = 0

        if tokens.count >= 2,
            let hundreds = small[tokens[0]],
            (1...9).contains(hundreds),
            tokens[1] == "hundred"
        {
            value = hundreds * 100
            index = 2
            if index == tokens.count { return value }
        }

        let remainder = Array(tokens[index...])
        if remainder.count == 1, let number = small[remainder[0]] {
            return value + number
        }
        if remainder.count == 1, let number = tens[remainder[0]] {
            return value + number
        }
        if remainder.count == 2,
            let ten = tens[remainder[0]],
            let unit = small[remainder[1]],
            (1...9).contains(unit)
        {
            return value + ten + unit
        }
        return nil
    }
}
