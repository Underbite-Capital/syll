import SwiftUI

/// The ordinary recorder's visual surface. The caller decides when capture is active.
struct SyllWaveformPill: View {
    let audioMeterProvider: () -> AudioMeter

    private let orange = Color(red: 1.0, green: 0.43, blue: 0.12)
    private let barCount = 9

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            let meter = audioMeterProvider()
            HStack(spacing: 15) {
                Circle()
                    .fill(orange)
                    .frame(width: 15, height: 15)
                    .shadow(color: orange.opacity(0.75), radius: 9)

                HStack(alignment: .center, spacing: 4) {
                    ForEach(0..<barCount, id: \.self) { index in
                        Capsule()
                            .fill(orange.opacity(index > 6 ? 0.65 : 1))
                            .frame(width: 4, height: Self.barHeight(
                                index: index, average: meter.averagePower,
                                peak: meter.peakPower, time: timeline.date.timeIntervalSinceReferenceDate
                            ))
                    }
                }
                .frame(height: 27)
            }
            .padding(.horizontal, 17)
            .frame(width: 138, height: 43)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay { Capsule().fill(Color(red: 0.08, green: 0.09, blue: 0.11).opacity(0.85)) }
                    .overlay { Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 0.7) }
            }
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.28), radius: 12, y: 5)
            .accessibilityLabel("Recording")
        }
    }

    static func barHeight(index: Int, average: Double, peak: Double, time: TimeInterval) -> CGFloat {
        let level = max(0, min(1, average * 0.7 + peak * 0.3))
        let centre = 1 - abs(Double(index) - 4) / 6
        let pulse = 0.7 + 0.3 * sin(time * 11 + Double(index) * 0.75)
        return CGFloat(4 + level * centre * pulse * 23)
    }
}
