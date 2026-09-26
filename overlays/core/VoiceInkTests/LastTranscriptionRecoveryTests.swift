import SwiftData
import XCTest
@testable import VoiceInk

@MainActor
final class LastTranscriptionRecoveryTests: XCTestCase {
    func testRecoverySkipsNewerPendingFailedAndCanceledRecords() throws {
        let container = try ModelContainer(
            for: Transcription.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let completed = Transcription(text: "Completed dictation.", duration: 1,
                                      audioFileURL: "file:///tmp/completed.wav", transcriptionStatus: .completed)
        completed.timestamp = Date(timeIntervalSince1970: 1)
        context.insert(completed)

        for (index, status) in [TranscriptionStatus.pending, .failed, .canceled].enumerated() {
            let record = Transcription(text: "Do not recover", duration: 1, transcriptionStatus: status)
            record.timestamp = Date(timeIntervalSince1970: Double(index + 2))
            context.insert(record)
        }
        try context.save()

        XCTAssertEqual(LastTranscriptionService.latestCompletedText(from: context), "Completed dictation.")
    }

    func testRecoverySelectsNewestPersistedCompletion() throws {
        let container = try ModelContainer(
            for: Transcription.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let older = Transcription(text: "First.", duration: 1,
                                  audioFileURL: "file:///tmp/first.wav", transcriptionStatus: .completed)
        older.timestamp = Date(timeIntervalSince1970: 1)
        context.insert(older)
        let newer = Transcription(text: "Second.", duration: 1,
                                  audioFileURL: "file:///tmp/second.wav", transcriptionStatus: .completed)
        newer.timestamp = Date(timeIntervalSince1970: 2)
        context.insert(newer)
        let typed = Transcription(text: "Typed assistant turn", duration: 0, transcriptionStatus: .completed)
        typed.timestamp = Date(timeIntervalSince1970: 3)
        context.insert(typed)
        try context.save()

        XCTAssertEqual(LastTranscriptionService.latestCompletedText(from: context), "Second.")
    }
}
