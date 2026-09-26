import Foundation

enum SyllClipboardResetPolicy {
    /// An explicit reset may restore the pre-paste snapshot only while Syll's
    /// session marker or exact pasted text still occupies the clipboard.
    static func canRestore(
        currentSessionID: String?, currentText: String?,
        expectedSessionID: String, expectedText: String
    ) -> Bool {
        currentSessionID == expectedSessionID || currentText == expectedText
    }
}
