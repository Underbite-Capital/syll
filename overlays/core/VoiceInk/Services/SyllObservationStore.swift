import Foundation

/// Durable Remember observation store.
///
/// Observations are intentional user data, not diagnostics: this store has no
/// automatic expiry and is never touched by diagnostic deletion
/// (`SyllFailureEvidenceStore.deleteAll` / `SyllOperationalLog.deleteAll`
/// operate on their own roots). Each observation keeps the recognized
/// original text immutably; later correction and closeout review are additive
/// fields, so review never silently loses what David actually said.
///
/// Status model (lightweight, no task framework):
/// - "new": captured, no response yet.
/// - "reviewed": a response exists and nothing is outstanding.
/// - "awaitingDecision": a proposal or question is waiting on David.
/// - "unresolved": a concern that remains open after review.
/// - "addressed": David explicitly marked it addressed. An agent response
///   alone never marks an observation addressed.
///
/// Outstanding work for closeout = new + awaitingDecision + unresolved.
///
/// Failed captures keep their audio under `Failed/`, bounded to
/// `maximumFailedCount` entries (oldest pruned) and explicitly deletable.
/// This is not an indefinite audio archive.
@MainActor
final class SyllObservationStore: ObservableObject {
    static let shared = SyllObservationStore()

    static let maximumFailedCount = 20

    /// Emitted when the store changes so open views refresh.
    @Published private(set) var changeStamp = 0

    struct Review: Codable, Equatable, Sendable {
        let respondedAt: Date
        let responder: String
        let response: String
        /// "answered", "proposal", or "unresolved".
        let disposition: String
        /// The exact text the response reviewed. If the observation is
        /// corrected later, this keeps the response's relationship to the old
        /// wording explicit instead of silently attaching it to the new text.
        let basisText: String?
    }

    struct Observation: Codable, Equatable, Sendable, Identifiable {
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
        /// "new", "reviewed", "awaitingDecision", "unresolved", "addressed".
        var status: String
        var review: Review?

        /// The text a reader should see first.
        var displayText: String { correctedText ?? text }

        /// True when a correction changed the wording after the review was
        /// written, so the response must not read as reviewing the new text.
        var reviewPredatesCorrection: Bool {
            guard let basis = review?.basisText else { return false }
            return basis != displayText
        }

        var isOutstanding: Bool {
            status == "new" || status == "awaitingDecision" || status == "unresolved"
        }
    }

    struct Failure: Equatable, Sendable, Identifiable {
        let id: String
        let reason: String
        let failedAt: String
        let audioFile: String
    }

    struct Summary: Equatable, Sendable {
        let new: Int
        let awaitingDecision: Int
        let unresolved: Int
        let reviewed: Int
        let addressed: Int
        var outstanding: Int { new + awaitingDecision + unresolved }
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
        changeStamp += 1
        return observation
    }

    /// Keep the audio of a failed capture recoverable and visible on disk,
    /// bounded to the newest `maximumFailedCount` failures. Best effort:
    /// never throws, because this runs on an already-failed path.
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
        try? pruneFailures()
        changeStamp += 1
    }

    private func pruneFailures() throws {
        guard files.fileExists(atPath: failedDirectory.path) else { return }
        let notes = try files.contentsOfDirectory(
            at: failedDirectory, includingPropertiesForKeys: [.creationDateKey]
        ).filter { $0.pathExtension == "json" }
        let sorted = notes.sorted {
            let lhs = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let rhs = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return lhs == rhs ? $0.lastPathComponent > $1.lastPathComponent : lhs > rhs
        }
        for (index, note) in sorted.enumerated() where index >= Self.maximumFailedCount {
            let stem = note.deletingPathExtension().lastPathComponent
            try? files.removeItem(at: note)
            try? files.removeItem(at: failedDirectory.appendingPathComponent(stem + ".wav"))
        }
    }

    func failures() -> [Failure] {
        guard let urls = try? files.contentsOfDirectory(at: failedDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> Failure? in
                guard let data = try? Data(contentsOf: url),
                      let note = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                      let id = note["id"] else { return nil }
                return Failure(
                    id: id,
                    reason: note["reason"] ?? "Unknown reason",
                    failedAt: note["failedAt"] ?? "",
                    audioFile: note["audioFile"] ?? ""
                )
            }
            .sorted { $0.failedAt > $1.failedAt }
    }

    func deleteFailure(id: String) {
        try? files.removeItem(at: failedDirectory.appendingPathComponent(id + ".json"))
        try? files.removeItem(at: failedDirectory.appendingPathComponent(id + ".wav"))
        changeStamp += 1
    }

    /// Additive correction: the original recognized text is never rewritten.
    /// An existing review keeps its `basisText`, making any staleness visible.
    func correct(id: UUID, text: String, now: Date = Date()) throws {
        var observation = try load(id: id)
        observation.correctedText = text
        observation.correctedAt = now
        try write(observation)
        changeStamp += 1
    }

    /// Explicit human decision that an observation is handled. Review alone
    /// never sets this.
    func markAddressed(id: UUID) throws {
        var observation = try load(id: id)
        observation.status = "addressed"
        try write(observation)
        changeStamp += 1
    }

    /// Explicit removal of an observation and its audio.
    func delete(id: UUID) throws {
        let observation = try load(id: id)
        try files.removeItem(at: recordURL(for: id))
        try? files.removeItem(at: root.appendingPathComponent(observation.audioFile))
        changeStamp += 1
    }

    /// Counts by status. Failures are not counted; they were never saved
    /// observations.
    func summary() -> Summary {
        var new = 0, awaitingDecision = 0, unresolved = 0, reviewed = 0, addressed = 0
        for observation in all() {
            switch observation.status {
            case "new": new += 1
            case "awaitingDecision": awaitingDecision += 1
            case "unresolved": unresolved += 1
            case "addressed": addressed += 1
            default: reviewed += 1
            }
        }
        return Summary(new: new, awaitingDecision: awaitingDecision,
                       unresolved: unresolved, reviewed: reviewed, addressed: addressed)
    }

    /// Outstanding work for closeout: no response yet, awaiting David's
    /// decision, or still unresolved. Oldest first.
    func outstanding() -> [Observation] {
        all().filter { $0.isOutstanding }
    }

    /// All observations, oldest first, including reviewed and addressed.
    func allObservations() -> [Observation] { all() }

    func latest() -> Observation? { all().last }

    func load(id: UUID) throws -> Observation {
        let url = recordURL(for: id)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Observation.self, from: Data(contentsOf: url))
    }

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
