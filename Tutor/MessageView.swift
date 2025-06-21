import SwiftUI

struct MessageView: View {
    let text: String
    let tokenizedWords: [TokenizedWord]
    let isCurrentUser: Bool
    let onPlayAudio: (() -> Void)?
    
    // Add a default initializer without the play button for backwards compatibility
    init(text: String, tokenizedWords: [TokenizedWord], isCurrentUser: Bool) {
        self.text = text
        self.tokenizedWords = tokenizedWords
        self.isCurrentUser = isCurrentUser
        self.onPlayAudio = nil
    }
    
    // New initializer with play button
    init(text: String, tokenizedWords: [TokenizedWord], isCurrentUser: Bool, onPlayAudio: @escaping () -> Void) {
        self.text = text
        self.tokenizedWords = tokenizedWords
        self.isCurrentUser = isCurrentUser
        self.onPlayAudio = onPlayAudio
    }
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 8) {
            SpeechBubbleTextView(
                text: text,
                words: tokenizedWords.isEmpty ? nil : tokenizedWords,
                isCurrentUser: isCurrentUser
            )
            
            // Add play button for system messages
            if !isCurrentUser, let onPlayAudio = onPlayAudio {
                Button(action: onPlayAudio) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                        Text("Play")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
    }
}
