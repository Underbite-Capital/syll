import Foundation

@MainActor
@main
struct ObservationStoreTests {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("syll-observation-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try checkSaveMovesAudioAndPersists(root: root)
        try checkAwaitingReviewContract(root: root)
        try checkFailureKeepsAudio(root: root)
        try checkDiagnosticsDeletionCannotTouchObservations(root: root)
        try checkCorrectionPreservesOriginal(root: root)
        print("Observation store tests passed")
    }

    private static func makeAudio(in directory: URL, named name: String) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try Data([0x52, 0x49, 0x46, 0x46]).write(to: url) // "RIFF" stub; store never parses audio
        return url
    }

    private static func checkSaveMovesAudioAndPersists(root: URL) throws {
        let store = SyllObservationStore(root: root)
        let staging = root.appendingPathComponent("staging", isDirectory: true)
        let audio = try makeAudio(in: staging, named: "take.wav")
        let observation = try store.save(
            audioURL: audio,
            originalText: "uh the deploy pipeline feels fragile",
            text: "The deploy pipeline feels fragile.",
            audioDurationSeconds: 2.4,
            model: "parakeet-tdt-0.6b-v3"
        )
        precondition(!FileManager.default.fileExists(atPath: audio.path), "audio was not moved out of staging")
        let savedAudio = root.appendingPathComponent(observation.audioFile)
        precondition(FileManager.default.fileExists(atPath: savedAudio.path), "audio missing beside record")
        precondition(observation.status == "new", "new observation must start as new")
        precondition(observation.originalText == "uh the deploy pipeline feels fragile", "original text not preserved")
        precondition(observation.review == nil, "new observation must have no review")
        let perms = try FileManager.default.attributesOfItem(atPath: savedAudio.path)[.posixPermissions] as? Int
        precondition(perms == 0o600, "observation audio must be owner-only")
    }

    private static func checkAwaitingReviewContract(root: URL) throws {
        let store = SyllObservationStore(root: root)
        let summary = store.summary()
        precondition(summary.new == 1 && summary.awaitingReview == 1 && summary.reviewed == 0,
                     "summary mismatch: \(summary)")
        let awaiting = store.awaitingReview()
        precondition(awaiting.count == 1 && awaiting.first?.status == "new",
                     "awaitingReview must return new observations")
        precondition(store.latest()?.id == awaiting.first?.id, "latest mismatch")
    }

    private static func checkFailureKeepsAudio(root: URL) throws {
        let store = SyllObservationStore(root: root)
        let staging = root.appendingPathComponent("staging", isDirectory: true)
        let audio = try makeAudio(in: staging, named: "failed-take.wav")
        store.recordFailure(audioURL: audio, reason: "Nothing was recognized")
        let failed = root.appendingPathComponent("Failed", isDirectory: true)
        let contents = try FileManager.default.contentsOfDirectory(at: failed, includingPropertiesForKeys: nil)
        precondition(contents.contains { $0.pathExtension == "wav" }, "failed audio was not kept")
        precondition(contents.contains { $0.pathExtension == "json" }, "failure note was not written")
        // A failed capture is not a saved observation.
        precondition(store.summary().awaitingReview == 1, "failed capture must not enter review queue")
    }

    private static func checkDiagnosticsDeletionCannotTouchObservations(root: URL) throws {
        // Diagnostic stores live under their own roots; deleting them must not
        // affect intentionally saved observations.
        let diagnosticsRoot = root.appendingPathComponent("FailureEvidence", isDirectory: true)
        let diagnostics = SyllFailureEvidenceStore(root: diagnosticsRoot)
        try diagnostics.deleteAll()
        let store = SyllObservationStore(root: root)
        precondition(store.summary().new == 1, "diagnostic deletion removed observations")
        precondition(store.awaitingReview().count == 1, "observation record lost after diagnostic deletion")
    }

    private static func checkCorrectionPreservesOriginal(root: URL) throws {
        // The closeout tool writes corrections as additive fields. Simulate its
        // JSON update and verify the original recognized text survives.
        let store = SyllObservationStore(root: root)
        guard let observation = store.latest() else {
            preconditionFailure("no observation to correct")
        }
        let recordURL = root.appendingPathComponent(observation.id.uuidString + ".json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: recordURL)) as! [String: Any]
        json["correctedText"] = "The deployment pipeline feels fragile."
        json["correctedAt"] = ISO8601DateFormatter().string(from: Date())
        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: recordURL, options: .atomic)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let reloaded = try decoder.decode(
            SyllObservationStore.Observation.self, from: Data(contentsOf: recordURL))
        precondition(reloaded.originalText == "uh the deploy pipeline feels fragile",
                     "correction rewrote the original text")
        precondition(reloaded.correctedText == "The deployment pipeline feels fragile.",
                     "correction was not retained")
        precondition(reloaded.status == "new", "correction must not mark an observation reviewed")
    }
}
