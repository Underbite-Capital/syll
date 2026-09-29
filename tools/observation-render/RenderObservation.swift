import AppKit
import SwiftUI

// Renders the actual product observation outcome views, plus the exact
// control-bar marker snippet from MiniRecorderView (which has too many app
// dependencies to render whole). No app is launched.
@main
struct RenderObservation {
    @MainActor
    static func main() throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let panelBackground = Color.black

        try writePNG(
            ZStack {
                panelBackground
                VStack(spacing: 0) {
                    SyllObservationOutcomeView(outcome: SyllObservationOutcome(
                        title: "Saved to observations",
                        detail: "The deploy pipeline feels fragile.",
                        kind: .success
                    ))
                    Divider().background(Color.white.opacity(0.15))
                    controlBar
                }
                .frame(width: 420)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .frame(width: 480, height: 160),
            to: directory.appendingPathComponent("observation-outcome-saved.png")
        )

        try writePNG(
            ZStack {
                panelBackground
                VStack(spacing: 0) {
                    SyllObservationOutcomeView(outcome: SyllObservationOutcome(
                        title: "Not saved",
                        detail: "Nothing recognized; audio kept in Observations/Failed",
                        kind: .failure
                    ))
                    Divider().background(Color.white.opacity(0.15))
                    controlBar
                }
                .frame(width: 420)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .frame(width: 480, height: 160),
            to: directory.appendingPathComponent("observation-outcome-failed.png")
        )

        try writePNG(
            ZStack {
                panelBackground
                controlBar
                    .frame(width: 300)
            }
            .frame(width: 340, height: 90),
            to: directory.appendingPathComponent("observation-recording-marker.png")
        )

        print("Rendered observation outcome views and the recording marker")
    }

    // Exact marker snippet from MiniRecorderView's control bar (isObservationMode branch).
    @ViewBuilder
    private static var controlBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red.opacity(0.85))
                .frame(width: 22, height: 22)
            Text("Recording observation…")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 4) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("Remember")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(0.92))
            .accessibilityLabel("Remember observation recording")
        }
        .padding(.horizontal, 8)
        .frame(height: 40)
    }

    @MainActor
    private static func writePNG<Content: View>(_ content: Content, to url: URL) throws {
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Could not render the observation views")
        }
        try png.write(to: url)
    }
}
