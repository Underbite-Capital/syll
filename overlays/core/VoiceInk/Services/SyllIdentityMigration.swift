import Foundation

enum SyllIdentityMigration {
    static let currentVersion = 1
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
            migrateShortcuts(from: source, to: destination)
        }
        destination.set(true, forKey: "IsMenuBarOnly")
        destination.set(true, forKey: "hasCompletedOnboardingV2")
        destination.set(true, forKey: "hasPreparedOnboardingV2")
        destination.set(currentVersion, forKey: versionKey)
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
