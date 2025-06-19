import SwiftUI

struct SpeechBubbleTextView: View {
    let text: String
    let words: [TokenizedWord]?

    @State private var selectedWord: TokenizedWord?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if words != nil {
                FlowingTextView(words: words ?? []) { word in
                    selectedWord = word
                }
            } else {
                Text(text)
            }
        }
        .padding(12)
        .padding(.bottom, 12) 
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .sheet(item: $selectedWord) { word in
            WordDetailSheet(word: word)
        }
    }
}
