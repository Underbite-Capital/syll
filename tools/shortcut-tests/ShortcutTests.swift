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
        try await checkDoubleTap()
        try await checkHold()
        print("Fn shortcut tests passed: single tap, rapid double tap, and hold")
    }

    private static func makeHandler(
        visible: @escaping @MainActor () -> Bool,
        state: @escaping @MainActor () -> RecordingState,
        toggle: @escaping @MainActor (UUID?) async -> Void,
        command: @escaping @MainActor () -> Void
    ) -> RecordingShortcutModeHandler {
        RecordingShortcutModeHandler(
            canHandleShortcutAction: { true },
            isRecorderVisible: visible,
            recordingState: state,
            toggleRecorderPanel: toggle,
            latchCommandMode: command,
            cancelRecording: {}
        )
    }

    private static func checkSingleTap() async throws {
        var visible = false
        var toggles = 0
        var commands = 0
        let handler = makeHandler(
            visible: { visible }, state: { visible ? .recording : .idle },
            toggle: { _ in visible.toggle(); toggles += 1 },
            command: { commands += 1 }
        )
        await handler.handleKeyDown(action: .primaryRecording, eventTime: 1.0, mode: .hybrid)
        await handler.handleKeyUp(action: .primaryRecording, eventTime: 1.1, mode: .hybrid)
        try await Task.sleep(for: .milliseconds(650))
        precondition(!visible && toggles == 2 && commands == 0, "single tap changed")
    }

    private static func checkDoubleTap() async throws {
        var visible = false
        var toggles = 0
        var commands = 0
        let handler = makeHandler(
            visible: { visible }, state: { visible ? .recording : .idle },
            toggle: { _ in visible.toggle(); toggles += 1 },
            command: { commands += 1 }
        )
        await handler.handleKeyDown(action: .primaryRecording, eventTime: 1.0, mode: .hybrid)
        await handler.handleKeyUp(action: .primaryRecording, eventTime: 1.1, mode: .hybrid)
        await handler.handleKeyDown(action: .primaryRecording, eventTime: 1.2, mode: .hybrid)
        await handler.handleKeyUp(action: .primaryRecording, eventTime: 1.3, mode: .hybrid)
        try await Task.sleep(for: .milliseconds(650))
        precondition(!visible && toggles == 2 && commands == 0, "double tap entered a special mode")
    }

    private static func checkHold() async throws {
        var visible = false
        var toggles = 0
        var commands = 0
        let handler = makeHandler(
            visible: { visible }, state: { visible ? .recording : .idle },
            toggle: { _ in visible.toggle(); toggles += 1 },
            command: { commands += 1 }
        )
        await handler.handleKeyDown(action: .primaryRecording, eventTime: 1.0, mode: .hybrid)
        await handler.handleKeyUp(action: .primaryRecording, eventTime: 1.8, mode: .hybrid)
        precondition(!visible && toggles == 2 && commands == 0, "hold Fn changed")
    }
}
