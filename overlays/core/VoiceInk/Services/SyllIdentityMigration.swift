import Foundation

enum SyllIdentityMigration {
    static let currentVersion = 2
    static let versionKey = "SyllIdentityMigrationVersion"
    static let legacySuiteName = "com.prakashjoshipax.VoiceInk"

    private static let scalarKeys: Set<String> = [
        "AIProvider", "SelectedTranscriptionProvider", "SelectedTranscriptionModel",
        "SelectedLanguage", "SelectedAudioDeviceID", "RecorderType", "ShowLiveTranscript",
        "primaryRecordingShortcut", "primaryRecordingShortcutMode",
        "secondaryRecordingShortcut", "secondaryRecordingShortcutMode", "IsMenuBarOnly",
        "restoreClipboardAfterPaste", "clipboardRestoreDelay", "AppendTrailingSpace",
        "IsTextFormattingEnabled", "IsVADEnabled", "PersonalDictionaryCorrectionsEnabled",
        "PersonalDictionaryRecognitionCache", "PersonalDictionaryRecognitionCacheRevision",
        "hasCompletedOnboardingV2", "hasPreparedOnboardingV2",
    ]

    static func runIfNeeded(source: UserDefaults? = UserDefaults(suiteName: legacySuiteName), destination: UserDefaults = .standard) {
        guard destination.integer(forKey: versionKey) < currentVersion else { return }
        if let source {
            for key in scalarKeys where destination.object(forKey: key) == nil {
                if let value = source.object(forKey: key) { destination.set(value, forKey: key) }
            }
            migrateModes(from: source, to: destination)
            migrateShortcuts(from: source, to: destination)
        }
        destination.set(true, forKey: "IsMenuBarOnly")
        destination.set(true, forKey: "hasCompletedOnboardingV2")
        destination.set(true, forKey: "hasPreparedOnboardingV2")
        destination.set(currentVersion, forKey: versionKey)
    }

    private static func migrateModes(from source: UserDefaults, to destination: UserDefaults) {
        let destinationKey = "modeConfigurationsV2"
        guard destination.data(forKey: destinationKey) == nil else { return }

        let sourceData = source.data(forKey: destinationKey)
            ?? source.data(forKey: "powerModeConfigurationsV2")
        guard let sourceData,
              let modes = try? JSONDecoder().decode([ModeConfig].self, from: sourceData),
              !modes.isEmpty else { return }

        destination.set(sourceData, forKey: destinationKey)
        if let activeID = source.string(forKey: "activeConfigurationId"),
           let uuid = UUID(uuidString: activeID),
           modes.contains(where: { $0.id == uuid }) {
            destination.set(activeID, forKey: "activeConfigurationId")
        }
    }

    private static func migrateShortcuts(from source: UserDefaults, to destination: UserDefaults) {
        for action in ShortcutAction.legacyKeyboardShortcutActions {
            let key = action.userDefaultsKey
            if let data = destination.data(forKey: key), validShortcutData(data) != nil { continue }
            guard let legacyData = source.data(forKey: key),
                  let shortcut = validShortcutData(legacyData),
                  ShortcutValidator.validationError(for: shortcut, action: action) == nil else {
                destination.removeObject(forKey: key)
                continue
            }
            destination.set(legacyData, forKey: key)
            destination.removeObject(forKey: "\(key)_cleared")
        }
    }

    private static func validShortcutData(_ data: Data) -> Shortcut? {
        try? JSONDecoder().decode(Shortcut.self, from: data)
    }
}
