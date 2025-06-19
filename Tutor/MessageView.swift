import SwiftUI

struct MessageView: View {

    private var text: String
    private var tokenizedWords: [TokenizedWord]?
    private var isCurrentUser: Bool
    
    init(text: String, tokenizedWords: [TokenizedWord]?, isCurrentUser: Bool) {
        self.text = text
        self.tokenizedWords = tokenizedWords
        self.isCurrentUser = isCurrentUser
    }

    var body: some View {
        SpeechBubbleTextView(text: text, words: self.tokenizedWords ?? [])
    }
    
}
