import SwiftUI
import AppKit

class ReaderTextView: NSTextView {
    override func rightMouseDown(with event: NSEvent) {
        nextResponder?.rightMouseDown(with: event)
    }
}

struct ReadingContentView: NSViewRepresentable {
    let text: String
    let font: NSFont
    let textColor: NSColor
    let lineSpacing: CGFloat
    let hoverToShowEnabled: Bool
    let shouldScrollToTop: Bool
    @Binding var isHovering: Bool
    var onScrollPositionChanged: ((Int) -> Void)?
    var onNearBottom: (() -> Void)?
    var onScrolledToTop: (() -> Void)?
    var onCoordinatorReady: ((Coordinator) -> Void)?
    var onTextApplied: (() -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = ReaderTextView()

        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.contentView.drawsBackground = false

        let trackingArea = NSTrackingArea(
            rect: scrollView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: context.coordinator,
            userInfo: nil
        )
        scrollView.addTrackingArea(trackingArea)

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.didScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        context.coordinator.scrollView = scrollView
        context.coordinator.textView = textView
        context.coordinator.lastText = text

        applyText(text, to: textView)
        resizeTextViewToFit(textView, in: scrollView)

        DispatchQueue.main.async {
            onCoordinatorReady?(context.coordinator)
            self.onTextApplied?()
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! ReaderTextView
        let coord = context.coordinator

        if coord.lastText != text {
            coord.lastText = text
            coord.suppressScrollCallback = true

            applyText(text, to: textView)
            resizeTextViewToFit(textView, in: scrollView)

            if shouldScrollToTop {
                coord.scrollToTop()
            }

            // Re-enable scroll callback after everything settles
            DispatchQueue.main.async {
                coord.suppressScrollCallback = false
                if self.shouldScrollToTop {
                    self.onScrolledToTop?()
                }
                self.onTextApplied?()
            }
        }

        let opacity: Double = hoverToShowEnabled ? (isHovering ? 1.0 : 0.0) : 1.0
        textView.alphaValue = CGFloat(opacity)

        coord.onScrollPositionChanged = onScrollPositionChanged
        coord.onNearBottom = onNearBottom
    }

    private func applyText(_ text: String, to textView: NSTextView) {
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
    }

    /// Resize the text view to fit its content so the scroll view knows the full content height.
    private func resizeTextViewToFit(_ textView: NSTextView, in scrollView: NSScrollView) {
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        layoutManager.ensureLayout(for: textContainer)

        let usedRect = layoutManager.usedRect(for: textContainer)
        let contentWidth = scrollView.contentView.bounds.width
        let newHeight = usedRect.height + textView.textContainerInset.height * 2

        textView.frame = NSRect(x: 0, y: 0, width: contentWidth, height: max(newHeight, scrollView.bounds.height))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isHovering: $isHovering)
    }

    class Coordinator: NSView {
        var isHovering: Binding<Bool>
        var onScrollPositionChanged: ((Int) -> Void)?
        var onNearBottom: (() -> Void)?
        weak var scrollView: NSScrollView?
        weak var textView: NSTextView?
        var lastText: String = ""
        var suppressScrollCallback = false
        private var debounceTimer: Timer?

        init(isHovering: Binding<Bool>) {
            self.isHovering = isHovering
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
            guard !suppressScrollCallback else { return }
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
                self?.handleScroll()
            }
        }

        private func handleScroll() {
            guard let scrollView = scrollView, let textView = textView else { return }
            let visibleRect = scrollView.contentView.bounds
            let layoutManager = textView.layoutManager!
            let textContainer = textView.textContainer!
            let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
            let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            let offset = charRange.location

            DispatchQueue.main.async {
                self.onScrollPositionChanged?(offset)

                let totalLength = textView.string.count
                let distanceFromEnd = totalLength - offset
                if distanceFromEnd < 1500 {
                    self.onNearBottom?()
                }
            }
        }

        func scrollToTop() {
            guard let scrollView = scrollView else { return }
            scrollView.contentView.scroll(to: NSPoint(x: 0, y: 0))
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }

        func scrollToCharacterOffset(_ offset: Int) {
            guard let textView = textView, let scrollView = scrollView else { return }
            let safeOffset = min(offset, textView.string.count)
            guard safeOffset >= 0 else { return }
            let nsRange = NSRange(location: safeOffset, length: 0)
            if let rect = textView.boundingRect(forCharacterRange: nsRange) {
                scrollView.contentView.scroll(to: NSPoint(x: 0, y: rect.origin.y))
                scrollView.reflectScrolledClipView(scrollView.contentView)
            }
        }
    }
}

extension NSTextView {
    func boundingRect(forCharacterRange range: NSRange) -> NSRect? {
        guard let layoutManager = layoutManager, let textContainer = textContainer else { return nil }
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
}
