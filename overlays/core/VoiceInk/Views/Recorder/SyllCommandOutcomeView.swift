import SwiftUI

struct SyllCommandOutcomeView: View {
    let outcome: SyllCommandOutcome

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            commandLine("Heard", outcome.heard)
            commandLine("Interpreted", outcome.interpreted)
            commandLine("Result", outcome.result, resultKind: outcome.kind)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func commandLine(
        _ label: String,
        _ value: String,
        resultKind: SyllCommandOutcome.Kind? = nil
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.48))
                .frame(width: 62, alignment: .trailing)
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(commandColor(resultKind))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .accessibilityElement(children: .combine)
    }

    private func commandColor(_ kind: SyllCommandOutcome.Kind?) -> AnyShapeStyle {
        switch kind {
        case .success:
            AnyShapeStyle(Color.green.opacity(0.9))
        case .failure:
            AnyShapeStyle(Color.red.opacity(0.9))
        case .information, nil:
            AnyShapeStyle(Color.white.opacity(0.88))
        }
    }
}
