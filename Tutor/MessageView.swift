import SwiftUI

struct MessageView: View {

    @State private var desiredHeight: CGFloat
    
    private var text: String
    private var isCurrentUser: Bool
    private var onTextSelected: (String) -> Void
    private var onTripleTap: (String) -> Void
    
    init(text: String, isCurrentUser: Bool, onTextSelected: @escaping (String) -> Void, onTripleTap: @escaping (String) -> Void) {
        self.text = text
        self.isCurrentUser = isCurrentUser
        self.onTextSelected = onTextSelected
        self.onTripleTap = onTripleTap
        self.desiredHeight = 100
    }

    var body: some View {
        SpeechBubbleTextView(
            desiredHeight: $desiredHeight,
            text: text,
            isCurrentUser: isCurrentUser,
            onTextSelected: onTextSelected,
            onTripleTap: onTripleTap
        )
        .padding()
        .frame(height: desiredHeight)
    }
    
}
