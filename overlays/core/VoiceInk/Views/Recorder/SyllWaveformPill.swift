import SwiftUI

/// The ordinary recorder's visual surface. The caller decides when capture is active.
struct SyllWaveformPill: View {
    let audioMeterProvider: () -> AudioMeter

    private let orange = Color(red: 1.0, green: 0.54, blue: 0.0)
    private let barCount = 8
    private static let barHeights: [CGFloat] = [3.5, 5, 8, 10.5, 12, 9, 6, 4.5]
    private static let barThresholds: [Double] = [0.05, 0.13, 0.22, 0.32, 0.43, 0.55, 0.68, 0.81]

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { _ in
            let level = Self.meterLevel(audioMeterProvider())
            HStack(spacing: 6) {
                Circle()
                    .fill(orange.opacity(0.92))
                    .frame(width: 5.5, height: 5.5)
                    .shadow(color: orange.opacity(0.25), radius: 2)

                HStack(alignment: .center, spacing: 1.4) {
                    ForEach(0..<barCount, id: \.self) { index in
                        let activity = Self.barActivity(index: index, level: level)
                        ZStack {
                            Capsule()
                                .fill(.white.opacity(0.30))
                                .frame(width: 1.6, height: Self.barHeights[index])
                            Capsule()
                                .fill(orange)
                                .frame(width: 1.6, height: Self.barHeights[index] * CGFloat(activity))
                                .opacity(activity)
                        }
                        .frame(width: 1.6, height: 12)
                    }
                }
                .animation(.easeOut(duration: 0.12), value: level)
            }
            .padding(.horizontal, 11)
            .frame(width: 56, height: 19)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay { Capsule().fill(Color(red: 0.09, green: 0.10, blue: 0.12).opacity(0.68)) }
            }
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.14), radius: 3, y: 1)
            .accessibilityLabel("Recording")
        }
    }

    static func meterLevel(_ meter: AudioMeter) -> Double {
        max(0, min(1, meter.averagePower * 0.7 + meter.peakPower * 0.3))
    }

    static func barActivity(index: Int, level: Double) -> Double {
        max(0, min(1, (level - barThresholds[index]) / 0.16))
    }
}
