import SwiftUI

/// The existing Vocabulary popup is the Personal Dictionary entry point.
/// `VocabularyWord` remains a provider-facing projection maintained by
/// `PersonalDictionaryService`; users manage one dictionary, not two lists.
struct VocabularyView: View {
    var body: some View {
        WordReplacementView()
    }
}
