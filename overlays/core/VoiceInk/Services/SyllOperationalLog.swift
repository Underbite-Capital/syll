import Foundation

/// Local, bounded recorder timing for ordinary dictation. No transcript or audio is written here.
@MainActor
final class SyllOperationalLog {
    static let shared = SyllOperationalLog()
    static let maximumSessions = 500
    static let lifetime: TimeInterval = 30 * 24 * 60 * 60

    struct Capture: Codable {
        let transcriptionID: UUID
        let timestamp: Date
        let model: String
        let path: String
        let audioDurationSeconds: Double
        let inferenceSeconds: Double?
        let transcriptionPipelineSeconds: Double
        let shortcutHandlerUptimeSeconds: Double?
        let recorderStartRequestUptimeSeconds: Double?
        let audioUnitStartedUptimeSeconds: Double?
        let firstAcceptedBufferUptimeSeconds: Double?
        let firstNonSilentBufferUptimeSeconds: Double?
        let recordedFrames: UInt64?
        let droppedBuffers: UInt64?
    }

    struct StartupCancellation: Codable {
        let event: String
        let sessionID: UUID
        let timestamp: Date
        let shortcutHandlerUptimeSeconds: Double?
        let recorderStartRequestUptimeSeconds: Double?
        let canceledUptimeSeconds: Double
        let fileExistedAtCancellation: Bool
    }

    private struct Timing {
        var shortcutDown: Double?
        var startRequest: Double?
        var audioUnitStarted: Double? = nil
        var firstAccepted: Double? = nil
        var firstNonSilent: Double? = nil
        var recordedFrames: UInt64? = nil
        var droppedBuffers: UInt64? = nil
    }

    private let directory: URL
    private let files: FileManager
    private var pendingShortcutDown: Double?
    private var timings: [URL: Timing] = [:]

    init(directory: URL? = nil, files: FileManager = .default) {
        self.files = files
        self.directory = directory ?? files.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Syll/OperationalSessions", isDirectory: true)
        try? prune(now: Date())
    }

    func shortcutDown() {
        pendingShortcutDown = ProcessInfo.processInfo.systemUptime
    }

    func recorderRequested(audioURL: URL) {
        timings.removeAll()
        timings[audioURL.standardizedFileURL] = Timing(
            shortcutDown: pendingShortcutDown,
            startRequest: ProcessInfo.processInfo.systemUptime
        )
        pendingShortcutDown = nil
    }

    func audioUnitStarted(audioURL: URL) {
        timings[audioURL.standardizedFileURL]?.audioUnitStarted = ProcessInfo.processInfo.systemUptime
    }

    func recorderStopped(audioURL: URL, snapshot: CoreAudioRecorder.CaptureSnapshot?) {
        guard let snapshot else { return }
        let key = audioURL.standardizedFileURL
        timings[key]?.firstAccepted = snapshot.firstAcceptedBufferNanos == 0 ? nil : Double(snapshot.firstAcceptedBufferNanos) / 1e9
        timings[key]?.firstNonSilent = snapshot.firstNonSilentBufferNanos == 0 ? nil : Double(snapshot.firstNonSilentBufferNanos) / 1e9
        timings[key]?.recordedFrames = snapshot.writtenFrames
        timings[key]?.droppedBuffers = snapshot.droppedBuffers
    }

    func completed(
        audioURL: URL, transcriptionID: UUID, timestamp: Date, model: String,
        audioDuration: Double, inferenceSeconds: Double?, transcriptionPipelineSeconds: Double
    ) {
        let timing = timings.removeValue(forKey: audioURL.standardizedFileURL)
        let capture = Capture(
            transcriptionID: transcriptionID, timestamp: timestamp, model: model,
            path: "local-fluid-audio-parakeet-v3-tdt", audioDurationSeconds: audioDuration,
            inferenceSeconds: inferenceSeconds,
            transcriptionPipelineSeconds: transcriptionPipelineSeconds,
            shortcutHandlerUptimeSeconds: timing?.shortcutDown,
            recorderStartRequestUptimeSeconds: timing?.startRequest,
            audioUnitStartedUptimeSeconds: timing?.audioUnitStarted,
            firstAcceptedBufferUptimeSeconds: timing?.firstAccepted,
            firstNonSilentBufferUptimeSeconds: timing?.firstNonSilent,
            recordedFrames: timing?.recordedFrames, droppedBuffers: timing?.droppedBuffers
        )
        do {
            try files.createDirectory(at: directory, withIntermediateDirectories: true,
                                      attributes: [.posixPermissions: 0o700])
            try files.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let destination = directory.appendingPathComponent(transcriptionID.uuidString + ".json")
            try encoder.encode(capture).write(to: destination, options: .atomic)
            try files.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
            try prune(now: Date())
        } catch {
            // Operational logging must never delay or fail dictation delivery.
        }
    }

    func discard(audioURL: URL) { timings.removeValue(forKey: audioURL.standardizedFileURL) }

    func startupCanceled(audioURL: URL?) {
        let timing = audioURL.flatMap { timings.removeValue(forKey: $0.standardizedFileURL) }
        let event = StartupCancellation(
            event: "canceled-before-recording-ready", sessionID: UUID(), timestamp: Date(),
            shortcutHandlerUptimeSeconds: timing?.shortcutDown ?? pendingShortcutDown,
            recorderStartRequestUptimeSeconds: timing?.startRequest,
            canceledUptimeSeconds: ProcessInfo.processInfo.systemUptime,
            fileExistedAtCancellation: audioURL.map { files.fileExists(atPath: $0.path) } ?? false
        )
        pendingShortcutDown = nil
        do {
            try files.createDirectory(at: directory, withIntermediateDirectories: true,
                                      attributes: [.posixPermissions: 0o700])
            try files.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let destination = directory.appendingPathComponent("startup-" + event.sessionID.uuidString + ".json")
            try encoder.encode(event).write(to: destination, options: .atomic)
            try files.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
            try prune(now: Date())
        } catch {
            // Startup logging is best effort and must not prevent cancellation.
        }
    }

    func deleteAll() throws {
        timings.removeAll()
        if files.fileExists(atPath: directory.path) { try files.removeItem(at: directory) }
    }

    func prune(now: Date) throws {
        guard files.fileExists(atPath: directory.path) else { return }
        let filesInDirectory = try files.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.pathExtension == "json" }
        let sorted = filesInDirectory.sorted {
            let lhs = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let rhs = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return lhs > rhs
        }
        for (index, file) in sorted.enumerated() {
            let created = (try? file.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            if index >= Self.maximumSessions || now.timeIntervalSince(created) > Self.lifetime {
                try files.removeItem(at: file)
            }
        }
    }
}
