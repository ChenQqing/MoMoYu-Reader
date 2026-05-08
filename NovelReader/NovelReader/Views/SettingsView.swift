import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("设置")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("外观") {
                    CodableColorPicker(
                        title: "文字颜色",
                        color: $viewModel.settings.textColor
                    )
                    CodableColorPicker(
                        title: "背景颜色",
                        color: $viewModel.settings.backgroundColor
                    )
                    OpacitySlider(
                        title: "背景透明度",
                        value: $viewModel.settings.backgroundOpacity
                    )
                }

                Section("字体") {
                    FontPicker(
                        fontName: $viewModel.settings.fontName,
                        availableFonts: SettingsViewModel.availableFontNames
                    )
                    HStack {
                        Text("大小")
                        Slider(value: $viewModel.settings.fontSize, in: 12...36, step: 1)
                        Text("\(Int(viewModel.settings.fontSize))pt")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                    HStack {
                        Text("行间距")
                        Slider(value: $viewModel.settings.lineSpacing, in: 1.0...3.0, step: 0.1)
                        Text(String(format: "%.1f", viewModel.settings.lineSpacing))
                            .monospacedDigit()
                            .frame(width: 30)
                    }
                }

                Section("行为") {
                    Toggle("鼠标悬停时才显示文字", isOn: $viewModel.settings.hoverToShowEnabled)
                    Picker("阅读模式", selection: $viewModel.settings.readingMode) {
                        Text("滚动").tag(AppSettings.ReadingMode.scroll)
                        Text("翻页").tag(AppSettings.ReadingMode.pagination)
                    }
                    .pickerStyle(.segmented)
                }

                Section("窗口") {
                    HStack {
                        Text("宽度")
                        Slider(value: $viewModel.settings.windowWidth, in: 250...1200, step: 10)
                        Text("\(Int(viewModel.settings.windowWidth))px")
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                    HStack {
                        Text("高度")
                        Slider(value: $viewModel.settings.windowHeight, in: 300...1000, step: 10)
                        Text("\(Int(viewModel.settings.windowHeight))px")
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("恢复默认") {
                    viewModel.resetToDefaults()
                }
                .foregroundColor(.red)

                Spacer()

                Button("完成") {
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
