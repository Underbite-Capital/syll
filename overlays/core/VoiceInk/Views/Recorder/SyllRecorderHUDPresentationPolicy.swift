enum SyllRecorderHUDPresentationPolicy {
    /// The ordinary Phase 1 recorder is a transient state indicator, never a text display.
    case ordinaryPhase1

    /// Reserved for an explicitly invoked diagnostic or assistant surface, not the ordinary recorder.
    case transcriptCapable(isLiveTranscriptPreferenceEnabled: Bool)

    func shouldRenderTranscriptContent(
        isRecording: Bool,
        partialTranscript: String
    ) -> Bool {
        guard case let .transcriptCapable(isLiveTranscriptPreferenceEnabled) = self else { return false }
        return isLiveTranscriptPreferenceEnabled && isRecording && !partialTranscript.isEmpty
    }

    func transcriptContent(
        isRecording: Bool,
        partialTranscript: String
    ) -> String {
        guard shouldRenderTranscriptContent(
            isRecording: isRecording,
            partialTranscript: partialTranscript
        ) else {
            return ""
        }
        return partialTranscript
    }
}
