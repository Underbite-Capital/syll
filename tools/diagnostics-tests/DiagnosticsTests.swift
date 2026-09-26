import Foundation

// The operational log accepts only this read-only snapshot shape from the recorder.
// This shim lets the Foundation-only store tests run without an app host or microphone.
final class CoreAudioRecorder {
    struct CaptureSnapshot {
        let firstAcceptedBufferNanos: UInt64
        let firstNonSilentBufferNanos: UInt64
        let writtenFrames: UInt64
        let droppedBuffers: UInt64
    }
}

@main
struct DiagnosticsTests {
    @MainActor
    static func main() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("syll-diagnostics-tests-\(UUID())")
        defer { try? FileManager.default.removeItem(at: base) }
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let store = SyllFailureEvidenceStore(root: base.appendingPathComponent("evidence"))
        let log = SyllOperationalLog(directory: base.appendingPathComponent("operational"))
        precondition(SyllClipboardResetPolicy.canRestore(
            currentSessionID: "session", currentText: "changed", expectedSessionID: "session", expectedText: "Syll text"))
        precondition(SyllClipboardResetPolicy.canRestore(
            currentSessionID: nil, currentText: "Syll text", expectedSessionID: "session", expectedText: "Syll text"))
        precondition(!SyllClipboardResetPolicy.canRestore(
            currentSessionID: nil, currentText: "user copy", expectedSessionID: "session", expectedText: "Syll text"))
        let audio = base.appendingPathComponent("recording.wav")
        let bytes = Data(repeating: 0x41, count: 64 * 1024)
        try bytes.write(to: audio)

        func stage(_ id: UUID, raw: String = "raw-private-\(UUID())", final: String = "Final text") -> Bool {
            store.begin(audioURL: audio)
            store.captureRaw(audioURL: audio, text: raw, inferenceSeconds: 0.123)
            return store.stageCompleted(
                audioURL: audio, transcriptionID: id, timestamp: Date(), finalText: final,
                model: "parakeet-tdt-0.6b-v3", audioDuration: 2
            )
        }

        let first = UUID()
        let raw = "raw-local-bounded-ordinary"
        precondition(stage(first, raw: raw, final: "PreferredName"))
        let ordinary = base.appendingPathComponent("evidence/ordinary")
        let firstDirectory = ordinary.appendingPathComponent(first.uuidString)
        let firstMetadata = try Data(contentsOf: firstDirectory.appendingPathComponent("failure.json"))
        precondition(String(data: firstMetadata, encoding: .utf8)!.contains(raw))
        let firstAudio = try Data(contentsOf: firstDirectory.appendingPathComponent("recording.wav"))
        precondition(firstAudio == bytes)
        let permissions = try FileManager.default.attributesOfItem(
            atPath: firstDirectory.appendingPathComponent("recording.wav").path
        )[.posixPermissions] as! NSNumber
        precondition((permissions.intValue & 0o077) == 0)

        let second = UUID()
        precondition(stage(second, raw: "raw-second", final: "ExactFinal"))
        precondition(FileManager.default.fileExists(atPath: firstDirectory.path), "bounded ordinary corpus lost prior session")
        let markedSecond = try store.markLatest()
        precondition(markedSecond == second)
        let marked = base.appendingPathComponent("evidence/marked/\(second.uuidString)")
        let metadataURL = marked.appendingPathComponent("failure.json")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let metadata = try decoder.decode(SyllFailureEvidenceStore.MarkedFailure.self, from: Data(contentsOf: metadataURL))
        precondition(metadata.transcriptionID == second && metadata.rawRecognizerText == "raw-second")
        precondition(metadata.finalText == "ExactFinal")
        let markedAudioData = try Data(contentsOf: marked.appendingPathComponent(metadata.audioFile))
        precondition(markedAudioData == bytes)

        let expired = UUID()
        precondition(stage(expired))
        store.expire(now: Date().addingTimeInterval(SyllFailureEvidenceStore.markWindow + 1))
        precondition(!store.canMarkLatest)
        precondition(FileManager.default.fileExists(atPath: ordinary.appendingPathComponent(expired.uuidString).path))
        try store.pruneOrdinary(now: Date().addingTimeInterval(SyllFailureEvidenceStore.ordinaryLifetime + 1))
        let afterExpiry = try FileManager.default.contentsOfDirectory(at: ordinary, includingPropertiesForKeys: nil)
        precondition(afterExpiry.isEmpty)

        let oversized = base.appendingPathComponent("missing.wav")
        store.begin(audioURL: oversized)
        store.captureRaw(audioURL: oversized, text: "unavailable", inferenceSeconds: 0.1)
        precondition(!store.stageCompleted(audioURL: oversized, transcriptionID: UUID(),
            timestamp: Date(), finalText: "unavailable", model: "parakeet-tdt-0.6b-v3", audioDuration: 1))
        precondition(!store.canMarkLatest, "failed newest staging must not expose an older dictation")

        for _ in 0..<(SyllFailureEvidenceStore.maximumMarkedCount + 3) {
            let id = UUID()
            precondition(stage(id))
            let markedID = try store.markLatest()
            precondition(markedID == id)
        }
        let markedEntries = try FileManager.default.contentsOfDirectory(
            at: base.appendingPathComponent("evidence/marked"), includingPropertiesForKeys: nil
        )
        precondition(markedEntries.count == SyllFailureEvidenceStore.maximumMarkedCount)

