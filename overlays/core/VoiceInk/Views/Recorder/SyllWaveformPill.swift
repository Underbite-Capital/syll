import SwiftUI

/// The ordinary recorder's visual surface. The caller decides when capture is active.
struct SyllWaveformPill: View {
    let audioMeterProvider: () -> AudioMeter

    private let orange = Color(red: 1.0, green: 0.54, blue: 0.0)
    private let barCount = 8

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            let meter = audioMeterProvider()
            HStack(spacing: 7) {
                Circle()
                    .fill(orange)
                    .frame(width: 8, height: 8)
                    .shadow(color: orange.opacity(0.6), radius: 4)

                HStack(alignment: .center, spacing: 2) {
                    ForEach(0..<barCount, id: \.self) { index in
                        Capsule()
                            .fill(index > 5 ? Color.white.opacity(0.25) : orange)
                            .frame(width: 2, height: Self.barHeight(
                                index: index, average: meter.averagePower,
                                peak: meter.peakPower, time: timeline.date.timeIntervalSinceReferenceDate
                            ))
                    }
                }
                .frame(height: 16)
            }
            .padding(.horizontal, 9.5)
            .frame(width: 64, height: 22)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay { Capsule().fill(Color(red: 0.08, green: 0.08, blue: 0.08).opacity(0.8)) }
                    .overlay { Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 0.5) }
            }
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.22), radius: 5, y: 2)
            .accessibilityLabel("Recording")
        }
    }

    static func barHeight(index: Int, average: Double, peak: Double, time: TimeInterval) -> CGFloat {
        let level = max(0, min(1, average * 0.7 + peak * 0.3))
        let centre = 1 - abs(Double(index) - 3.5) / 5
        let pulse = 0.7 + 0.3 * sin(time * 11 + Double(index) * 0.75)
        return CGFloat(2 + level * centre * pulse * 15)
    }
}
