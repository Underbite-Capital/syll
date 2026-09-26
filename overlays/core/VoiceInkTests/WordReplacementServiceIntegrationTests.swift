import SwiftData
import XCTest
@testable import VoiceInk

@MainActor
final class WordReplacementServiceIntegrationTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: VocabularyWord.self, WordReplacement.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func testOrdinaryCleanupStillCapitalizesSentence() throws {
        let context = try makeContext()
        XCTAssertEqual(
            WordReplacementService.shared.applyReplacements(to: "  hello  ,  world  ", using: context),
            "Hello, world."
        )
    }

    func testPreferredMixedCaseAtBeginningSurvivesCleanup() throws {
        let context = try makeContext()
        XCTAssertNil(PersonalDictionaryService.saveTerm(
            preferredText: "iPhone", aliases: ["eye phone"], context: context
        ))
        XCTAssertEqual(
            WordReplacementService.shared.applyReplacements(to: "eye phone works", using: context),
            "iPhone works."
        )
    }

    func testAliasesAndPunctuationDoNotCascade() throws {
        let context = try makeContext()
        XCTAssertNil(PersonalDictionaryService.saveTerm(
            preferredText: "Beta", aliases: ["alpha"], context: context
        ))
        XCTAssertNil(PersonalDictionaryService.saveTerm(
            preferredText: "Gamma", aliases: ["beta"], context: context
        ))
        XCTAssertEqual(
            WordReplacementService.shared.applyReplacements(to: "  alpha  ,  alpha  ", using: context),
            "Beta, Beta."
        )
    }
}
