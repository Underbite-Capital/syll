import AppKit
import SwiftUI

/// Compact native Remember observations surface: chronological observations
/// with full text, the linked review response and whether a decision remains
/// outstanding, correction that preserves the original, explicit
/// "Mark addressed" and removal, and visible failed captures.
struct SyllObservationsView: View {
    @ObservedObject var store: SyllObservationStore

    @State private var correctingID: UUID?
    @State private var correctionDraft = ""
    @State private var deletionCandidate: SyllObservationStore.Observation?

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            let observations = store.allObservations()
            let outstanding = observations.filter { $0.isOutstanding }
            let earlier = observations.filter { !$0.isOutstanding }
            let failures = store.failures()

            if observations.isEmpty && failures.isEmpty {
                ContentUnavailableView(
                    "No Observations",
                    systemImage: "book.closed",
                    description: Text("Double-tap Fn and speak to capture an observation.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if !outstanding.isEmpty {
                        Section("Awaiting review or decision") {
                            ForEach(outstanding) { observationRow($0) }
                        }
                    }
                    if !earlier.isEmpty {
                        Section("Earlier") {
                            ForEach(earlier.reversed()) { observationRow($0) }
                        }
                    }
                    if !failures.isEmpty {
                        Section("Failed captures (audio kept, bounded)") {
                            ForEach(failures) { failure in
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(failure.reason)
                                            .font(.system(size: 12))
                                        Text(failure.failedAt)
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button("Delete") { store.deleteFailure(id: failure.id) }
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 460, minHeight: 320)
        .alert("Delete this observation?", presenting: deletionCandidate) { candidate in
            Button("Delete", role: .destructive) {
                try? store.delete(id: candidate.id)
                deletionCandidate = nil
            }
            Button("Cancel", role: .cancel) { deletionCandidate = nil }
        } message: { candidate in
            Text("This permanently removes the observation and its audio. The original text cannot be recovered.")
        }
    }

    @ViewBuilder
    private func observationRow(_ observation: SyllObservationStore.Observation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(Self.timestampFormatter.string(from: observation.createdAt))
                    .font(.system(size: 11, weight: .medium))
                statusLabel(observation)
                Spacer()
            }

            if correctingID == observation.id {
                TextEditor(text: $correctionDraft)
                    .font(.system(size: 12))
                    .frame(minHeight: 56)
                    .border(Color.secondary.opacity(0.3))
                HStack(spacing: 8) {
                    Button("Save Correction") {
                        let text = correctionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !text.isEmpty {
                            try? store.correct(id: observation.id, text: text)
                        }
                        correctingID = nil
                    }
                    Button("Cancel") { correctingID = nil }
                }
            } else {
                Text(observation.displayText)
                    .font(.system(size: 12))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if observation.correctedText != nil {
                Text("Original: \(observation.originalText)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let review = observation.review {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(dispositionLabel(review.disposition))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(dispositionColor(review.disposition))
                        Text(review.responder)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Text(review.response)
                        .font(.system(size: 11))
                        .foregroundStyle(.primary.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                    if observation.reviewPredatesCorrection {
                        Text("This response reviewed earlier wording; the observation was corrected afterwards.")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            HStack(spacing: 12) {
                if correctingID != observation.id {
                    Button("Correct…") {
                        correctionDraft = observation.displayText
                        correctingID = observation.id
                    }
                }
                if observation.status != "addressed" {
                    Button("Mark Addressed") { try? store.markAddressed(id: observation.id) }
                }
                Button("Delete…") { deletionCandidate = observation }
            }
            .font(.system(size: 11))
        }
        .padding(.vertical, 4)
    }

    private func statusLabel(_ observation: SyllObservationStore.Observation) -> some View {
        let (text, color): (String, Color) = {
            switch observation.status {
            case "new": return ("Awaiting review", .secondary)
            case "awaitingDecision": return ("Decision outstanding", .orange)
            case "unresolved": return ("Unresolved", .red)
            case "addressed": return ("Addressed", .green)
            default: return ("Reviewed", .secondary)
            }
        }()
        return Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
    }

    private func dispositionLabel(_ disposition: String) -> String {
        switch disposition {
        case "answered": return "Answered"
        case "proposal": return "Proposal — awaiting your decision"
        case "unresolved": return "Unresolved"
        default: return disposition
        }
    }

    private func dispositionColor(_ disposition: String) -> Color {
        switch disposition {
        case "answered": return .green
        case "proposal": return .orange
        case "unresolved": return .red
        default: return .secondary
        }
    }
}

/// Hosts the observations view in a compact native window. The window is
/// created on demand and reused; closing it does not affect capture.
@MainActor
final class SyllObservationWindowController {
    static let shared = SyllObservationWindowController()

    private var window: NSWindow?

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = SyllObservationsView(store: SyllObservationStore.shared)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Observations"
        window.contentView = NSHostingView(rootView: view)
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
