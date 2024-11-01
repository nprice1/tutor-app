import SwiftUI
import UIKit

struct SpeechBubbleTextView: UIViewRepresentable {
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SpeechBubbleTextView

        init(parent: SpeechBubbleTextView) {
            self.parent = parent
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            if let selectedText = textView.text(in: textView.selectedTextRange ?? textView.textRange(from: textView.beginningOfDocument, to: textView.endOfDocument)!) {
                parent.onTextSelected(selectedText)
            }
        }
        
        @objc func handleTripleTap(_ gesture: UITapGestureRecognizer) {
            if let textView = gesture.view as? UITextView {
                // Call the triple tap action with the selected text
                parent.onTripleTap(textView.text)
            }
        }
    }

    @Binding var desiredHeight: CGFloat
    var text: String
    var isCurrentUser: Bool
    var onTextSelected: (String) -> Void
    var onTripleTap: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.text = text
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.white
        textView.textAlignment = .natural
        textView.isScrollEnabled = false

        textView.textContainer.lineBreakMode = .byWordWrapping
        
        // Add triple tap gesture recognizer
        let tripleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTripleTap(_:)))
        tripleTapGesture.numberOfTapsRequired = 3
        textView.addGestureRecognizer(tripleTapGesture)
        
        DispatchQueue.main.async {
            self.desiredHeight = heightForTextView(textView: textView)
        }
        
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        
        DispatchQueue.main.async {
            // Remove old bubble layer if it exists
            if let existingLayer = uiView.layer.sublayers?.first(where: { $0 is CAShapeLayer }) {
                existingLayer.removeFromSuperlayer()
            }
            
            // Create and configure the bubble layer
            let bubbleLayer = CAShapeLayer()
            let path = UIBezierPath()
            let rect = CGRect(x: 0, y: 0, width: uiView.bounds.width, height: heightForTextView(textView: uiView))
            let bubbleRect = rect.insetBy(dx: 0, dy: 0)
            
            path.move(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY))
            path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.minY))
            path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY))
            path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY))
            path.close()
            
            bubbleLayer.path = path.cgPath
            bubbleLayer.fillColor = isCurrentUser ? UIColor.systemBlue.cgColor : UIColor.systemGreen.cgColor
            uiView.layer.insertSublayer(bubbleLayer, at: 0)
            
            self.desiredHeight = heightForTextView(textView: uiView)
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        // Update the height for the text view before returning size
        let height = heightForTextView(textView: uiView)
        return CGSize(width: proposal.width ?? UIScreen.main.bounds.width, height: height)
    }
    
    func heightForTextView(textView: UITextView) -> CGFloat {
        let text = textView.text ?? ""
        let textViewWidth = textView.frame.width
        let maxWidth = textViewWidth - textView.textContainerInset.left - textView.textContainerInset.right
        let textViewSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: textView.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        ]
        let boundingRect = text.boundingRect(with: textViewSize,
                                             options: .usesLineFragmentOrigin,
                                             attributes: attributes,
                                             context: nil)
        return boundingRect.height + 25
    }
    
}
