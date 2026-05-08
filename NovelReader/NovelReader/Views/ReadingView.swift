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
        .toolbar {
            ToolbarItemGroup {
                Button(action: { showFilePicker = true }) {
                    Image(systemName: "doc.badge.plus")
                }
                .help("Open File (⌘O)")

                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                }
                .help("Settings (⌘,)")

                Button(action: { readingVM.addBookmark(label: "Bookmark \(readingVM.bookmarks.count + 1)") }) {
                    Image(systemName: "bookmark")
                }
                .help("Add Bookmark")
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
            Text("Open a .txt file to start reading")
                .font(.headline)
                .foregroundColor(.secondary)
            Button("Open File") {
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
