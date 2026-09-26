import AppKit
import SwiftUI

// Only the recorder's meter value is substituted; every pill is the product view.
struct AudioMeter: Equatable {
    let averagePower: Double
    let peakPower: Double
}

private struct LevelCase: Identifiable {
    let id: String
    let title: String
    let meter: AudioMeter
}

@main
struct RenderIndicator {
    private static let levels = [
        LevelCase(id: "near-silent", title: "NEAR-SILENT", meter: AudioMeter(averagePower: 0.01, peakPower: 0.03)),
        LevelCase(id: "quiet-speech", title: "QUIET SPEECH", meter: AudioMeter(averagePower: 0.18, peakPower: 0.27)),
        LevelCase(id: "ordinary-speech", title: "ORDINARY SPEECH", meter: AudioMeter(averagePower: 0.55, peakPower: 0.72)),
        LevelCase(id: "louder-speech", title: "LOUDER SPEECH", meter: AudioMeter(averagePower: 0.86, peakPower: 0.98)),
    ]

    @MainActor
    static func main() throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        for (background, color) in [
            ("light", Color(red: 0.91, green: 0.93, blue: 0.96)),
            ("dark", Color(red: 0.10, green: 0.12, blue: 0.16)),
        ] {
            let labelColor = background == "light" ? Color.black.opacity(0.65) : Color.white.opacity(0.72)
            for level in levels {
                try writePNG(
                    ZStack {
                        color
                        SyllWaveformPill(audioMeterProvider: { level.meter })
                    }
                    .frame(width: 210, height: 105),
                    to: directory.appendingPathComponent("\(level.id)-\(background).png")
                )
            }

            try writePNG(
                ZStack {
                    color
                    HStack(spacing: 10) {
                        ForEach(levels) { level in
                            VStack(spacing: 10) {
                                Text(level.title)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .tracking(0.8)
                                SyllWaveformPill(audioMeterProvider: { level.meter })
                                    .frame(width: 190, height: 40)
                            }
                            .frame(width: 190)
                        }
                    }
                    .foregroundStyle(labelColor)
                }
                .frame(width: 820, height: 105),
                to: directory.appendingPathComponent("states-\(background).png")
            )

            try writePNG(
                ZStack {
                    color
                    HStack(spacing: 10) {
                        ForEach(levels) { level in
                            VStack(spacing: 15) {
                                Text(level.title)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .tracking(0.8)
                                SyllWaveformPill(audioMeterProvider: { level.meter })
                                    .scaleEffect(3.5)
                                    .frame(width: 190, height: 75)
                            }
                            .frame(width: 190)
                        }
                    }
                    .foregroundStyle(labelColor)
                }
                .frame(width: 820, height: 160),
                to: directory.appendingPathComponent("detail-\(background).png")
            )
        }

        let comparisonMeter = levels[2].meter
        try writePNG(
            ZStack {
                Color(red: 0.91, green: 0.93, blue: 0.96)
                HStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Text("BUILD 242 · REJECTED")
                        SyllWaveformPill242(audioMeterProvider: { comparisonMeter })
                            .frame(width: 190, height: 36)
                        Text("64 × 22 PT")
                    }
                    VStack(spacing: 8) {
                        Text("2977DA0 · REJECTED")
                        SyllWaveformPill2977(audioMeterProvider: { comparisonMeter })
                            .frame(width: 190, height: 36)
                        Text("56 × 19 PT")
                    }
                    VStack(spacing: 8) {
                        Text("THIN EXPLORATION")
                        SyllWaveformPill(audioMeterProvider: { comparisonMeter })
                            .frame(width: 190, height: 36)
                        Text("48 × 15 PT")
                    }
                }
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.65))
            }
            .frame(width: 630, height: 112),
            to: directory.appendingPathComponent("comparison-true-size.png")
        )

        try writePNG(
            ZStack {
                LinearGradient(
                    colors: [.indigo, .orange, .blue, .purple],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                SyllWaveformPill(audioMeterProvider: { levels[2].meter })
            }
            .frame(width: 210, height: 105),
            to: directory.appendingPathComponent("ordinary-speech-busy.png")
        )

        let silent = SyllWaveformPill.meterLevel(levels[0].meter)
        let loud = SyllWaveformPill.meterLevel(levels[3].meter)
        precondition(SyllWaveformPill.barActivity(index: 0, level: silent) == 0)
        precondition(SyllWaveformPill.barActivity(index: 7, level: loud) > 0)
        print("Rendered four actual-view levels, enlarged details, and exact historical size comparison")
    }

    @MainActor
    private static func writePNG<Content: View>(_ content: Content, to url: URL) throws {
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Could not render the product waveform pill")
        }
        try png.write(to: url)
    }
}
