import Testing
@testable import NovelReader

@Suite("Bookmark Tests")
struct BookmarkTests {
    @Test("Bookmark stores position and label")
    func testBookmarkCreation() {
        let bookmark = Bookmark(
            id: UUID(),
            characterOffset: 500,
            label: "Chapter 3",
            createdAt: Date()
        )
        #expect(bookmark.characterOffset == 500)
        #expect(bookmark.label == "Chapter 3")
    }

    @Test("Bookmark is Codable")
    func testCodable() throws {
        let bookmark = Bookmark(
            id: UUID(),
            characterOffset: 100,
            label: "Start",
            createdAt: Date()
        )
        let data = try JSONEncoder().encode(bookmark)
        let decoded = try JSONDecoder().decode(Bookmark.self, from: data)
        #expect(decoded.characterOffset == 100)
        #expect(decoded.label == "Start")
    }
}
