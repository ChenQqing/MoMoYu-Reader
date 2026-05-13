import SwiftUI

struct ReadingView: View {
    @ObservedObject var readingVM: ReadingViewModel
    @ObservedObject var settingsVM: SettingsViewModel
    @State private var isHovering = false
    @State private var showFilePicker = false
    @State private var showSettings = false
    @State private var showChapterList = false
    @State private var coordinatorRef: ReadingContentView.Coordinator?

    var body: some View {
        ZStack {
            backgroundView

            if readingVM.displayText.isEmpty {
                emptyStateView
            } else {
                readingContentView
            }
        }
        .frame(
            idealWidth: settingsVM.settings.windowWidth,
            idealHeight: settingsVM.settings.windowHeight
        )
        .contextMenu {
            Button("返回书库") {
                readingVM.saveState()
                readingVM.currentFileName = nil
            }
            Button("打开文件") { showFilePicker = true }
            Button("设置") { showSettings = true }

            if !readingVM.chapters.isEmpty {
                Divider()
                Button("目录 (\(readingVM.currentChapterIndex + 1)/\(readingVM.chapters.count))") {
                    showChapterList = true
                }
            }

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
        .popover(isPresented: $showChapterList) {
            ChapterListView(
                chapters: readingVM.chapters,
                currentIndex: Binding(
                    get: { readingVM.currentChapterIndex },
                    set: { readingVM.currentChapterIndex = $0 }
                ),
                onSelect: { chapter in
                    readingVM.jumpToChapter(chapter)
                }
            )
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
            isHovering = true
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
            text: readingVM.displayText,
            font: NSFont(
                name: settingsVM.settings.fontName,
                size: settingsVM.settings.fontSize
            ) ?? NSFont.systemFont(ofSize: settingsVM.settings.fontSize),
            textColor: settingsVM.settings.textColor.nsColor,
            lineSpacing: settingsVM.settings.lineSpacing,
            hoverToShowEnabled: settingsVM.settings.hoverToShowEnabled,
            shouldScrollToTop: readingVM.needsScrollToTop,
            isHovering: $isHovering,
            onScrollPositionChanged: { offset in
                readingVM.updateScrollPosition(offset)
            },
            onNearBottom: {
                readingVM.loadMoreChaptersAtEnd()
            },
            onScrolledToTop: {
                readingVM.needsScrollToTop = false
            },
            onCoordinatorReady: { coord in
                coordinatorRef = coord
            },
            onTextApplied: {
                if let absOffset = readingVM.pendingScrollToAbsoluteOffset,
                   let displayOffset = readingVM.displayOffsetForAbsoluteOffset(absOffset),
                   let coord = coordinatorRef {
                    readingVM.pendingScrollToAbsoluteOffset = nil
                    coord.scrollToCharacterOffset(displayOffset)
                }
            }
        )
        .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
}
