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

        // Transparent background support
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true

        // Title bar
        self.title = "NovelReader"
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden

        // Allow dragging from content area
        self.isMovableByWindowBackground = true

        // Minimum size
        self.minSize = NSSize(width: 250, height: 300)
    }

    /// Update window background based on settings
    func applyBackground(color: NSColor, opacity: Double) {
        if opacity <= 0.01 {
            self.backgroundColor = .clear
            self.isOpaque = false
            self.hasShadow = false
        } else {
            self.backgroundColor = color.withAlphaComponent(CGFloat(opacity))
            self.isOpaque = false
            self.hasShadow = true
        }
    }
}
