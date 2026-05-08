import Foundation

enum PersistenceService {
    private enum Keys {
        static let settings = "NovelReader.Settings"
        static let readingState = "NovelReader.ReadingState"
        static let bookmarks = "NovelReader.Bookmarks"
        static let library = "NovelReader.Library"
    }

    // MARK: - Settings

    static func saveSettings(_ settings: AppSettings, to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Keys.settings)
        }
    }

    static func loadSettings(from defaults: UserDefaults = .standard) -> AppSettings {
        guard let data = defaults.data(forKey: Keys.settings),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    // MARK: - Reading State

    static func saveReadingState(_ state: ReadingState, to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Keys.readingState)
        }
    }

    static func loadReadingState(from defaults: UserDefaults = .standard) -> ReadingState? {
        guard let data = defaults.data(forKey: Keys.readingState) else { return nil }
        return try? JSONDecoder().decode(ReadingState.self, from: data)
    }

    // MARK: - Bookmarks

    static func saveBookmarks(_ bookmarks: [Bookmark], fileName: String) {
        let url = bookmarksURL(for: fileName)
        if let data = try? JSONEncoder().encode(bookmarks) {
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: url)
        }
    }

    static func loadBookmarks(fileName: String) -> [Bookmark] {
        let url = bookmarksURL(for: fileName)
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Bookmark].self, from: data)) ?? []
    }

    private static func bookmarksURL(for fileName: String) -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let safeName = fileName.replacingOccurrences(of: "/", with: "_")
        return appSupport.appendingPathComponent("NovelReader/Bookmarks/\(safeName).json")
    }

    // MARK: - Book Library

    static func saveBooks(_ books: [BookItem], to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(books) {
            defaults.set(data, forKey: Keys.library)
        }
    }

    static func loadBooks(from defaults: UserDefaults = .standard) -> [BookItem] {
        guard let data = defaults.data(forKey: Keys.library),
              let books = try? JSONDecoder().decode([BookItem].self, from: data) else {
            return []
        }
        return books
    }
}
