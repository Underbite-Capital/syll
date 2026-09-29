import Foundation

@MainActor
@main
struct ObservationStoreTests {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("syll-observation-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try checkSaveMovesAudioAndPersists(root: root)
        try checkOutstandingContract(root: root)
        try checkProposalSurvivesRereads(root: root)
        try checkCorrectionAfterReviewKeepsBasisExplicit(root: root)
        try checkMarkAddressedIsExplicit(root: root)
        try checkDeleteRemovesRecordAndAudio(root: root)
        try checkFailureKeepsAudio(root: root)
        try checkFailedAudioIsBounded(root: root)
        try checkDiagnosticsDeletionCannotTouchObservations(root: root)
        try checkRestartDurability(root: root)
        print("Observation store tests passed")
    }

    private static func makeAudio(in directory: URL, named name: String) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try Data([0x52, 0x49, 0x46, 0x46]).write(to: url) // "RIFF" stub; store never parses audio
        return url
    }

    @discardableResult
    private static func saveObservation(
        root: URL, name: String, text: String, seconds: Double = 2.0
    ) throws -> SyllObservationStore.Observation {
        let store = SyllObservationStore(root: root)
        let staging = root.appendingPathComponent("staging", isDirectory: true)
        let audio = try makeAudio(in: staging, named: name)
        return try store.save(
            audioURL: audio, originalText: text, text: text,
            audioDurationSeconds: seconds, model: "parakeet-tdt-0.6b-v3")
    }

    /// Simulates the closeout bridge's additive JSON review update.
    private static func writeReview(
        root: URL, id: UUID, disposition: String, status: String, basisText: String
    ) throws {
        let recordURL = root.appendingPathComponent(id.uuidString + ".json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: recordURL)) as! [String: Any]
        json["review"] = [
            "respondedAt": ISO8601DateFormatter().string(from: Date()),
            "responder": "test-reviewer",
            "response": "test response",
            "disposition": disposition,
            "basisText": basisText,
        ]
        json["status"] = status
        try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
            .write(to: recordURL, options: .atomic)
    }

    private static func checkSaveMovesAudioAndPersists(root: URL) throws {
        let observation = try saveObservation(root: root, name: "take.wav", text: "The deploy pipeline feels fragile.")
        let savedAudio = root.appendingPathComponent(observation.audioFile)
        precondition(FileManager.default.fileExists(atPath: savedAudio.path), "audio missing beside record")
        precondition(observation.status == "new", "new observation must start as new")
        precondition(observation.review == nil, "new observation must have no review")
        let perms = try FileManager.default.attributesOfItem(atPath: savedAudio.path)[.posixPermissions] as? Int
        precondition(perms == 0o600, "observation audio must be owner-only")
    }

    private static func checkOutstandingContract(root: URL) throws {
        let store = SyllObservationStore(root: root)
        let summary = store.summary()
        precondition(summary.new == 1 && summary.outstanding == 1, "summary mismatch: \(summary)")
        precondition(store.outstanding().count == 1, "new observation must be outstanding")
    }

    private static func checkProposalSurvivesRereads(root: URL) throws {
        let proposal = try saveObservation(root: root, name: "proposal.wav", text: "Maybe the closeout should group by project.")
        try writeReview(root: root, id: proposal.id, disposition: "proposal",
                        status: "awaitingDecision", basisText: proposal.text)
        // Regression: a proposal awaiting David's decision is not resolved by
        // having a response; it must survive every subsequent outstanding read.
        for _ in 0..<3 {
            let reread = SyllObservationStore(root: root)
            let outstanding = reread.outstanding()
            precondition(outstanding.contains { $0.id == proposal.id && $0.status == "awaitingDecision" },
                         "proposal awaiting decision dropped from outstanding work")
        }
        let answered = try saveObservation(root: root, name: "answered.wav", text: "What time is the standup?")
        try writeReview(root: root, id: answered.id, disposition: "answered",
                        status: "reviewed", basisText: answered.text)
        precondition(!SyllObservationStore(root: root).outstanding().contains { $0.id == answered.id },
                     "answered observation with nothing outstanding should leave the outstanding list")
    }

    private static func checkCorrectionAfterReviewKeepsBasisExplicit(root: URL) throws {
        let store = SyllObservationStore(root: root)
        let proposal = store.allObservations().first { $0.status == "awaitingDecision" }!
        try store.correct(id: proposal.id, text: "Maybe the daily closeout should group observations by project.")
        let reloaded = try store.load(id: proposal.id)
        precondition(reloaded.originalText == "Maybe the closeout should group by project.",
                     "correction rewrote the original text")
        precondition(reloaded.correctedText != nil, "correction not retained")
        precondition(reloaded.review?.basisText == "Maybe the closeout should group by project.",
                     "review basis text lost")
        precondition(reloaded.reviewPredatesCorrection,
                     "stale response must be visibly attached to the old wording")
    }

    private static func checkMarkAddressedIsExplicit(root: URL) throws {
        let store = SyllObservationStore(root: root)
        let proposal = store.allObservations().first { $0.status == "awaitingDecision" }!
        try store.markAddressed(id: proposal.id)
        let reloaded = try store.load(id: proposal.id)
        precondition(reloaded.status == "addressed", "markAddressed did not persist")
        precondition(!store.outstanding().contains { $0.id == proposal.id },
                     "addressed observation must leave the outstanding list")
        precondition(reloaded.review != nil, "marking addressed must not erase the linked response")
    }

    private static func checkDeleteRemovesRecordAndAudio(root: URL) throws {
        let store = SyllObservationStore(root: root)
        let observation = try saveObservation(root: root, name: "delete-me.wav", text: "Delete me.")
        let audio = root.appendingPathComponent(observation.audioFile)
        precondition(FileManager.default.fileExists(atPath: audio.path), "audio missing before delete")
        try store.delete(id: observation.id)
        precondition(!FileManager.default.fileExists(atPath: audio.path), "delete left audio behind")
        precondition(!store.allObservations().contains { $0.id == observation.id }, "delete left record behind")
    }

    private static func checkFailureKeepsAudio(root: URL) throws {
        let store = SyllObservationStore(root: root)
        let staging = root.appendingPathComponent("staging", isDirectory: true)
        let audio = try makeAudio(in: staging, named: "failed-take.wav")
        store.recordFailure(audioURL: audio, reason: "Nothing was recognized")
        let failures = store.failures()
        precondition(failures.count == 1 && failures.first?.reason == "Nothing was recognized",
                     "failed capture not visible")
        precondition(FileManager.default.fileExists(
            atPath: root.appendingPathComponent("Failed/\(failures[0].audioFile)").path),
            "failed audio was not kept")
        let before = store.summary().outstanding
        precondition(failures.count == 1 && before == store.summary().outstanding,
                     "failed capture must not enter the outstanding queue")
        store.deleteFailure(id: failures[0].id)
        precondition(store.failures().isEmpty, "failed capture not deletable")
    }

    private static func checkFailedAudioIsBounded(root: URL) throws {
        let store = SyllObservationStore(root: root)
        let staging = root.appendingPathComponent("staging", isDirectory: true)
        for index in 0..<(SyllObservationStore.maximumFailedCount + 5) {
            let audio = try makeAudio(in: staging, named: "failed-\(index).wav")
            store.recordFailure(audioURL: audio, reason: "synthetic failure \(index)")
        }
        precondition(store.failures().count == SyllObservationStore.maximumFailedCount,
                     "failed audio archive is not bounded")
        let wavCount = try FileManager.default.contentsOfDirectory(
            atPath: root.appendingPathComponent("Failed").path
        ).filter { $0.hasSuffix(".wav") }.count
        precondition(wavCount == SyllObservationStore.maximumFailedCount,
                     "pruned failure left audio behind")
    }

    private static func checkDiagnosticsDeletionCannotTouchObservations(root: URL) throws {
        let diagnosticsRoot = root.appendingPathComponent("FailureEvidence", isDirectory: true)
        let diagnostics = SyllFailureEvidenceStore(root: diagnosticsRoot)
        try diagnostics.deleteAll()
        let store = SyllObservationStore(root: root)
        precondition(!store.allObservations().isEmpty, "diagnostic deletion removed observations")
    }

    private static func checkRestartDurability(root: URL) throws {
        // A fresh store instance on the same root (an app restart) must see
        // every record, including addressed history.
        let fresh = SyllObservationStore(root: root)
        let summary = fresh.summary()
        precondition(summary.new == 1 && summary.awaitingDecision == 0 && summary.addressed == 1,
                     "restart lost state: \(summary)")
        precondition(fresh.allObservations().count == 3, "restart lost observations")
    }
}
