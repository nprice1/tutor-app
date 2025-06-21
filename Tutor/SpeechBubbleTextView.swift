import SwiftUI

struct SpeechBubbleTextView: View {
    let text: String
    let words: [TokenizedWord]?
    let isCurrentUser: Bool

    @State private var selectedWord: TokenizedWord?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TokenWrapLayout(text: text, words: words ?? []) { word in
                selectedWord = word
            }
        }
        .padding(12)
        .background(isCurrentUser ? Color.blue : Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
        .sheet(item: $selectedWord) { word in
            WordDetailSheet(word: word)
        }
    }
}
