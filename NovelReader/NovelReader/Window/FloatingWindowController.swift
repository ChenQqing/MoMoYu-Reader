import AppKit
import SwiftUI

/// Manages the floating reading window lifecycle.
class FloatingWindowController {
    private var window: FloatingWindow?
    private var hostingView: NSHostingView<AnyView>?

    func openWindow<Content: View>(
        size: NSSize,
        content: Content
    ) {
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.midY - size.height / 2
        )
        let rect = NSRect(origin: origin, size: size)

        let floatingWindow = FloatingWindow(contentRect: rect)
        let hosting = NSHostingView(rootView: AnyView(content))
        hosting.frame = floatingWindow.contentView!.bounds
        hosting.autoresizingMask = [.width, .height]

        floatingWindow.contentView?.addSubview(hosting)
        floatingWindow.makeKeyAndOrderFront(nil)

        self.window = floatingWindow
        self.hostingView = hosting
    }

    func closeWindow() {
        window?.close()
        window = nil
        hostingView = nil
    }

    func updateBackground(color: NSColor, opacity: Double) {
        window?.applyBackground(color: color, opacity: opacity)
    }

    var isVisible: Bool {
        window?.isVisible ?? false
    }
}
