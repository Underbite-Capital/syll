import AppKit
import SwiftUI

@main
struct RenderSyllCommandHUD {
    @MainActor
    static func main() throws {
        let outcome = SyllCommandOutcome(
            heard: "kill port three thousand",
            interpreted: "kill-port(port: 3000)",
            result: "Stopped node (PID 4812); port 3000 is free",
            kind: .success
        )
        let view = VStack(spacing: 0) {
            SyllCommandOutcomeView(outcome: outcome)
            Divider().background(Color.white.opacity(0.15))
            HStack(spacing: 8) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 22, height: 22)
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Spacer()
                Image(systemName: "terminal")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 22)
            }
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 8)
            .frame(height: 40)
        }
        .frame(width: 420)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(20)
        .background(Color(red: 0.10, green: 0.11, blue: 0.13))

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.nsImage,
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let png = bitmap.representation(using: .png, properties: [:])
        else { fatalError("Could not render command HUD") }

        let destination = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "/tmp/syll-command-hud.png")
        try png.write(to: destination)
        print(destination.path)
    }
}
