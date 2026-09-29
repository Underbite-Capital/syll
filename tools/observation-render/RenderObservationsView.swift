import AppKit
import SwiftUI

// Renders the actual SyllObservationsView product component against a sandbox
// store populated through the real store code paths (plus the bridge's review
// JSON shape). Render-only evidence: no app is launched and no live store is
// touched.
@main
struct RenderObservationsView {
    @MainActor
    static func main() throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("syll-obs-render-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let store = SyllObservationStore(root: root)
        let staging = root.appendingPathComponent("staging", isDirectory: true)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)

        func save(_ name: String, _ raw: String, _ text: String, minutesAgo: Double) throws -> SyllObservationStore.Observation {
            let audio = staging.appendingPathComponent(name)
            try Data([0x52, 0x49, 0x46, 0x46]).write(to: audio)
            return try store.save(
                audioURL: audio, originalText: raw, text: text,
                audioDurationSeconds: 2.4, model: "parakeet-tdt-0.6b-v3",
                now: Date().addingTimeInterval(-minutesAgo * 60))
        }

        func review(_ id: UUID, _ disposition: String, _ status: String, _ response: String, basis: String) throws {
            let recordURL = root.appendingPathComponent(id.uuidString + ".json")
            var json = try JSONSerialization.jsonObject(with: Data(contentsOf: recordURL)) as! [String: Any]
            json["review"] = [
                "respondedAt": ISO8601DateFormatter().string(from: Date()),
                "responder": "closeout-agent",
                "response": response,
                "disposition": disposition,
                "basisText": basis,
            ]
            json["status"] = status
            try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
                .write(to: recordURL, options: .atomic)
        }

        // New, unreviewed.
        _ = try save("a.wav", "the deploy pipeline feels fragile", "The deploy pipeline feels fragile.", minutesAgo: 12)
        // Proposal awaiting decision.
        let proposal = try save("b.wav", "maybe the closeout should group observations by project",
                                "Maybe the closeout should group observations by project.", minutesAgo: 90)
        try review(proposal.id, "proposal", "awaitingDecision",
                   "Grouping is reasonable but needs your decision before any closeout change.",
                   basis: "Maybe the closeout should group observations by project.")
        // Corrected after review: response predates the correction.
        let corrected = try save("c.wav", "i keep losing the first word on short dictations",
                                 "I keep losing the first word on short dictations.", minutesAgo: 200)
        try review(corrected.id, "unresolved", "unresolved",
                   "Confirmed against the corpus analysis; still open pending live evidence.",
                   basis: "I keep losing the first word on short dictations.")
        try store.correct(id: corrected.id, text: "I keep losing the first word on short dictations, especially in Cursor.")
        // Addressed.
        let done = try save("d.wav", "the menu bar icon looks right now", "The menu bar icon looks right now.", minutesAgo: 400)
        try review(done.id, "answered", "reviewed", "Noted; no action needed.", basis: "The menu bar icon looks right now.")
        try store.markAddressed(id: done.id)
        // One failed capture with retained audio.
        let failedAudio = staging.appendingPathComponent("failed.wav")
        try Data([0x52, 0x49, 0x46, 0x46]).write(to: failedAudio)
        store.recordFailure(audioURL: failedAudio, reason: "Nothing was recognized")

        try writePNG(
            SyllObservationsView(store: store).frame(width: 520, height: 640),
            to: directory.appendingPathComponent("observations-view.png")
        )
        print("Rendered the actual SyllObservationsView with synthetic data")
    }

    @MainActor
    private static func writePNG<Content: View>(_ content: Content, to url: URL) throws {
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Could not render the observations view")
        }
        try png.write(to: url)
    }
}
