import SwiftUI

struct MiniRecorderView<S: RecorderStateProvider & ObservableObject>: View {
    @ObservedObject var stateProvider: S
    @ObservedObject var recorder: Recorder
    @ObservedObject var assistantSession: AssistantSession
    let onRecordButtonTapped: () -> Void
    let onCloseTapped: () -> Void
    let onAssistantFollowUp: (String) -> Void
    private let presentationPolicy: SyllRecorderHUDPresentationPolicy = .ordinaryPhase1

    // MARK: - Layout Constants

    private let controlBarHeight: CGFloat = 40
    private let compactWidth: CGFloat = 144
    private let commandWidth: CGFloat = 420
    private let expandedWidth: CGFloat = 300
    private let assistantWidth: CGFloat = 520
    private let compactCornerRadius: CGFloat = 20
    private let expandedCornerRadius: CGFloat = 14

    private var hasLiveTranscript: Bool {
        presentationPolicy.shouldRenderTranscriptContent(
            isRecording: stateProvider.recordingState == .recording,
            partialTranscript: stateProvider.partialTranscript
        )
    }

    private var hasAssistantResponse: Bool {
        assistantSession.isVisible
    }

    private var hasCommandOutcome: Bool {
        stateProvider.commandOutcome != nil
    }

    private var shouldShowCloseButton: Bool {
        hasAssistantResponse && stateProvider.recordingState == .idle && !assistantSession.isBusy
    }

    private var liveAssistantFollowUpText: String {
        presentationPolicy.transcriptContent(
            isRecording: stateProvider.recordingState == .recording,
            partialTranscript: stateProvider.partialTranscript
        )
    }

    private var controlBar: some View {
        HStack(spacing: 8) {
            Group {
                if shouldShowCloseButton {
                    RecorderCloseButton(action: onCloseTapped)
                } else {
                    RecorderRecordButton(
                        recordingState: stateProvider.recordingState,
                        action: onRecordButtonTapped
                    )
                }
            }

            RecorderStatusDisplay(
                currentState: stateProvider.recordingState,
                audioMeterProvider: recorder.audioMeterSnapshot
            )
            .frame(maxWidth: .infinity)

            if stateProvider.isCommandMode {
                Image(systemName: "terminal")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 22)
                    .accessibilityLabel("Command Mode")
            } else {
                RecorderModeButton(
                    buttonSize: 22,
                    padding: EdgeInsets()
                )
            }
        }
        .padding(.horizontal, 8)
        .frame(height: controlBarHeight)
    }

    @ViewBuilder
    private var commandOutcomeSection: some View {
        if let outcome = stateProvider.commandOutcome {
            SyllCommandOutcomeView(outcome: outcome)

            Divider().background(Color.white.opacity(0.15))
        }
    }

    private var transcriptSection: some View {
        VStack(spacing: 0) {
            if hasLiveTranscript {
                LiveTranscriptView(text: stateProvider.partialTranscript)
                Divider().background(Color.white.opacity(0.15))
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if hasCommandOutcome {
                commandOutcomeSection
            } else if hasAssistantResponse {
                AssistantPanelView(
                    session: assistantSession,
                    liveFollowUpText: liveAssistantFollowUpText,
                    onSend: onAssistantFollowUp
                )
                Divider().background(Color.white.opacity(0.15))
            } else {
                transcriptSection
            }
            controlBar
        }
        .frame(
            width: hasCommandOutcome
                ? commandWidth
                : (hasAssistantResponse ? assistantWidth : (hasLiveTranscript ? expandedWidth : compactWidth))
        )
        .background(Color.black)
        .clipShape(
            RoundedRectangle(
                cornerRadius: hasLiveTranscript || hasAssistantResponse ? expandedCornerRadius : compactCornerRadius,
                style: .continuous
            )
        )
        .animation(.easeInOut(duration: 0.3), value: hasLiveTranscript)
        .animation(.easeInOut(duration: 0.3), value: hasAssistantResponse)
        .animation(.easeInOut(duration: 0.2), value: hasCommandOutcome)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}
