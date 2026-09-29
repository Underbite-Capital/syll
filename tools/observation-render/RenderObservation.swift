import AppKit
import SwiftUI

// Stub matching the product's AudioMeter shape; only the meter value is
// substituted, every pill is the product view.
struct AudioMeter: Equatable {
    let averagePower: Double
    let peakPower: Double
}

// Renders the actual product observation outcome views and the actual
// ordinary/Remember waveform pills side by side. The control-bar chrome under
// the outcome views is a stand-in for upstream components. No app is launched.
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
            to: directory.appendingPathComponent("observation-outcome-chrome.png")
        )

        // Side-by-side: the actual ordinary pill and the actual Remember pill,
        // same component, same size, on both background classes.
        for (background, color) in [
            ("light", Color(red: 0.91, green: 0.93, blue: 0.96)),
            ("dark", Color(red: 0.10, green: 0.12, blue: 0.16)),
        ] {
            let labelColor = background == "light" ? Color.black.opacity(0.65) : Color.white.opacity(0.72)
            try writePNG(
                ZStack {
                    color
                    HStack(spacing: 16) {
                        ForEach(levels) { level in
                            VStack(spacing: 8) {
                                Text(level.title)
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .tracking(0.8)
                                HStack(spacing: 12) {
                                    SyllWaveformPill(audioMeterProvider: { level.meter })
                                    SyllWaveformPill(
                                        audioMeterProvider: { level.meter },
                                        accent: SyllWaveformPill.rememberViolet,
                                        accessibilityName: "Recording observation"
                                    )
                                }
                                HStack(spacing: 12) {
                                    Text("DICTATION").frame(width: 54)
                                    Text("REMEMBER").frame(width: 54)
                                }
                                .font(.system(size: 7, weight: .medium, design: .rounded))
                            }
                        }
                    }
                    .foregroundStyle(labelColor)
                }
                .frame(width: 700, height: 110),
                to: directory.appendingPathComponent("pill-ordinary-vs-remember-\(background).png")
            )
        }

        print("Rendered observation outcome views and the ordinary/Remember pill comparison")
    }

    private struct LevelCase: Identifiable {
        let id: String
        let title: String
        let meter: AudioMeter
    }

    private static let levels = [
        LevelCase(id: "near-silent", title: "NEAR-SILENT", meter: AudioMeter(averagePower: 0.01, peakPower: 0.03)),
        LevelCase(id: "quiet-speech", title: "QUIET SPEECH", meter: AudioMeter(averagePower: 0.18, peakPower: 0.27)),
        LevelCase(id: "ordinary-speech", title: "ORDINARY SPEECH", meter: AudioMeter(averagePower: 0.55, peakPower: 0.72)),
        LevelCase(id: "louder-speech", title: "LOUDER SPEECH", meter: AudioMeter(averagePower: 0.86, peakPower: 0.98)),
    ]

    // Stand-in chrome for the upstream control bar shown under outcome views.
    // The Remember recording marker no longer exists; outcomes use the
    // ordinary control bar.
    @ViewBuilder
    private static var controlBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red.opacity(0.85))
                .frame(width: 22, height: 22)
            Text("Observation saved")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
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
