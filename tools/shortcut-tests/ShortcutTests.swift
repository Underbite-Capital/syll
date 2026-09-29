import Foundation

enum RecordingState { case idle, recording }
enum ShortcutAction { case primaryRecording }
enum RecordingShortcutManager {
    enum Mode { case toggle, pushToTalk, hybrid }
}
final class SyllOperationalLog {
    static let shared = SyllOperationalLog()
    func shortcutDown() {}
}

@MainActor
@main
struct ShortcutTests {
    static func main() async throws {
        try await checkSingleTap()
        try await checkDoubleTapLatchesObservation()
        try await checkDoubleTapFallsBackWhenLatchUnavailable()
        try await checkHold()
        print("Fn shortcut tests passed: single tap, double tap observation latch, latch fallback, and hold")
    }

    private static func makeHandler(
        visible: @escaping @MainActor () -> Bool,
        state: @escaping @MainActor () -> RecordingState,
        toggle: @escaping @MainActor (UUID?) async -> Void,
        command: @escaping @MainActor () -> Void,
        observation: @escaping @MainActor () -> Bool
    ) -> RecordingShortcutModeHandler {
        RecordingShortcutModeHandler(
            canHandleShortcutAction: { true },
            isRecorderVisible: visible,
            recordingState: state,
            toggleRecorderPanel: toggle,
            latchCommandMode: command,
            latchObservationMode: observation,
            cancelRecording: {}
        )
    }

    private static func checkSingleTap() async throws {
        var visible = false
        var toggles = 0
        var commands = 0
        var observations = 0
        let handler = makeHandler(
            visible: { visible }, state: { visible ? .recording : .idle },
            toggle: { _ in visible.toggle(); toggles += 1 },
            command: { commands += 1 },
            observation: { observations += 1; return true }
        )
        await handler.handleKeyDown(action: .primaryRecording, eventTime: 1.0, mode: .hybrid)
        await handler.handleKeyUp(action: .primaryRecording, eventTime: 1.1, mode: .hybrid)
        try await Task.sleep(for: .milliseconds(650))
        precondition(!visible && toggles == 2 && commands == 0 && observations == 0, "single tap changed")
    }

    /// Double-tap Fn latches Remember observation capture onto the recording the
    /// first tap started; the second tap must not toggle ordinary handling, and
    /// a later tap finishes the hands-free observation session.
    private static func checkDoubleTapLatchesObservation() async throws {
        var visible = false
        var toggles = 0
        var commands = 0
        var observations = 0
        let handler = makeHandler(
            visible: { visible }, state: { visible ? .recording : .idle },
            toggle: { _ in visible.toggle(); toggles += 1 },
            command: { commands += 1 },
            observation: { observations += 1; return true }
        )
        await handler.handleKeyDown(action: .primaryRecording, eventTime: 1.0, mode: .hybrid)
        await handler.handleKeyUp(action: .primaryRecording, eventTime: 1.1, mode: .hybrid)
        await handler.handleKeyDown(action: .primaryRecording, eventTime: 1.2, mode: .hybrid)
        await handler.handleKeyUp(action: .primaryRecording, eventTime: 1.3, mode: .hybrid)
        try await Task.sleep(for: .milliseconds(650))
        precondition(visible && toggles == 1 && commands == 0 && observations == 1,
                     "double tap did not latch a hands-free observation session")
        // A later tap finishes the observation recording.
        await handler.handleKeyDown(action: .primaryRecording, eventTime: 5.0, mode: .hybrid)
        await handler.handleKeyUp(action: .primaryRecording, eventTime: 5.1, mode: .hybrid)
        try await Task.sleep(for: .milliseconds(650))
        precondition(!visible && toggles == 2 && commands == 0 && observations == 1,
                     "later tap did not finish the observation session")
    }

    /// When no eligible ordinary session is in flight, a double tap keeps the
    /// previous ordinary behavior instead of forcing observation capture.
    private static func checkDoubleTapFallsBackWhenLatchUnavailable() async throws {
        var visible = false
        var toggles = 0
        var commands = 0
        var observations = 0
        let handler = makeHandler(
            visible: { visible }, state: { visible ? .recording : .idle },
            toggle: { _ in visible.toggle(); toggles += 1 },
            command: { commands += 1 },
            observation: { observations += 1; return false }
        )
        await handler.handleKeyDown(action: .primaryRecording, eventTime: 1.0, mode: .hybrid)
        await handler.handleKeyUp(action: .primaryRecording, eventTime: 1.1, mode: .hybrid)
        await handler.handleKeyDown(action: .primaryRecording, eventTime: 1.2, mode: .hybrid)
        await handler.handleKeyUp(action: .primaryRecording, eventTime: 1.3, mode: .hybrid)
        try await Task.sleep(for: .milliseconds(650))
        precondition(!visible && toggles == 2 && commands == 0 && observations == 1,
                     "double tap without an eligible session changed ordinary handling")
    }

    private static func checkHold() async throws {
        var visible = false
        var toggles = 0
        var commands = 0
        var observations = 0
        let handler = makeHandler(
            visible: { visible }, state: { visible ? .recording : .idle },
            toggle: { _ in visible.toggle(); toggles += 1 },
            command: { commands += 1 },
            observation: { observations += 1; return true }
        )
        await handler.handleKeyDown(action: .primaryRecording, eventTime: 1.0, mode: .hybrid)
        await handler.handleKeyUp(action: .primaryRecording, eventTime: 1.8, mode: .hybrid)
        precondition(!visible && toggles == 2 && commands == 0 && observations == 0, "hold Fn changed")
    }
}
