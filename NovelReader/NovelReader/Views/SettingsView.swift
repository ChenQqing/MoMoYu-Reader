import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("Appearance") {
                    CodableColorPicker(
                        title: "Text Color",
                        color: $viewModel.settings.textColor
                    )
                    CodableColorPicker(
                        title: "Background Color",
                        color: $viewModel.settings.backgroundColor
                    )
                    OpacitySlider(
                        title: "Background Opacity",
                        value: $viewModel.settings.backgroundOpacity
                    )
                }

                Section("Font") {
                    FontPicker(
                        fontName: $viewModel.settings.fontName,
                        availableFonts: SettingsViewModel.availableFontNames
                    )
                    HStack {
                        Text("Size")
                        Slider(value: $viewModel.settings.fontSize, in: 12...36, step: 1)
                        Text("\(Int(viewModel.settings.fontSize))pt")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                    HStack {
                        Text("Line Spacing")
                        Slider(value: $viewModel.settings.lineSpacing, in: 1.0...3.0, step: 0.1)
                        Text(String(format: "%.1f", viewModel.settings.lineSpacing))
                            .monospacedDigit()
                            .frame(width: 30)
                    }
                }

                Section("Behavior") {
                    Toggle("Show text on hover only", isOn: $viewModel.settings.hoverToShowEnabled)
                    Picker("Reading Mode", selection: $viewModel.settings.readingMode) {
                        Text("Scroll").tag(AppSettings.ReadingMode.scroll)
                        Text("Pagination").tag(AppSettings.ReadingMode.pagination)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Window") {
                    HStack {
                        Text("Width")
                        Slider(value: $viewModel.settings.windowWidth, in: 250...1200, step: 10)
                        Text("\(Int(viewModel.settings.windowWidth))px")
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                    HStack {
                        Text("Height")
                        Slider(value: $viewModel.settings.windowHeight, in: 300...1000, step: 10)
                        Text("\(Int(viewModel.settings.windowHeight))px")
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Reset to Defaults") {
                    viewModel.resetToDefaults()
                }
                .foregroundColor(.red)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 350, height: 450)
    }
}
