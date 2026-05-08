import SwiftUI

struct AppSettings: Codable {
    var fontSize: CGFloat = 16
    var fontName: String = "Helvetica"
    var lineSpacing: CGFloat = 1.5
    var textColor: CodableColor = CodableColor(.white)
    var backgroundColor: CodableColor = CodableColor(Color(red: 0.15, green: 0.15, blue: 0.15))
    var backgroundOpacity: Double = 0.85
    var hoverToShowEnabled: Bool = true
    var readingMode: ReadingMode = .scroll
    var windowWidth: CGFloat = 400
    var windowHeight: CGFloat = 600

    enum ReadingMode: String, Codable, CaseIterable {
        case scroll
        case pagination
    }
}

/// Wrapper to make SwiftUI Color Codable
struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ color: Color) {
        // Default to white if extraction fails
        self.red = 1; self.green = 1; self.blue = 1; self.alpha = 1
        // Extract from NSColor for reliability
        if let nsColor = NSColor(color).usingColorSpace(.deviceRGB) {
            self.red = Double(nsColor.redComponent)
            self.green = Double(nsColor.greenComponent)
            self.blue = Double(nsColor.blueComponent)
            self.alpha = Double(nsColor.alphaComponent)
        }
    }

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    var nsColor: NSColor {
        NSColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }

    // Static color constants for convenient comparison (e.g. settings.textColor == .white)
    static let white = CodableColor(red: 1, green: 1, blue: 1)
    static let black = CodableColor(red: 0, green: 0, blue: 0)
}
