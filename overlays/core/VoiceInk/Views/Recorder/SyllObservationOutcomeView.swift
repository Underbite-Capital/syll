import SwiftUI

/// Result of a Remember observation capture, shown briefly in the recorder
/// panel. An observation is never pasted and never touches the clipboard;
/// this surface is how David sees that saving succeeded or failed.
struct SyllObservationOutcome: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case success
        case failure
    }

    let title: String
    let detail: String
    let kind: Kind
}

struct SyllObservationOutcomeView: View {
    let outcome: SyllObservationOutcome

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            line("Observation", outcome.title, kind: outcome.kind)
            line("Text", outcome.detail)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func line(_ label: String, _ value: String, kind: SyllObservationOutcome.Kind? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.48))
                .frame(width: 62, alignment: .trailing)
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color(kind))
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .accessibilityElement(children: .combine)
    }

    private func color(_ kind: SyllObservationOutcome.Kind?) -> AnyShapeStyle {
        switch kind {
        case .success:
            AnyShapeStyle(Color.green.opacity(0.9))
        case .failure:
            AnyShapeStyle(Color.red.opacity(0.9))
        case nil:
            AnyShapeStyle(Color.white.opacity(0.88))
        }
    }
}
