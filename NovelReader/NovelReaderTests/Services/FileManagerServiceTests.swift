import Testing
import Foundation
@testable import NovelReader

@Suite("FileManagerService Tests")
struct FileManagerServiceTests {
    @Test("Reads UTF-8 text file correctly")
    func testReadUTF8File() throws {
        let tmpDir = FileManager.default.temporaryDirectory
        let fileURL = tmpDir.appendingPathComponent("test_\(UUID().uuidString).txt")
        let content = "第一章\n这是一个测试小说。\n第二章\n这是第二章内容。"
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        defer { try? FileManager.default.removeItem(at: fileURL) }

        let result = try FileManagerService.readFile(at: fileURL.path)
        #expect(result.text == content)
        #expect(result.paragraphs.count == 4)
        #expect(result.paragraphs[0] == "第一章")
    }

    @Test("Throws error for non-existent file")
    func testNonExistentFile() {
        #expect(throws: FileManagerServiceError.self) {
            try FileManagerService.readFile(at: "/nonexistent/path.txt")
        }
    }
}
