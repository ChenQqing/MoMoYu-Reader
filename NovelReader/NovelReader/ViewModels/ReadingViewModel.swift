import Foundation
import Combine

class ReadingViewModel: ObservableObject {
    @Published var displayText: String = ""
    @Published var fullText: String = ""
    @Published var currentFileName: String?
    @Published var characterOffset: Int = 0
    @Published var bookmarks: [Bookmark] = []
    @Published var chapters: [Chapter] = []
    @Published var currentChapterIndex: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    var needsScrollToTop = false
    /// Set after loading a file to request scrolling to the saved position (absolute offset in fullText)
    var pendingScrollToAbsoluteOffset: Int?

    private var loadedChapterRange: Range<Int> = 0..<0
    private let chapterBufferSize = 5

    /// Pre-computed: character length of each chapter in fullText
    private var chapterLengths: [Int] = []
    /// Pre-computed: cumulative character offsets for loaded chapters in displayText
    private var loadedChapterDisplayOffsets: [Int] = []

    func updateScrollPosition(_ displayOffset: Int) {
        // Convert display text offset to full text absolute offset
        if !chapters.isEmpty && !loadedChapterDisplayOffsets.isEmpty {
            let relIdx = findLoadedChapterForOffset(displayOffset)
            let absIdx = relIdx + loadedChapterRange.lowerBound
            let chapterStart = chapters[loadedChapterRange.lowerBound + relIdx].offset
            let offsetInChapter = displayOffset - loadedChapterDisplayOffsets[relIdx]
            let absoluteOffset = chapterStart + offsetInChapter
            characterOffset = max(0, min(absoluteOffset, fullText.count))

            if absIdx != currentChapterIndex && absIdx < chapters.count {
                currentChapterIndex = absIdx
            }
        } else {
            characterOffset = displayOffset
        }
        saveState()
    }

