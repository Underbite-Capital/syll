import Foundation

// Protocol for objects that provide live recorder state to the UI.
@MainActor
protocol RecorderStateProvider: AnyObject {
    var recordingState: RecordingState { get }
    var partialTranscript: String { get }
    var isCommandMode: Bool { get }
    var commandOutcome: SyllCommandOutcome? { get }
}
