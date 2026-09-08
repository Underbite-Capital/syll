import AppKit
import Carbon.HIToolbox
import XCTest
@testable import VoiceInk

final class SyllIdentityMigrationTests: XCTestCase {
    private var suites: [String] = []
    override func tearDown() {
        for suite in suites { UserDefaults.standard.removePersistentDomain(forName: suite) }
        super.tearDown()
    }

    func testMigratesValidFnShortcutAndPreferences() throws {
        let source = makeSuite("source"), destination = makeSuite("destination")
        let shortcut = Shortcut.modifierOnly(keyCode: UInt16(kVK_Function), modifierFlags: [.function])
        source.set(try JSONEncoder().encode(shortcut), forKey: ShortcutAction.primaryRecording.userDefaultsKey)
        source.set("hybrid", forKey: "primaryRecordingShortcutMode")
        SyllIdentityMigration.runIfNeeded(source: source, destination: destination)
        let migrated = try XCTUnwrap(destination.data(forKey: ShortcutAction.primaryRecording.userDefaultsKey))
        XCTAssertEqual(try JSONDecoder().decode(Shortcut.self, from: migrated), shortcut)
        XCTAssertEqual(destination.string(forKey: "primaryRecordingShortcutMode"), "hybrid")
        XCTAssertTrue(destination.bool(forKey: "IsMenuBarOnly"))
    }

    func testMalformedDoubleEncodedShortcutIsReplacedByValidLegacyData() throws {
        let source = makeSuite("source"), destination = makeSuite("destination")
        let shortcut = Shortcut.modifierOnly(keyCode: UInt16(kVK_Function), modifierFlags: [.function])
        let valid = try JSONEncoder().encode(shortcut)
        source.set(valid, forKey: ShortcutAction.primaryRecording.userDefaultsKey)
        destination.set(valid.base64EncodedData(), forKey: ShortcutAction.primaryRecording.userDefaultsKey)
        SyllIdentityMigration.runIfNeeded(source: source, destination: destination)
        XCTAssertEqual(destination.data(forKey: ShortcutAction.primaryRecording.userDefaultsKey), valid)
    }

    private func makeSuite(_ label: String) -> UserDefaults {
        let name = "SyllIdentityMigrationTests.\(label).\(UUID().uuidString)"
        suites.append(name)
        UserDefaults.standard.removePersistentDomain(forName: name)
        return UserDefaults(suiteName: name)!
    }
}
