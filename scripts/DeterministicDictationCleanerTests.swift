import Foundation

@main
struct DeterministicDictationCleanerTests {
    static func main() {
        // Leading words are never deleted: real-use evidence showed the former
        // "yeah so" opening strip causing the reported first-word loss.
        expect(
            "Yeah so I think we should probably like send that to Kean tomorrow.",
            from: "yeah so um I think we should probably like send that to Kean tomorrow"
        )
        // Real 2026-09-28 ordinary session: the first two spoken words survive.
        expect(
            "Yeah, so now it's really small.",
            from: "Yeah, so now it's really small."
        )
        // Cleanup must never erase a whole utterance: a genuine short
        // affirmation stays deliverable instead of collapsing to "-."
        // (real 2026-09-29 ordinary session).
        expect("Mm-hmm.", from: "Mm-hmm.")
        expect("Um.", from: "um")
        expect("Shukuru uses Supabase.", from: "shukuru uses Supabase")
        expect("I think maybe we should wait.", from: "I think maybe we should wait")
        expect("This is sort of important.", from: "this is sort of important")
        expect("I probably like the first version.", from: "I probably like the first version")
        expect("Kean, please check this.", from: "Kean, um, please check this")
        expect("Are we ready?", from: "are we ready?")
        expect("Version 2.1 is stable.", from: "version 2.1 is stable.")
        expect("Yeah, I agree.", from: "yeah, I agree")
        print("DeterministicDictationCleaner tests passed")
    }

    private static func expect(_ expected: String, from source: String) {
        let actual = DeterministicDictationCleaner.clean(source)
        guard actual == expected else {
            fputs("FAIL\nsource: \(source)\nexpected: \(expected)\nactual: \(actual)\n", stderr)
            exit(1)
        }
    }
}
