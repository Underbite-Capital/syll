import SwiftUI

struct SyllMenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var engine: VoiceInkEngine
    @EnvironmentObject private var recorderUIManager: RecorderUIManager
    @EnvironmentObject private var menuBarManager: MenuBarManager
    @EnvironmentObject private var mainWindowNavigation: MainWindowNavigation
    @ObservedObject private var launchAtLoginManager = LaunchAtLoginManager.shared

    var body: some View {
        Button("Toggle Recorder") { recorderUIManager.handleToggleRecorderPanelNotification() }
        Divider()
        Button("Copy Last Transcription") { LastTranscriptionService.copyLastTranscription(from: engine.modelContext) }
        Button("Personal Dictionary…") { show(.dictionary) }
        Button("Setup…") { show(.dashboard) }
        Button("History…") { menuBarManager.openHistoryWindow() }
        Button("Advanced Settings…") { show(.settings) }
        Divider()
        Toggle("Launch at Login", isOn: Binding(get: { launchAtLoginManager.isEnabled }, set: { launchAtLoginManager.setEnabled($0) }))
            .disabled(launchAtLoginManager.isUpdating)
        Divider()
        Button("Quit Syll") { NSApplication.shared.terminate(nil) }
    }

    private func show(_ destination: ViewType) {
        mainWindowNavigation.navigate(to: destination)
        let existing = WindowManager.shared.currentMainWindow()
        menuBarManager.activateForPresentedWindow()
        if existing == nil {
            WindowManager.shared.prepareForUserRequestedMainWindow()
            openWindow(id: AppWindowID.main)
        } else {
            openWindow(id: AppWindowID.main)
            WindowManager.shared.showMainWindow()
        }
    }
}
