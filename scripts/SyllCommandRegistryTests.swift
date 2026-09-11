import Foundation

private func expect(_ actual: SyllCommandInterpretation, _ expected: SyllCommandInterpretation, _ message: String) {
    guard actual == expected else {
        fatalError("\(message): expected \(expected), got \(actual)")
    }
}

@main
enum SyllCommandRegistryTests {
    static func main() {
        expect(
            SyllCommandRegistry.interpret("  KILL   PORT three thousand!  "),
            .command(.killPort(SyllPort(3_000)!)),
            "normalizes and parses spoken ports"
        )
        expect(
            SyllCommandRegistry.interpret("what is on port sixty five thousand five hundred thirty five"),
            .command(.inspectPort(SyllPort(65_535)!)),
            "accepts upper port boundary"
        )
        expect(
            SyllCommandRegistry.interpret("What’s on port 3,000?"),
            .command(.inspectPort(SyllPort(3_000)!)),
            "normalizes ASR apostrophes and digit grouping"
        )
        expect(
            SyllCommandRegistry.interpret("open localhost 1"),
            .command(.openLocalhost(SyllPort(1)!)),
            "accepts lower port boundary"
        )
        expect(SyllCommandRegistry.interpret("git status"), .command(.gitStatus), "matches git status")
        expect(SyllCommandRegistry.interpret("copy branch."), .command(.copyBranch), "matches copy branch")
        expect(
            SyllCommandRegistry.interpret("open IQS staging"),
            .command(.openAlias(.iqsStaging)),
            "matches the bounded alias"
        )

        guard case .invalid = SyllCommandRegistry.interpret("kill port 0") else {
            fatalError("port zero must be invalid")
        }
        guard case .invalid = SyllCommandRegistry.interpret("kill port 65536") else {
            fatalError("ports above 65535 must be invalid")
        }
        guard case .invalid = SyllCommandRegistry.interpret("kill port 3,00") else {
            fatalError("malformed digit grouping must be invalid")
        }
        guard case .invalid = SyllCommandRegistry.interpret("open production") else {
            fatalError("unknown aliases must be invalid")
        }
        expect(
            SyllCommandRegistry.interpret("kill port 3000; open localhost 3001"),
            .invalid(
                description: "kill-port(port: 3000; open localhost 3001)",
                reason: "Invalid port; nothing executed"
            ),
            "does not accept command chaining"
        )
        expect(
            SyllCommandRegistry.interpret("delete everything"),
            .unmatched,
            "unmatched text has no command"
        )

        print("Syll command registry tests passed")
    }
}
