import Testing
@testable import NovelReader

@Suite("ReadingState Tests")
struct ReadingStateTests {
    @Test("Default state starts at position 0")
    func testDefaultState() {
        let state = ReadingState()
        #expect(state.characterOffset == 0)
        #expect(state.currentPage == 0)
        #expect(state.fileName == nil)
    }

    @Test("Codable roundtrip preserves state")
    func testCodableRoundtrip() throws {
        var state = ReadingState()
        state.characterOffset = 1234
        state.currentPage = 5
        state.fileName = "test.txt"

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(ReadingState.self, from: data)

        #expect(decoded.characterOffset == 1234)
        #expect(decoded.currentPage == 5)
        #expect(decoded.fileName == "test.txt")
    }
}
