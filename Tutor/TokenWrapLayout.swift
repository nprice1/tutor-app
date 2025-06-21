import SwiftUI

struct TokenWrapLayout: View {
    let text: String
    let words: [TokenizedWord]
    let onTap: (TokenizedWord) -> Void

    var body: some View {
        if !words.isEmpty {
            FlowLayout(spacing: 4) {
                ForEach(words.indices, id: \.self) { index in
                    let tokenizedWord = words[index]
                    Text(tokenizedWord.word + " ")
                        .underline()
                        .foregroundColor(.blue)
                        .onTapGesture {
                            onTap(tokenizedWord)
                        }
                }
            }
            .padding(4)
        } else {
            Text(text)
                .padding(4)
        }
    }

}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            // Add bounds.origin to position relative to the container's actual position
            let adjustedOrigin = CGPoint(
                x: result.frames[index].origin.x + bounds.origin.x,
                y: result.frames[index].origin.y + bounds.origin.y
            )
            subview.place(at: adjustedOrigin, proposal: .unspecified)
        }
    }
}

struct FlowResult {
    var bounds = CGSize.zero
    var frames: [CGRect] = []
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if origin.x + size.width > maxWidth && origin.x > 0 {
                // Move to next row
                origin.x = 0
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            
            frames.append(CGRect(origin: origin, size: size))
            
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        
        bounds = CGSize(
            width: maxWidth,
            height: origin.y + rowHeight
        )
    }
}
