import XCTest
@testable import VoiceInk

final class CleanupOutputValidatorTests: XCTestCase {
    func testAllowsPunctuationCleanupAroundAnUnchangedNumber() throws {
        let result = try CleanupOutputValidator.validatedText(
            candidate: "Send 5 please.",
            source: "Send 5, please.",
            promptTitle: "David cleanup",
            protectedTerms: []
        )
        XCTAssertEqual(result, "Send 5 please.")
    }

    func testRejectsChangedNumber() {
        XCTAssertThrowsError(
            try CleanupOutputValidator.validatedText(
                candidate: "Send 6 please.",
                source: "Send 5 please.",
                promptTitle: "David cleanup",
                protectedTerms: []
            )
        )
    }

    func testRejectsDroppedRepeatedNumber() {
        XCTAssertThrowsError(
            try CleanupOutputValidator.validatedText(
                candidate: "Send 5 now.",
                source: "Send 5 and 5 now.",
                promptTitle: "David cleanup",
                protectedTerms: []
            )
        )
    }

    func testRejectsInventedNumber() {
        XCTAssertThrowsError(
            try CleanupOutputValidator.validatedText(
                candidate: "Send it on 6 September.",
                source: "Send it in September.",
                promptTitle: "David cleanup",
                protectedTerms: []
            )
        )
    }

    func testRejectsDuplicatedNumber() {
        XCTAssertThrowsError(
            try CleanupOutputValidator.validatedText(
                candidate: "Send 5 and 5 now.",
                source: "Send 5 now.",
                promptTitle: "David cleanup",
                protectedTerms: []
            )
        )
    }

    func testAllowsUnchangedRepeatedNumbers() throws {
        let result = try CleanupOutputValidator.validatedText(
            candidate: "Send 5 and 5 now.",
            source: "Send 5, and 5 now.",
            promptTitle: "David cleanup",
            protectedTerms: []
        )
        XCTAssertEqual(result, "Send 5 and 5 now.")
    }

    func testRejectsReorderedNumbers() {
        XCTAssertThrowsError(
            try CleanupOutputValidator.validatedText(
                candidate: "Send 6 then 5 now.",
                source: "Send 5 then 6 now.",
                promptTitle: "David cleanup",
                protectedTerms: []
            )
        )
    }

    func testRejectsChangedProtectedSpelling() {
        XCTAssertThrowsError(
            try CleanupOutputValidator.validatedText(
                candidate: "Ask underbite tomorrow.",
                source: "Ask Underbite tomorrow.",
                promptTitle: "David cleanup",
                protectedTerms: ["Underbite"]
            )
        )
    }

    func testRejectsProtectedSpellingExpandedIntoLongerWord() {
        XCTAssertThrowsError(
            try CleanupOutputValidator.validatedText(
                candidate: "Talk to Student tomorrow.",
                source: "Talk to Stu tomorrow.",
                promptTitle: "David cleanup",
                protectedTerms: ["Stu"]
            )
        )
    }

    func testRejectsDroppedRepeatedProtectedSpelling() {
        XCTAssertThrowsError(
            try CleanupOutputValidator.validatedText(
                candidate: "Ask Underbite about it.",
                source: "Ask Underbite and Underbite about it.",
                promptTitle: "David cleanup",
                protectedTerms: ["Underbite"]
            )
        )
    }

    func testAllowsUnchangedBoundedProtectedSpelling() throws {
        let result = try CleanupOutputValidator.validatedText(
            candidate: "Talk to Stu tomorrow.",
            source: "Talk to Stu tomorrow.",
            promptTitle: "David cleanup",
            protectedTerms: ["Stu"]
        )
        XCTAssertEqual(result, "Talk to Stu tomorrow.")
    }

    func testAllowsPunctuationAroundProtectedSpelling() throws {
        let result = try CleanupOutputValidator.validatedText(
            candidate: "Ask (Underbite), please.",
            source: "Ask (Underbite), please.",
            promptTitle: "David cleanup",
            protectedTerms: ["Underbite"]
        )
        XCTAssertEqual(result, "Ask (Underbite), please.")
    }

    func testRejectsAssistantPreamble() {
        XCTAssertThrowsError(
            try CleanupOutputValidator.validatedText(
                candidate: "Sure, here is the cleaned text.",
                source: "Here is the text.",
                promptTitle: "Clean Dictation",
                protectedTerms: []
            )
        )
    }

    func testDoesNotConstrainNonCleanupPrompts() throws {
        let result = try CleanupOutputValidator.validatedText(
            candidate: "6",
            source: "5",
            promptTitle: "Rewrite",
            protectedTerms: []
        )
        XCTAssertEqual(result, "6")
    }
}
