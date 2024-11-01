import SwiftUI
import UIKit

struct SpeechBubbleTestView: UIViewRepresentable {
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SpeechBubbleTestView

        init(parent: SpeechBubbleTestView) {
            self.parent = parent
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            if let selectedText = textView.text(in: textView.selectedTextRange ?? textView.textRange(from: textView.beginningOfDocument, to: textView.endOfDocument)!) {
                parent.onTextSelected(selectedText)
            }
        }
    }

    var text: String
    var isCurrentUser: Bool
    var onTextSelected: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.white
        textView.textAlignment = .natural

        // Set the line break mode and ensure word wrapping
        textView.textContainer.lineBreakMode = .byWordWrapping
        
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
}
