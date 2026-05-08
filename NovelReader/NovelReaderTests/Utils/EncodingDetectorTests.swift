import Testing
@testable import NovelReader

@Suite("EncodingDetector Tests")
struct EncodingDetectorTests {
    @Test("Detects UTF-8 encoded data")
    func testUTF8Detection() throws {
        let text = "Hello, 你好世界"
        let data = text.data(using: .utf8)!
        let encoding = EncodingDetector.detectEncoding(for: data)
        #expect(encoding == .utf8)
    }

    @Test("Falls back to UTF-8 for small or empty data")
    func testEmptyData() {
        let data = Data()
        let encoding = EncodingDetector.detectEncoding(for: data)
        #expect(encoding == .utf8)
    }
}
