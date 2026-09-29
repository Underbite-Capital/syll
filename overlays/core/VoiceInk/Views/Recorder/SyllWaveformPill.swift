import SwiftUI

/// The ordinary recorder's visual surface. The caller decides when capture is active.
struct SyllWaveformPill: View {
    let audioMeterProvider: () -> AudioMeter

    private static let ordinaryOrange = Color(red: 1.0, green: 0.54, blue: 0.0)
    /// Restrained soft violet marking a Remember observation recording. The
    /// ordinary dictation accent is unchanged.
    static let rememberViolet = Color(red: 0.76, green: 0.65, blue: 0.95)

    /// Accent colour for the microphone dot and active waveform bars.
    /// Ordinary dictation must use the default.
    private let accent: Color
    private let accessibilityName: String

    init(
        audioMeterProvider: @escaping () -> AudioMeter,
        accent: Color = SyllWaveformPill.ordinaryOrange,
        accessibilityName: String = "Recording"
    ) {
        self.audioMeterProvider = audioMeterProvider
        self.accent = accent
        self.accessibilityName = accessibilityName
    }

    private let iceBlue = Color(red: 0.79, green: 0.93, blue: 1.0)
    private let barCount = 8
    private static let barHeights: [CGFloat] = [3.6, 5.2, 7.3, 9.9, 11.8, 10.2, 7.7, 4.7]
    private static let barThresholds: [Double] = [0.55, 0.34, 0.19, 0.06, 0.04, 0.17, 0.36, 0.58]

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { _ in
            let level = Self.meterLevel(audioMeterProvider())
            HStack(spacing: 5.85) {
                Circle()
                    .fill(accent.opacity(0.88))
                    .frame(width: 4.6, height: 4.6)
                    .shadow(color: accent.opacity(0.14), radius: 1)

                HStack(alignment: .center, spacing: 1.24) {
                    ForEach(0..<barCount, id: \.self) { index in
                        let activity = Self.barActivity(index: index, level: level)
                        ZStack {
                            Capsule()
                                .fill(iceBlue.opacity(0.82))
                                .frame(width: 1.4, height: Self.barHeights[index])
                            Capsule()
                                .fill(accent)
                                .frame(width: 1.4, height: Self.barHeights[index] * CGFloat(activity))
                                .opacity(min(1, activity * 1.4))
                        }
                        .frame(width: 1.4, height: 11.8)
                    }
                }
                .animation(.easeOut(duration: 0.12), value: level)
            }
            .padding(.horizontal, 11.8)
            .frame(width: 54, height: 17)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay { Capsule().fill(Color(red: 0.10, green: 0.14, blue: 0.19).opacity(0.52)) }
            }
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
            .accessibilityLabel(accessibilityName)
        }
    }

    static func meterLevel(_ meter: AudioMeter) -> Double {
        max(0, min(1, meter.averagePower * 0.7 + meter.peakPower * 0.3))
    }

    static func barActivity(index: Int, level: Double) -> Double {
        max(0, min(0.86, (level - barThresholds[index]) / 0.36))
    }
}
