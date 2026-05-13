import AppKit
import SwiftUI

/// NSWindow subclass configured for floating above all other windows.
class FloatingWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        // Float above all windows
        self.level = .floating

        // Keep window opaque to event system (use nearly-clear color)
        self.isOpaque = true
        self.backgroundColor = NSColor(white: 0, alpha: 0.004)
        self.hasShadow = true

        // Title bar — hide completely
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.styleMask.remove(.titled)

        // Allow dragging from content area
        self.isMovableByWindowBackground = true

        self.minSize = NSSize(width: 1, height: 1)
    }

    /// Update window background based on settings
    func applyBackground(color: NSColor, opacity: Double) {
        if opacity <= 0.01 {
            // Nearly transparent but still opaque to event system
            self.backgroundColor = NSColor(white: 0, alpha: 0.004)
            self.isOpaque = true
            self.hasShadow = false
        } else {
            self.backgroundColor = color.withAlphaComponent(CGFloat(opacity))
            self.isOpaque = true
            self.hasShadow = true
        }
    }
}
