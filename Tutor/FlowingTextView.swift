import SwiftUI

struct FlowingTextView: View {
    let words: [TokenizedWord]
    let onTap: (TokenizedWord) -> Void

    var body: some View {
        Group {
            ForEach(words.indices, id: \.self) { index in
                let tokenizedWord = words[index]
                Text(tokenizedWord.word)
                    .underline()
                    .foregroundColor(.blue)
                    .onTapGesture {
                        onTap(tokenizedWord)
                    }
            }
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .font(.body)
        .lineSpacing(4)
    }
}


