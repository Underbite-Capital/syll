import SwiftUI

struct SyllControlView: View {
    @EnvironmentObject private var navigation: MainWindowNavigation
    @EnvironmentObject private var recordingShortcutManager: RecordingShortcutManager
    @ObservedObject private var audioDeviceManager = AudioDeviceManager.shared

    var body: some View {
        Group {
            switch navigation.selectedView {
            case .dictionary: DictionarySettingsView()
            case .settings: SettingsView()
            case .history: InlineHistoryView()
            case .audio: AudioSetupView()
            default: setup
            }
        }
        .frame(width: 720)
        .frame(minHeight: 520)
        .background(AppTheme.Surface.window)
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 22) {
            AppScreenHeader(title: "Set up Syll")
            setupCard(title: "Dictation shortcut", detail: "Hold Fn / Globe, speak, then release. Double-tap to lock; tap once to finish.") {
                HStack {
                    Text("Current shortcut")
                    Spacer()
                    ShortcutRecorder(action: .primaryRecording) {
                        recordingShortcutManager.primaryRecordingShortcut = .custom
                        recordingShortcutManager.updateShortcutStatus()
                    }.controlSize(.small)
                }
            }
            setupCard(title: "Microphone", detail: "Choose the input Syll should use for dictation.") {
                Picker("Audio input", selection: Binding(
                    get: { audioDeviceManager.getCurrentDevice() ?? 0 },
                    set: { audioDeviceManager.selectDeviceAndSwitchToCustomMode(id: $0) }
                )) {
                    ForEach(audioDeviceManager.availableDevices, id: \.id) { device in Text(device.name).tag(device.id) }
                }.labelsHidden().frame(maxWidth: 320)
            }
            setupCard(title: "Personal Dictionary", detail: "Teach Syll preferred spellings and optional spoken aliases.") {
                Button("Open Personal Dictionary") { navigation.navigate(to: .dictionary) }
            }
            Text("Accessibility is not required to detect the Fn shortcut. It may still be needed for cursor insertion in apps that do not accept the standard paste path.")
                .font(.footnote).foregroundStyle(.secondary).padding(.horizontal, 24)
            Spacer()
        }.padding(.bottom, 24)
    }

    private func setupCard<Content: View>(title: LocalizedStringKey, detail: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
            content()
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.Surface.card))
            .padding(.horizontal, 24)
    }
}
