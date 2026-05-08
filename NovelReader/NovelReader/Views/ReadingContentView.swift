import SwiftUI
import AppKit

/// NSViewRepresentable that wraps an NSTextView with hover detection and scroll tracking.
struct ReadingContentView: NSViewRepresentable {
    let text: String
    let font: NSFont
    let textColor: NSColor
    let lineSpacing: CGFloat
    let hoverToShowEnabled: Bool
    @Binding var isHovering: Bool
    var onScrollPositionChanged: ((Int) -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 10, height: 10)

        // Hide scrollbars
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.verticalScroller?.isHidden = true
        scrollView.horizontalScroller?.isHidden = true

        // Configure tracking area
        let trackingArea = NSTrackingArea(
            rect: scrollView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: context.coordinator,
            userInfo: nil
        )
        scrollView.addTrackingArea(trackingArea)

        // Observe scroll position changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.didScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

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

        context.coordinator.onScrollPositionChanged = onScrollPositionChanged
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isHovering: $isHovering, onScrollPositionChanged: onScrollPositionChanged)
    }

    class Coordinator: NSView {
        var isHovering: Binding<Bool>
        var onScrollPositionChanged: ((Int) -> Void)?
        weak var scrollView: NSScrollView?
        weak var textView: NSTextView?
        private var debounceTimer: Timer?

        init(isHovering: Binding<Bool>, onScrollPositionChanged: ((Int) -> Void)?) {
            self.isHovering = isHovering
            self.onScrollPositionChanged = onScrollPositionChanged
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
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

        @objc func didScroll(_ notification: Notification) {
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                self?.calculateAndReportOffset()
            }
        }

        private func calculateAndReportOffset() {
            guard let scrollView = scrollView, let textView = textView else { return }
            let visibleRect = scrollView.contentView.bounds
            let layoutManager = textView.layoutManager!
            let textContainer = textView.textContainer!
            let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
            let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            let offset = charRange.location
            DispatchQueue.main.async {
                self.onScrollPositionChanged?(offset)
            }
        }
    }
}
