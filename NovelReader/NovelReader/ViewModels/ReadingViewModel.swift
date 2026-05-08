import Foundation
import Combine

class ReadingViewModel: ObservableObject {
    @Published var paragraphs: [String] = []
    @Published var fullText: String = ""
    @Published var currentFileName: String?
    @Published var characterOffset: Int = 0
    @Published var currentPage: Int = 0
    @Published var bookmarks: [Bookmark] = []
    @Published var chapters: [Chapter] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Update scroll position with debounced save.
    func updateScrollPosition(_ offset: Int) {
        characterOffset = offset
        saveState()
    }

    /// Load a .txt file and restore reading position.
    func loadFile(at path: String) throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = try FileManagerService.readFile(at: path)
        fullText = result.text
        paragraphs = result.paragraphs
        currentFileName = (path as NSString).lastPathComponent

        // Add to library
        addToLibrary(fileName: currentFileName!, filePath: path)

        // Load bookmarks
        if let fileName = currentFileName {
            bookmarks = PersistenceService.loadBookmarks(fileName: fileName)
        }

        // Parse chapters
        chapters = ChapterParser.parseChapters(from: fullText)

        // Restore reading position
        if let fileName = currentFileName,
           let state = PersistenceService.loadReadingState(),
           state.fileName == fileName {
            characterOffset = min(state.characterOffset, fullText.count)
            currentPage = state.currentPage
        } else {
            characterOffset = 0
            currentPage = 0
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

    /// Navigate to a specific character offset.
    func navigateToOffset(_ offset: Int) {
        characterOffset = max(0, min(offset, fullText.count))
        saveState()
    }

    /// Navigate to a specific page (pagination mode).
    func navigateToPage(_ page: Int) {
        currentPage = max(0, page)
        saveState()
    }

    /// Add a bookmark at current position.
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

    /// Remove a bookmark by ID.
    func removeBookmark(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        if let fileName = currentFileName {
            PersistenceService.saveBookmarks(bookmarks, fileName: fileName)
        }
    }

    /// Navigate to a bookmark's position.
    func goToBookmark(_ bookmark: Bookmark) {
        navigateToOffset(bookmark.characterOffset)
    }

    /// Jump to a specific chapter.
    func jumpToChapter(_ chapter: Chapter) {
        navigateToOffset(chapter.offset)
    }

    /// Save current reading state.
    func saveState() {
        guard let fileName = currentFileName else { return }
        var state = ReadingState()
        state.characterOffset = characterOffset
        state.currentPage = currentPage
        state.fileName = fileName
        state.lastOpened = Date()
        PersistenceService.saveReadingState(state)
    }
}
