import Foundation

/// Durable Remember observation store.
///
/// Observations are intentional user data, not diagnostics: this store has no
/// automatic expiry and is never touched by diagnostic deletion
/// (`SyllFailureEvidenceStore.deleteAll` / `SyllOperationalLog.deleteAll`
/// operate on their own roots). Each observation keeps the recognized
/// original text immutably; later correction and closeout review are additive
/// fields, so review never silently loses what David actually said.
@MainActor
final class SyllObservationStore {
    static let shared = SyllObservationStore()

    struct Review: Codable, Equatable, Sendable {
        let respondedAt: Date
        let responder: String
        let response: String
        /// "answered", "proposal", or "unresolved".
        let disposition: String
    }

    struct Observation: Codable, Equatable, Sendable {
        let schemaVersion: Int
        let id: UUID
        let createdAt: Date
        /// Recognized text at capture time, after output filtering only.
        /// Never rewritten after creation.
        let originalText: String
        /// Cleanup + personal-dictionary form shown to review.
        let text: String
        /// Optional later correction. `originalText` is always preserved.
        var correctedText: String?
        var correctedAt: Date?
        let audioFile: String
        let audioDurationSeconds: Double
        let model: String
        /// "new", "reviewed", or "unresolved".
        var status: String
        var review: Review?
    }

    struct Summary: Equatable, Sendable {
        let new: Int
        let unresolved: Int
        let reviewed: Int
        var awaitingReview: Int { new + unresolved }
    }

    private let files: FileManager
    let root: URL

    init(root: URL? = nil, files: FileManager = .default) {
        self.files = files
        self.root = root ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Syll", isDirectory: true)
            .appendingPathComponent("Observations", isDirectory: true)
    }

    private var failedDirectory: URL { root.appendingPathComponent("Failed", isDirectory: true) }

    private func secureDirectory(_ url: URL) throws {
        try files.createDirectory(at: url, withIntermediateDirectories: true,
                                  attributes: [.posixPermissions: 0o700])
        try files.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
    }

    private func secureFile(_ url: URL) throws {
        try files.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    /// Persist a completed observation. Moves the recorded audio beside its
    /// record so the observation stays verifiable and correctable. Throws if
    /// the observation could not be durably stored; the caller keeps the audio
    /// recoverable via `recordFailure`.
    @discardableResult
    func save(
        audioURL: URL,
        originalText: String,
        text: String,
        audioDurationSeconds: Double,
        model: String,
        now: Date = Date()
    ) throws -> Observation {
        let id = UUID()
        try secureDirectory(root)
        let audioTarget = root.appendingPathComponent(id.uuidString + ".wav")
        try files.moveItem(at: audioURL, to: audioTarget)
        try secureFile(audioTarget)
        let observation = Observation(
            schemaVersion: 1, id: id, createdAt: now,
            originalText: originalText, text: text,
            correctedText: nil, correctedAt: nil,
            audioFile: audioTarget.lastPathComponent,
            audioDurationSeconds: audioDurationSeconds,
            model: model, status: "new", review: nil
        )
        do {
            try write(observation)
        } catch {
            // The audio is already safely in the store; remove the partial
            // record target if any and report the failure.
            try? files.removeItem(at: recordURL(for: id))
            throw error
        }
        return observation
    }

    /// Keep the audio of a failed observation recoverable and visible on disk.
    /// Best effort: never throws, because this runs on an already-failed path.
    func recordFailure(audioURL: URL, reason: String, now: Date = Date()) {
        let id = UUID()
        try? secureDirectory(failedDirectory)
        let audioTarget = failedDirectory.appendingPathComponent(id.uuidString + ".wav")
        try? files.moveItem(at: audioURL, to: audioTarget)
        if files.fileExists(atPath: audioTarget.path) { try? secureFile(audioTarget) }
        let note: [String: String] = [
            "id": id.uuidString,
            "failedAt": ISO8601DateFormatter().string(from: now),
            "reason": reason,
            "audioFile": files.fileExists(atPath: audioTarget.path) ? audioTarget.lastPathComponent : "",
        ]
        if let data = try? JSONSerialization.data(withJSONObject: note, options: [.prettyPrinted, .sortedKeys]) {
            let noteURL = failedDirectory.appendingPathComponent(id.uuidString + ".json")
            try? data.write(to: noteURL, options: .atomic)
            if files.fileExists(atPath: noteURL.path) { try? secureFile(noteURL) }
        }
    }

    /// Counts by status. Observations in `Failed/` are not counted; they were
    /// never saved observations.
    func summary() -> Summary {
        var new = 0, unresolved = 0, reviewed = 0
        for observation in all() {
            switch observation.status {
            case "new": new += 1
            case "unresolved": unresolved += 1
            default: reviewed += 1
            }
        }
        return Summary(new: new, unresolved: unresolved, reviewed: reviewed)
    }

    /// New and unresolved observations, oldest first — the closeout contract.
    func awaitingReview() -> [Observation] {
        all().filter { $0.status == "new" || $0.status == "unresolved" }
    }

    func latest() -> Observation? { all().last }

    private func all() -> [Observation] {
        guard let urls = try? files.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(Observation.self, from: Data(contentsOf: $0)) }
            .sorted { $0.createdAt == $1.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.createdAt < $1.createdAt }
    }

    private func recordURL(for id: UUID) -> URL {
        root.appendingPathComponent(id.uuidString + ".json")
    }

    private func write(_ observation: Observation) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let url = recordURL(for: observation.id)
        try encoder.encode(observation).write(to: url, options: .atomic)
        try secureFile(url)
    }
}
