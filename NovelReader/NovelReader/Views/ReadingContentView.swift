import SwiftUI
import AppKit

/// NSViewRepresentable that wraps an NSTextView with hover detection.
struct ReadingContentView: NSViewRepresentable {
    let text: String
    let font: NSFont
    let textColor: NSColor
    let lineSpacing: CGFloat
    let hoverToShowEnabled: Bool
    @Binding var isHovering: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 10, height: 10)

        // Configure tracking area
        let trackingArea = NSTrackingArea(
            rect: scrollView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: context.coordinator,
            userInfo: nil
        )
        scrollView.addTrackingArea(trackingArea)

        context.coordinator.scrollView = scrollView
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        textView.textStorage?.setAttributedString(
            NSAttributedString(string: text, attributes: attributes)
        )

        // Update hover opacity
        let opacity: Double = hoverToShowEnabled ? (isHovering ? 1.0 : 0.0) : 1.0
        textView.alphaValue = CGFloat(opacity)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isHovering: $isHovering)
    }

    class Coordinator: NSView {
        var isHovering: Binding<Bool>
        weak var scrollView: NSScrollView?
        weak var textView: NSTextView?

        init(isHovering: Binding<Bool>) {
            self.isHovering = isHovering
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func mouseEntered(with event: NSEvent) {
            DispatchQueue.main.async {
                self.isHovering.wrappedValue = true
            }
        }

        override func mouseExited(with event: NSEvent) {
            DispatchQueue.main.async {
                self.isHovering.wrappedValue = false
            }
        }
    }
}