        var newestOrdinaryID = UUID()
        var stagedOrdinaryIDs: [UUID] = []
        for index in 0..<8 {
            newestOrdinaryID = UUID()
            precondition(stage(newestOrdinaryID))
            stagedOrdinaryIDs.append(newestOrdinaryID)
            let directory = ordinary.appendingPathComponent(newestOrdinaryID.uuidString)
            try FileManager.default.setAttributes(
                [.creationDate: Date().addingTimeInterval(Double(index - 100))],
                ofItemAtPath: directory.path
            )
        }
        try store.pruneOrdinary(now: Date(), maximumCount: 5)
        let countEntries = try FileManager.default.contentsOfDirectory(at: ordinary, includingPropertiesForKeys: nil)
        precondition(countEntries.count == 5)
        precondition(!FileManager.default.fileExists(atPath: ordinary.appendingPathComponent(stagedOrdinaryIDs[0].uuidString).path))
        precondition(FileManager.default.fileExists(atPath: ordinary.appendingPathComponent(newestOrdinaryID.uuidString).path))
        try store.pruneOrdinary(now: Date(), maximumBytes: Int64(bytes.count * 2))
        let byteEntries = try FileManager.default.contentsOfDirectory(at: ordinary, includingPropertiesForKeys: nil)
        precondition(byteEntries.count == 2, "byte cap must evict oldest sessions")
        precondition(FileManager.default.fileExists(atPath: ordinary.appendingPathComponent(newestOrdinaryID.uuidString).path))
        precondition(store.canMarkLatest)
        let newestMarkedID = try store.markLatest()
        precondition(newestMarkedID == newestOrdinaryID)

        log.shortcutDown()
        log.recorderRequested(audioURL: audio)
        log.audioUnitStarted(audioURL: audio)
        log.recorderStopped(audioURL: audio, snapshot: .init(
            firstAcceptedBufferNanos: 1_000_000_000,
            firstNonSilentBufferNanos: 1_010_000_000,
            writtenFrames: 32_000,
            droppedBuffers: 0
        ))
        let logID = UUID()
        log.completed(audioURL: audio, transcriptionID: logID, timestamp: Date(),
                      model: "parakeet-tdt-0.6b-v3", audioDuration: 2,
                      inferenceSeconds: 0.1, transcriptionPipelineSeconds: 0.123)
        let logURL = base.appendingPathComponent("operational/\(logID.uuidString).json")
        let captured = try decoder.decode(SyllOperationalLog.Capture.self, from: Data(contentsOf: logURL))
        precondition(captured.recordedFrames == 32_000 && captured.droppedBuffers == 0)
        let logText = String(data: try Data(contentsOf: logURL), encoding: .utf8)!
        precondition(!logText.contains(raw))

        log.shortcutDown()
        log.recorderRequested(audioURL: audio)
        log.startupCanceled(audioURL: audio)
        let operationFiles = try FileManager.default.contentsOfDirectory(
            at: base.appendingPathComponent("operational"), includingPropertiesForKeys: nil
        )
        let startupFile = operationFiles.first { $0.lastPathComponent.hasPrefix("startup-") }!
        let startup = try decoder.decode(SyllOperationalLog.StartupCancellation.self,
                                         from: Data(contentsOf: startupFile))
        precondition(startup.event == "canceled-before-recording-ready")

        // Operational timing shares the ordinary 30-day window and evicts oldest first.
        try FileManager.default.setAttributes(
            [.creationDate: Date().addingTimeInterval(-100)], ofItemAtPath: logURL.path
        )
        try FileManager.default.setAttributes(
            [.creationDate: Date()], ofItemAtPath: startupFile.path
        )
        try log.prune(now: Date(), maximumCount: 1)
        precondition(!FileManager.default.fileExists(atPath: logURL.path))
        precondition(FileManager.default.fileExists(atPath: startupFile.path))

        // Local capture cost with the ordinary corpus already at its count cap.
        let minuteAudio = base.appendingPathComponent("minute.wav")
        try Data(repeating: 0x31, count: 1_920_044).write(to: minuteAudio)
        store.begin(audioURL: minuteAudio)
        store.captureRaw(audioURL: minuteAudio, text: "synthetic", inferenceSeconds: 0.01)
        let start = ProcessInfo.processInfo.systemUptime
        precondition(store.stageCompleted(audioURL: minuteAudio, transcriptionID: UUID(),
            timestamp: Date(), finalText: "synthetic", model: "parakeet-tdt-0.6b-v3", audioDuration: 60))
        let elapsed = (ProcessInfo.processInfo.systemUptime - start) * 1000

        try store.deleteAll()
        try log.deleteAll()
        precondition(!FileManager.default.fileExists(atPath: base.appendingPathComponent("evidence").path))
        precondition(!FileManager.default.fileExists(atPath: base.appendingPathComponent("operational").path))

        print(String(format: "Diagnostics tests passed; 1-minute synthetic audio staging at cap %.2f ms", elapsed))
    }
}
