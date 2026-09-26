import AppKit
import SwiftUI

// Only the recorder's meter value is substituted; the rendered view is the product source.
struct AudioMeter: Equatable {
    let averagePower: Double
    let peakPower: Double
}

@main
struct RenderIndicator {
    @MainActor
    static func main() throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for (name, meter) in [
            ("quiet", AudioMeter(averagePower: 0.07, peakPower: 0.12)),
            ("speaking", AudioMeter(averagePower: 0.67, peakPower: 0.82)),
        ] {
            let renderer = ImageRenderer(content:
                SyllWaveformPill(audioMeterProvider: { meter })
                    .frame(width: 210, height: 105)
                    .background(Color(red: 0.82, green: 0.84, blue: 0.88))
            )
            renderer.scale = 2
            guard let image = renderer.nsImage,
                  let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else {
                fatalError("Could not render the product waveform pill")
            }
            try png.write(to: directory.appendingPathComponent("\(name).png"))
        }
        let quiet = SyllWaveformPill.barHeight(index: 4, average: 0.07, peak: 0.12, time: 0)
        let speaking = SyllWaveformPill.barHeight(index: 4, average: 0.67, peak: 0.82, time: 0)
        precondition(speaking > quiet + 8, "microphone level must visibly drive the waveform")
        print("Rendered product waveform pill: quiet and speaking")
    }
}
