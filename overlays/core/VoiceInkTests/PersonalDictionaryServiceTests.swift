import SwiftData
import XCTest
@testable import VoiceInk

@MainActor
final class PersonalDictionaryServiceTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: VocabularyWord.self,
            WordReplacement.self,
            configurations: configuration
        )
        return ModelContext(container)
    }

    func testPreferredOnlyTermPersistsAndRefreshesRecognitionCache() throws {
        let context = try makeContext()

        XCTAssertNil(PersonalDictionaryService.saveTerm(
            preferredText: "Shukuru", aliases: [], context: context
        ))

        XCTAssertEqual(PersonalDictionaryService.entries(from: context), [
            PersonalDictionaryEntry(preferredText: "Shukuru", aliases: [])
        ])
        XCTAssertEqual(PersonalDictionaryService.preferredTerms(from: context), ["Shukuru"])
        XCTAssertEqual(PersonalDictionaryService.cachedRecognitionEntries(), [
            PersonalDictionaryEntry(preferredText: "Shukuru", aliases: [])
        ])
    }

    func testAliasPersistsEditsAndCorrectsOnTheNextTranscript() throws {
        let context = try makeContext()
        XCTAssertNil(PersonalDictionaryService.saveTerm(
            preferredText: "Supabase", aliases: ["Super Base"], context: context
        ))

        let replacement = try XCTUnwrap(
            try context.fetch(FetchDescriptor<WordReplacement>()).first
        )
        XCTAssertNil(PersonalDictionaryService.saveTerm(
            preferredText: "Supabase", aliases: ["Super Base", "Supa Base"],
            replacing: replacement, context: context
        ))

        XCTAssertEqual(
            PersonalDictionaryCorrector.correct(
                "Super Base and Supa Base", entries: PersonalDictionaryService.entries(from: context)
            ),
            "Supabase and Supabase"
        )
        XCTAssertEqual(PersonalDictionaryService.preferredTerms(from: context), ["Supabase"])
    }

    func testRecognitionTermsIncludePreferredAndAliasesInStableDeduplicatedOrder() throws {
        let context = try makeContext()
        XCTAssertNil(PersonalDictionaryService.saveTerm(
            preferredText: "Shukuru", aliases: ["shukuru"], context: context
        ))
        XCTAssertNil(PersonalDictionaryService.saveTerm(
            preferredText: "Supabase", aliases: ["Super Base", "super base"], context: context
        ))

        XCTAssertEqual(
            PersonalDictionaryService.recognitionTerms(from: context),
            ["Shukuru", "Supabase", "Super Base"]
        )
    }

    func testRecognitionTermsRespectsBound() throws {
        let context = try makeContext()
        XCTAssertNil(PersonalDictionaryService.saveTerm(
            preferredText: "Shukuru", aliases: [], context: context
        ))
        XCTAssertNil(PersonalDictionaryService.saveTerm(
            preferredText: "Supabase", aliases: ["Super Base"], context: context
        ))

        XCTAssertEqual(PersonalDictionaryService.recognitionTerms(from: context, limit: 2), ["Shukuru", "Supabase"])
    }

    func testDeleteRemovesPreferredTermAndRecognitionCacheEntry() throws {
        let context = try makeContext()
        XCTAssertNil(PersonalDictionaryService.saveTerm(
            preferredText: "Shukuru", aliases: [], context: context
        ))
        let replacement = try XCTUnwrap(
            try context.fetch(FetchDescriptor<WordReplacement>()).first
        )

        try PersonalDictionaryService.deleteTerm(replacement, context: context)

        XCTAssertTrue(PersonalDictionaryService.entries(from: context).isEmpty)
        XCTAssertTrue(PersonalDictionaryService.preferredTerms(from: context).isEmpty)
        XCTAssertTrue(PersonalDictionaryService.cachedRecognitionEntries().isEmpty)
    }

    func testDuplicatePreferredOrAliasIsRejected() throws {
        let context = try makeContext()
        XCTAssertNil(PersonalDictionaryService.saveTerm(
            preferredText: "Supabase", aliases: ["Super Base"], context: context
        ))

        let error = PersonalDictionaryService.saveTerm(
            preferredText: "Super Base", aliases: [], context: context
        )

        XCTAssertEqual(error, "'Super Base' is already used by another dictionary entry")
    }
}
