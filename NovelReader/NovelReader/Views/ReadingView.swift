import SwiftUI

struct ReadingView: View {
    @ObservedObject var readingVM: ReadingViewModel
    @ObservedObject var settingsVM: SettingsViewModel
    @State private var isHovering = false
    @State private var showFilePicker = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Background
            backgroundView

            // Content
            if readingVM.fullText.isEmpty {
                emptyStateView
            } else {
                readingContentView
            }

            // Toolbar overlay at top-right
            VStack {
                HStack {
                    Spacer()
                    toolbarButtons
                }
                .padding(8)
                Spacer()
            }
        }
        .frame(
            minWidth: 250, idealWidth: settingsVM.settings.windowWidth,
            minHeight: 300, idealHeight: settingsVM.settings.windowHeight
        )
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.plainText]
        ) { result in
            if case .success(let url) = result {
                try? readingVM.loadFile(at: url.path)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: settingsVM)
        }
        .onAppear {
            isHovering = true // Start visible
        }
        .onDisappear {
            readingVM.saveState()
        }
    }

    private var toolbarButtons: some View {
        HStack(spacing: 12) {
            Button(action: { showFilePicker = true }) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("打开文件 (⌘O)")

            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("设置 (⌘,)")

            Button(action: { readingVM.addBookmark(label: "书签 \(readingVM.bookmarks.count + 1)") }) {
                Image(systemName: "bookmark")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("添加书签")
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var backgroundView: some View {
        let settings = settingsVM.settings
        if settings.backgroundOpacity <= 0.01 {
            Color.clear
        } else {
            settings.backgroundColor.color
                .opacity(settings.backgroundOpacity)
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("打开 .txt 文件开始阅读")
                .font(.headline)
                .foregroundColor(.secondary)
            Button("打开文件") {
                showFilePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private var readingContentView: some View {
        ReadingContentView(
            text: readingVM.fullText,
            font: NSFont(
                name: settingsVM.settings.fontName,
                size: settingsVM.settings.fontSize
            ) ?? NSFont.systemFont(ofSize: settingsVM.settings.fontSize),
            textColor: settingsVM.settings.textColor.nsColor,
            lineSpacing: settingsVM.settings.lineSpacing,
            hoverToShowEnabled: settingsVM.settings.hoverToShowEnabled,
            isHovering: $isHovering
        )
        .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
}
