import XCTest
@testable import VoiceInk

final class PersonalDictionaryCorrectorTests: XCTestCase {
    func testCorrectsAliasWithExactPreferredSpelling() {
        let entries = [
            PersonalDictionaryEntry(
                preferredText: "Underbite",
                aliases: ["under bite", "underbyte"]
            )
        ]

        XCTAssertEqual(
            PersonalDictionaryCorrector.correct(
                "I spoke to under bite yesterday.",
                entries: entries
            ),
            "I spoke to Underbite yesterday."
        )
    }

    func testLongestAliasWinsAtSameLocation() {
        let entries = [
            PersonalDictionaryEntry(preferredText: "Plus", aliases: ["plus"]),
            PersonalDictionaryEntry(preferredText: "Plus 5", aliases: ["plus five"]),
        ]

        XCTAssertEqual(
            PersonalDictionaryCorrector.correct("Use plus five today", entries: entries),
            "Use Plus 5 today"
        )
    }

    func testDoesNotMatchInsideAnotherWord() {
        let entries = [
            PersonalDictionaryEntry(preferredText: "Stu", aliases: [])
        ]

        XCTAssertEqual(
            PersonalDictionaryCorrector.correct("The student arrived", entries: entries),
            "The student arrived"
        )
    }

    func testCorrectionsDoNotCascade() {
        let entries = [
            PersonalDictionaryEntry(preferredText: "Beta", aliases: ["alpha"]),
            PersonalDictionaryEntry(preferredText: "Gamma", aliases: ["beta"]),
        ]

        XCTAssertEqual(
            PersonalDictionaryCorrector.correct("alpha", entries: entries),
            "Beta"
        )
    }

    func testPreservesSurroundingPunctuation() {
        let entries = [
            PersonalDictionaryEntry(preferredText: "VoiceInk", aliases: ["voice ink"])
        ]

        XCTAssertEqual(
            PersonalDictionaryCorrector.correct("(voice ink), please.", entries: entries),
            "(VoiceInk), please."
        )
    }

    func testCorrectsEveryNonOverlappingOccurrence() {
        let entries = [
            PersonalDictionaryEntry(preferredText: "Corkboard", aliases: ["cork board"])
        ]

        XCTAssertEqual(
            PersonalDictionaryCorrector.correct(
                "cork board then cork board",
                entries: entries
            ),
            "Corkboard then Corkboard"
        )
    }
}
