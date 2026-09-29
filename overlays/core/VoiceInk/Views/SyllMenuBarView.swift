import SwiftUI

struct SyllMenuBarView: View {
    @Environment(\.openSettings) private var openSettings
    @EnvironmentObject private var engine: VoiceInkEngine
    @EnvironmentObject private var recorderUIManager: RecorderUIManager
    @EnvironmentObject private var menuBarManager: MenuBarManager
    @EnvironmentObject private var mainWindowNavigation: MainWindowNavigation
    @ObservedObject private var launchAtLoginManager = LaunchAtLoginManager.shared

    var body: some View {
        Button("Copy Last Transcription") { LastTranscriptionService.copyLastTranscription(from: engine.modelContext) }
        Button("Reset Clipboard") { resetClipboard() }
        Button("Personal Dictionary…") { show(.dictionary) }
        Menu("Observations") {
            Text(observationStatusLine)
            Button("Open Observations…") { SyllObservationWindowController.shared.show() }
            Divider()
            Button("Copy Outstanding Observations") { copyOutstandingObservations() }
            Button("Reveal Observations Folder") { revealObservations() }
        }
        Toggle("Launch at Login", isOn: Binding(get: { launchAtLoginManager.isEnabled }, set: { launchAtLoginManager.setEnabled($0) }))
            .disabled(launchAtLoginManager.isUpdating)
        Divider()
        Menu("Diagnostics") {
            Button("Mark Last Transcription as Wrong") { markLastWrong() }
            Button("Delete All Local Diagnostic Evidence…") { deleteDiagnostics() }
        }
        Button("Quit Syll") { NSApplication.shared.terminate(nil) }
    }

    private func resetClipboard() {
        let title: String
        let type: AppNotificationView.NotificationType
        switch CursorPaster.resetClipboard() {
        case .restoredPrevious:
            title = "Previous clipboard restored"
            type = .success
        case .clipboardChangedElsewhere:
            title = "Clipboard already changed; nothing overwritten"
            type = .info
        case .noSyllPaste:
            title = "No Syll clipboard state to reset"
            type = .info
        }
        NotificationManager.shared.showNotification(title: title, type: type)
    }

    private func markLastWrong() {
        do {
            if try SyllFailureEvidenceStore.shared.markLatest() != nil {
                NotificationManager.shared.showNotification(title: "Failure saved for diagnostics", type: .success)
            } else {
                NotificationManager.shared.showNotification(title: "No recent transcription available to mark", type: .error)
            }
        } catch {
            NotificationManager.shared.showNotification(title: "Could not save failure evidence", type: .error)
        }
    }

    private func deleteDiagnostics() {
        let confirmation = NSAlert()
        confirmation.messageText = "Delete all local diagnostic evidence?"
        confirmation.informativeText = "This permanently removes saved failure audio, transcripts, and operational timing records from this Mac."
        confirmation.addButton(withTitle: "Delete All")
        confirmation.addButton(withTitle: "Cancel")
        guard confirmation.runModal() == .alertFirstButtonReturn else { return }
        do {
            try SyllFailureEvidenceStore.shared.deleteAll()
            try SyllOperationalLog.shared.deleteAll()
            NotificationManager.shared.showNotification(title: "Local diagnostic evidence deleted", type: .success)
        } catch {
            NotificationManager.shared.showNotification(title: "Could not delete all diagnostic evidence", type: .error)
        }
    }

    private var observationStatusLine: String {
        let summary = SyllObservationStore.shared.summary()
        if summary.outstanding == 0 {
            return "No outstanding observations"
        }
        return "\(summary.outstanding) outstanding observation\(summary.outstanding == 1 ? "" : "s")"
    }

    /// Manual retrieval fallback: copies outstanding observations only when
    /// David explicitly asks. Capture itself never touches the clipboard.
    private func copyOutstandingObservations() {
        let pending = SyllObservationStore.shared.outstanding()
        guard !pending.isEmpty else {
            NotificationManager.shared.showNotification(title: "No outstanding observations", type: .info)
            return
        }
        let formatter = ISO8601DateFormatter()
        let text = pending.map { observation in
            "[\(formatter.string(from: observation.createdAt))] \(observation.id.uuidString)\n\(observation.displayText)"
        }.joined(separator: "\n\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        NotificationManager.shared.showNotification(
            title: "Copied \(pending.count) observation\(pending.count == 1 ? "" : "s")",
            type: .success
        )
    }

    private func revealObservations() {
        NSWorkspace.shared.open(SyllObservationStore.shared.root)
    }

    private func show(_ destination: ViewType) {
        mainWindowNavigation.navigate(to: destination)
        menuBarManager.activateForPresentedWindow()
        openSettings()
    }
}
