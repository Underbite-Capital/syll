import AppKit
import ApplicationServices
import Foundation

struct SyllCommandContext: Equatable, Sendable {
    let applicationName: String?
    let repositoryRoot: URL?

    @MainActor
    static func capture() -> SyllCommandContext {
        guard let application = NSWorkspace.shared.frontmostApplication else {
            return SyllCommandContext(applicationName: nil, repositoryRoot: nil)
        }

        return SyllCommandContext(
            applicationName: application.localizedName,
            repositoryRoot: focusedRepositoryRoot(processIdentifier: application.processIdentifier)
        )
    }

    private static func focusedRepositoryRoot(processIdentifier: pid_t) -> URL? {
        guard AXIsProcessTrusted() else { return nil }

        let application = AXUIElementCreateApplication(processIdentifier)
        var focusedWindowValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            application,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindowValue
        ) == .success,
            let focusedWindowValue,
            CFGetTypeID(focusedWindowValue) == AXUIElementGetTypeID()
        else { return nil }

        let focusedWindow = unsafeBitCast(focusedWindowValue, to: AXUIElement.self)
        var documentValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            focusedWindow,
            kAXDocumentAttribute as CFString,
            &documentValue
        ) == .success,
            let documentValue
        else { return nil }

        let documentURL: URL?
        if let url = documentValue as? URL {
            documentURL = url
        } else if let value = documentValue as? String {
            documentURL = URL(string: value)
        } else {
            documentURL = nil
        }

        guard let documentURL, documentURL.isFileURL else { return nil }
        return nearestRepositoryRoot(from: documentURL)
    }

    static func nearestRepositoryRoot(from documentURL: URL) -> URL? {
        var candidate = documentURL.standardizedFileURL.resolvingSymlinksInPath()
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: candidate.path, isDirectory: &isDirectory), !isDirectory.boolValue {
            candidate.deleteLastPathComponent()
        }

        while candidate.path != "/" {
            let marker = candidate.appendingPathComponent(".git", isDirectory: false)
            if FileManager.default.fileExists(atPath: marker.path) {
                return candidate
            }
            candidate.deleteLastPathComponent()
        }
        return nil
    }
}