    /// Binary search for chapter index within loaded display offsets.
    private func findLoadedChapterForOffset(_ offset: Int) -> Int {
        var lo = 0
        var hi = loadedChapterDisplayOffsets.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if loadedChapterDisplayOffsets[mid] <= offset {
                lo = mid
            } else {
                hi = mid - 1
            }
        }
        return lo
    }

    /// Convert an absolute offset in fullText to a display text offset.
    func displayOffsetForAbsoluteOffset(_ absoluteOffset: Int) -> Int? {
        guard !chapters.isEmpty, !loadedChapterDisplayOffsets.isEmpty else { return nil }
        let absIdx = findChapterIndex(for: absoluteOffset)
        let relIdx = absIdx - loadedChapterRange.lowerBound
        guard relIdx >= 0, relIdx < loadedChapterDisplayOffsets.count else { return nil }
        let offsetInChapter = absoluteOffset - chapters[absIdx].offset
        return loadedChapterDisplayOffsets[relIdx] + offsetInChapter
    }

    func loadFile(at path: String) throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = try FileManagerService.readFile(at: path)
        fullText = result.text
        currentFileName = (path as NSString).lastPathComponent

        addToLibrary(fileName: currentFileName!, filePath: path)

        if let fileName = currentFileName {
            bookmarks = PersistenceService.loadBookmarks(fileName: fileName)
        }

        chapters = ChapterParser.parseChapters(from: fullText)
        precomputeChapterLengths()
        let log = chapters.prefix(10).enumerated().map { "Ch\($0): off=\($1.offset) \($1.title)" }.joined(separator: "\n")
        try? log.write(toFile: "/tmp/chapters.txt", atomically: true, encoding: .utf8)

        var startOffset = 0
        if let fileName = currentFileName,
           let state = PersistenceService.loadReadingState(),
           state.fileName == fileName {
            startOffset = min(state.characterOffset, fullText.count)
        }
        characterOffset = startOffset

        if chapters.isEmpty {
            displayText = fullText
            loadedChapterRange = 0..<0
            loadedChapterDisplayOffsets = []
        } else {
            let idx = findChapterIndex(for: startOffset)
            currentChapterIndex = idx
            loadChaptersCenteredOn(idx)
        }

        // Request scroll to saved position after text is loaded
        if startOffset > 0 {
            pendingScrollToAbsoluteOffset = startOffset
        }
    }

    private func addToLibrary(fileName: String, filePath: String) {
        var books = PersistenceService.loadBooks()
        if let index = books.firstIndex(where: { $0.filePath == filePath }) {
            books[index].lastOpened = Date()
        } else {
            books.append(BookItem(fileName: fileName, filePath: filePath))
        }
        PersistenceService.saveBooks(books)
    }

    private func precomputeChapterLengths() {
        let nsLen = (fullText as NSString).length
        chapterLengths = chapters.enumerated().map { idx, chapter in
            let end = (idx + 1 < chapters.count) ? chapters[idx + 1].offset : nsLen
            return end - chapter.offset
        }
    }

    // MARK: - Chapter Display

    private func loadChaptersCenteredOn(_ index: Int) {
        guard !chapters.isEmpty else { return }

        let half = chapterBufferSize / 2
        let start = max(0, index - half)
        let end = min(chapters.count, index + half + 1)

        loadedChapterRange = start..<end
        currentChapterIndex = index
        rebuildDisplayText()
    }

    private func rebuildDisplayText() {
        guard !chapters.isEmpty else {
            displayText = fullText
            loadedChapterDisplayOffsets = []
            return
        }

        var parts: [String] = []
        var offsets: [Int] = []
        var nsCharCount = 0

        for idx in loadedChapterRange {
            offsets.append(nsCharCount)
            let chapterText = extractChapterText(at: idx)
            parts.append(chapterText)
            nsCharCount += (chapterText as NSString).length
            if idx < loadedChapterRange.upperBound - 1 {
                nsCharCount += 1 // newline separator (1 UTF-16 code unit)
            }
        }

        displayText = parts.joined(separator: "\n")
        loadedChapterDisplayOffsets = offsets
    }

    private func extractChapterText(at index: Int) -> String {
        let chapter = chapters[index]
        let nsFullText = fullText as NSString
        let start = chapter.offset
        let end: Int
        if index + 1 < chapters.count {
            end = chapters[index + 1].offset
        } else {
            end = nsFullText.length
        }
        let safeEnd = min(end, nsFullText.length)
        guard start < safeEnd else { return "" }
        return nsFullText.substring(with: NSRange(location: start, length: safeEnd - start))
    }

    // MARK: - Scroll-triggered chapter loading

    func loadMoreChaptersAtEnd() {
        guard !chapters.isEmpty else { return }
        let newEnd = min(loadedChapterRange.upperBound + 2, chapters.count)
        guard newEnd > loadedChapterRange.upperBound else { return }

        var nsLen = (displayText as NSString).length
        for idx in loadedChapterRange.upperBound..<newEnd {
            nsLen += 1 // newline
            loadedChapterDisplayOffsets.append(nsLen)
            let chapterText = extractChapterText(at: idx)
            displayText += "\n" + chapterText
            nsLen += (chapterText as NSString).length
        }
        loadedChapterRange = loadedChapterRange.lowerBound..<newEnd
    }

    // MARK: - Navigation

    func navigateToOffset(_ offset: Int) {
        let clamped = max(0, min(offset, fullText.count))
        characterOffset = clamped
        saveState()

        if !chapters.isEmpty {
            let idx = findChapterIndex(for: clamped)
            currentChapterIndex = idx
            // Load from target chapter onwards
            let end = min(idx + chapterBufferSize, chapters.count)
            loadedChapterRange = idx..<end
            rebuildDisplayText()
            needsScrollToTop = true
        }
    }

    func jumpToChapter(_ chapter: Chapter) {
        guard let idx = chapters.firstIndex(where: { $0.id == chapter.id }) else { return }
        currentChapterIndex = idx
        let end = min(idx + chapterBufferSize, chapters.count)
        loadedChapterRange = idx..<end
        rebuildDisplayText()
        let preview = String(displayText.prefix(100))
        try? "jump to idx=\(idx) range=\(loadedChapterRange) preview=\(preview)".write(toFile: "/tmp/jump.txt", atomically: true, encoding: .utf8)
        characterOffset = chapter.offset
        needsScrollToTop = true
        saveState()
    }

    private func findChapterIndex(for offset: Int) -> Int {
        // Binary search
        var lo = 0
        var hi = chapters.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if chapters[mid].offset <= offset {
                lo = mid
            } else {
                hi = mid - 1
            }
        }
        return lo
    }

    // MARK: - Bookmarks

    func addBookmark(label: String) {
        let bookmark = Bookmark(
            id: UUID(),
            characterOffset: characterOffset,
            label: label,
            createdAt: Date()
        )
        bookmarks.append(bookmark)
        if let fileName = currentFileName {
            PersistenceService.saveBookmarks(bookmarks, fileName: fileName)
        }
    }

    func removeBookmark(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        if let fileName = currentFileName {
            PersistenceService.saveBookmarks(bookmarks, fileName: fileName)
        }
    }

    func goToBookmark(_ bookmark: Bookmark) {
        navigateToOffset(bookmark.characterOffset)
    }

    func saveState() {
        guard let fileName = currentFileName else { return }
        var state = ReadingState()
        state.characterOffset = characterOffset
        state.fileName = fileName
        state.lastOpened = Date()
        PersistenceService.saveReadingState(state)
    }
}
