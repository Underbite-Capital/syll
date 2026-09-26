import Foundation

/// Local bounded ordinary-session corpus. Only the latest completion can be explicitly marked.
@MainActor
final class SyllFailureEvidenceStore {
    static let shared = SyllFailureEvidenceStore()
    static let markWindow: TimeInterval = 5 * 60
    static let ordinaryLifetime: TimeInterval = 24 * 60 * 60
    static let maximumOrdinaryCount = 100
    static let maximumOrdinaryBytes: Int64 = 512 * 1024 * 1024
    static let markedLifetime: TimeInterval = 30 * 24 * 60 * 60
    static let maximumMarkedCount = 20
    static let maximumAudioBytes = 32 * 1024 * 1024

    struct MarkedFailure: Codable {
        let schemaVersion: Int
        let transcriptionID: UUID
        let timestamp: Date
        let rawRecognizerText: String
        let finalText: String
        let model: String
        let recognitionPath: String
        let audioDurationSeconds: Double
        let inferenceSeconds: Double
        let audioFile: String
    }

    private struct Pending {
        let started: Date
        var raw: String?
        var inferenceSeconds: Double?
    }

    private struct Latest {
        let evidence: MarkedFailure
        let directory: URL
        let expires: Date
    }

    private let files: FileManager
    private let root: URL
    private var pending: [URL: Pending] = [:]
    private var latest: Latest?

    init(root: URL? = nil, files: FileManager = .default) {
        self.files = files
        self.root = root ?? files.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Syll", isDirectory: true)
            .appendingPathComponent("FailureEvidence", isDirectory: true)
        try? pruneOrdinary(now: Date())
        try? pruneMarked(now: Date())
    }

    private var ordinaryDirectory: URL { root.appendingPathComponent("ordinary", isDirectory: true) }
    private var markedDirectory: URL { root.appendingPathComponent("marked", isDirectory: true) }

    private func secureDirectory(_ url: URL) throws {
        try files.createDirectory(at: url, withIntermediateDirectories: true,
                                  attributes: [.posixPermissions: 0o700])
        try files.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
    }

    private func secureFile(_ url: URL) throws {
        try files.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    func begin(audioURL: URL, at date: Date = Date()) {
        expire(now: date)
        pending[audioURL.standardizedFileURL] = Pending(started: date)
    }

    func captureRaw(audioURL: URL, text: String, inferenceSeconds: Double) {
        let key = audioURL.standardizedFileURL
        guard pending[key] != nil else { return }
        pending[key]?.raw = text
        pending[key]?.inferenceSeconds = inferenceSeconds
    }

    func discard(audioURL: URL) {
        pending.removeValue(forKey: audioURL.standardizedFileURL)
    }

    /// Call only after the completed record has saved, before cleanup can delete its audio.
    @discardableResult
    func stageCompleted(
        audioURL: URL, transcriptionID: UUID, timestamp: Date, finalText: String,
        model: String, audioDuration: Double, now: Date = Date()
    ) -> Bool {
        let key = audioURL.standardizedFileURL
        // A newly completed dictation supersedes the previous menu target even
        // if its evidence cannot be staged (for example, an oversized file).
        latest = nil
        guard let pending = pending.removeValue(forKey: key),
              let raw = pending.raw, let inference = pending.inferenceSeconds,
              !finalText.isEmpty, audioDuration > 0, inference >= 0,
              let size = try? key.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size > 0, size <= Self.maximumAudioBytes else { return false }
        let temporary = ordinaryDirectory.appendingPathComponent(transcriptionID.uuidString + ".tmp", isDirectory: true)
        let directory = ordinaryDirectory.appendingPathComponent(transcriptionID.uuidString, isDirectory: true)
        let target = temporary.appendingPathComponent("recording." + key.pathExtension)
        do {
            try secureDirectory(root)
            try secureDirectory(ordinaryDirectory)
            try secureDirectory(temporary)
            try files.copyItem(at: key, to: target)
            try secureFile(target)
        } catch {
            try? files.removeItem(at: temporary)
            return false
        }
        let evidence = MarkedFailure(
            schemaVersion: 1, transcriptionID: transcriptionID, timestamp: timestamp,
            rawRecognizerText: raw, finalText: finalText, model: model,
            recognitionPath: "local-fluid-audio-parakeet-v3-tdt",
            audioDurationSeconds: audioDuration, inferenceSeconds: inference,
            audioFile: target.lastPathComponent
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let metadata = temporary.appendingPathComponent("failure.json")
            try encoder.encode(evidence).write(to: metadata, options: .atomic)
            try secureFile(metadata)
            try files.moveItem(at: temporary, to: directory)
            try pruneOrdinary(now: now)
        } catch {
            try? files.removeItem(at: temporary)
            try? files.removeItem(at: directory)
            return false
        }
        latest = Latest(evidence: evidence, directory: directory, expires: now.addingTimeInterval(Self.markWindow))
        let id = transcriptionID
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.markWindow) { [weak self] in
            guard let self, self.latest?.evidence.transcriptionID == id else { return }
            self.expire(now: Date())
        }
        return true
    }

    var canMarkLatest: Bool {
        expire(now: Date())
        return latest != nil
    }

    func inferenceSeconds(for transcriptionID: UUID) -> Double? {
        guard latest?.evidence.transcriptionID == transcriptionID else { return nil }
        return latest?.evidence.inferenceSeconds
    }

    @discardableResult
    func markLatest(now: Date = Date()) throws -> UUID? {
        expire(now: now)
        guard let latest else { return nil }
        try secureDirectory(markedDirectory)
        let directory = markedDirectory.appendingPathComponent(latest.evidence.transcriptionID.uuidString, isDirectory: true)
        try files.moveItem(at: latest.directory, to: directory)
        self.latest = nil
        try pruneMarked(now: now)
        return latest.evidence.transcriptionID
    }

    func deleteAll() throws {
        pending.removeAll()
        latest = nil
        if files.fileExists(atPath: root.path) { try files.removeItem(at: root) }
    }

    func expire(now: Date) {
        guard let latest, now >= latest.expires else { return }
        self.latest = nil
    }

    func pruneOrdinary(now: Date) throws {
        guard files.fileExists(atPath: ordinaryDirectory.path) else { return }
        let directories = try files.contentsOfDirectory(at: ordinaryDirectory, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.hasDirectoryPath }
        let sorted = directories.sorted {
            let lhs = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let rhs = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return lhs > rhs
        }
        var retainedBytes: Int64 = 0
        for (index, directory) in sorted.enumerated() {
            let created = (try? directory.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let audio = (try? files.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey]))?
                .first { $0.lastPathComponent.hasPrefix("recording.") }
            let bytes = Int64((try? audio?.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            if directory.pathExtension == "tmp" || index >= Self.maximumOrdinaryCount
                || now.timeIntervalSince(created) > Self.ordinaryLifetime
                || retainedBytes + bytes > Self.maximumOrdinaryBytes {
                try files.removeItem(at: directory)
            } else {
                retainedBytes += bytes
            }
        }
    }

    func pruneMarked(now: Date) throws {
        guard files.fileExists(atPath: markedDirectory.path) else { return }
        let directories = try files.contentsOfDirectory(at: markedDirectory, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.hasDirectoryPath }
        let sorted = directories.sorted {
            let lhs = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let rhs = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return lhs > rhs
        }
        for (index, directory) in sorted.enumerated() {
            let created = (try? directory.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            if index >= Self.maximumMarkedCount || now.timeIntervalSince(created) > Self.markedLifetime {
                try files.removeItem(at: directory)
            }
        }
    }
}
