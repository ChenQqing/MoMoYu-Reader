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
        }
        .frame(
            minWidth: 250, idealWidth: settingsVM.settings.windowWidth,
            minHeight: 300, idealHeight: settingsVM.settings.windowHeight
        )
        .contextMenu {
            Button("打开文件") { showFilePicker = true }
            Button("设置") { showSettings = true }
            Divider()
            Button("添加书签") {
                readingVM.addBookmark(label: "书签 \(readingVM.bookmarks.count + 1)")
            }
            if !readingVM.bookmarks.isEmpty {
                Menu("书签") {
                    ForEach(readingVM.bookmarks) { bookmark in
                        Button(bookmark.label) {
                            readingVM.goToBookmark(bookmark)
                        }
                    }
                }
            }
        }
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
