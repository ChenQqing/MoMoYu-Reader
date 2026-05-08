import SwiftUI

/// Color picker that binds to CodableColor
struct CodableColorPicker: View {
    let title: String
    @Binding var color: CodableColor

    var body: some View {
        ColorPicker(title, selection: Binding(
            get: { color.color },
            set: { newColor in
                color = CodableColor(newColor)
            }
        ))
    }
}

/// Opacity slider with label
struct OpacitySlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(title)
            Slider(value: $value, in: 0...1, step: 0.05)
            Text("\(Int(value * 100))%")
                .monospacedDigit()
                .frame(width: 40)
        }
    }
}

/// Font picker dropdown
struct FontPicker: View {
    @Binding var fontName: String
    let availableFonts: [String]

    var body: some View {
        Picker("Font", selection: $fontName) {
            ForEach(availableFonts, id: \.self) { name in
                Text(name).font(.custom(name, size: 14))
            }
        }
    }
}
