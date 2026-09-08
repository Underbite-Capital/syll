import Foundation

@main
struct DeterministicDictationCleanerTests {
    static func main() {
        expect(
            "I think we should probably like send that to Kean tomorrow.",
            from: "yeah so um I think we should probably like send that to Kean tomorrow"
        )
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
