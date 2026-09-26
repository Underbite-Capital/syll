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
                    VStack(spacing: 16) {
                        Text("SYLL · \(background.uppercased()) CONTENT")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .tracking(1.2)
                        HStack(spacing: 10) {
                            ForEach(levels) { level in
                                VStack(spacing: 8) {
                                    Text(level.title)
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .tracking(0.8)
                                    Text("TRUE SIZE · 56 × 19 PT")
                                        .font(.system(size: 9, design: .rounded))
                                        .opacity(0.75)
                                    SyllWaveformPill(audioMeterProvider: { level.meter })
                                        .frame(width: 190, height: 40)
                                    Text("3× VIEW FOR DETAIL")
                                        .font(.system(size: 9, design: .rounded))
                                        .opacity(0.75)
                                    SyllWaveformPill(audioMeterProvider: { level.meter })
                                        .scaleEffect(3)
                                        .frame(width: 190, height: 84)
                                }
                                .frame(width: 190)
                            }
                        }
                    }
                    .foregroundStyle(labelColor)
                }
                .frame(width: 820, height: 240),
                to: directory.appendingPathComponent("states-\(background).png")
            )
        }

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
        print("Rendered the product view at four microphone levels over light and dark content")
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
