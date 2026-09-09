import Foundation

@main
struct SyllRecorderHUDPresentationPolicyTests {
    static func main() {
        UserDefaults.standard.set(true, forKey: "ShowLiveTranscript")
        defer { UserDefaults.standard.removeObject(forKey: "ShowLiveTranscript") }

        let ordinary = SyllRecorderHUDPresentationPolicy.ordinaryPhase1

        expect(
            !ordinary.shouldRenderTranscriptContent(
                isRecording: true,
                partialTranscript: "dictated words"
            ),
            "ordinary Phase 1 HUD must not render text when ShowLiveTranscript is persisted true"
        )
        expect(
            ordinary.transcriptContent(
                isRecording: true,
                partialTranscript: "dictated words"
            ) == "",
            "ordinary Phase 1 HUD must not pass dictated words to an assistant follow-up panel"
        )
        expect(
            !ordinary.shouldRenderTranscriptContent(
                isRecording: true,
                partialTranscript: "dictated words"
            ),
            "ordinary Phase 1 HUD remains state-only when the preference is false"
        )

        let diagnostic = SyllRecorderHUDPresentationPolicy.transcriptCapable(
            isLiveTranscriptPreferenceEnabled: true
        )
        expect(
            diagnostic.shouldRenderTranscriptContent(
                isRecording: true,
                partialTranscript: "diagnostic text"
            ),
            "the policy preserves an explicit nonordinary transcript-capable route"
        )

        print("Syll recorder HUD presentation policy tests passed")
    }

    private static func expect(_ condition: Bool, _ message: String) {
        guard condition else {
            fputs("FAIL: \(message)\n", stderr)
            exit(1)
        }
    }
}
