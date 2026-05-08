import Testing
import Foundation
@testable import NovelReader

@Suite("ReadingViewModel Tests")
struct ReadingViewModelTests {
    @Test("Load file populates paragraphs")
    func testLoadFile() throws {
        let tmpDir = FileManager.default.temporaryDirectory
        let fileURL = tmpDir.appendingPathComponent("test_\(UUID().uuidString).txt")
        let content = "第一段内容\n\n第二段内容\n\n第三段内容"
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let vm = ReadingViewModel()
        try vm.loadFile(at: fileURL.path)

        #expect(vm.paragraphs.count == 3)
        #expect(vm.paragraphs[0] == "第一段内容")
        #expect(vm.currentFileName == fileURL.lastPathComponent)
    }

    @Test("Navigate to offset updates characterOffset")
    func testNavigateToOffset() throws {
        let tmpDir = FileManager.default.temporaryDirectory
        let fileURL = tmpDir.appendingPathComponent("test_\(UUID().uuidString).txt")
        try "Hello World".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let vm = ReadingViewModel()
        try vm.loadFile(at: fileURL.path)
        vm.navigateToOffset(5)

        #expect(vm.characterOffset == 5)
    }

    @Test("Add bookmark creates entry")
    func testAddBookmark() throws {
        let tmpDir = FileManager.default.temporaryDirectory
        let fileURL = tmpDir.appendingPathComponent("test_\(UUID().uuidString).txt")
        try "Some content".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let vm = ReadingViewModel()
        try vm.loadFile(at: fileURL.path)
        vm.addBookmark(label: "Test Mark")

        #expect(vm.bookmarks.count == 1)
        #expect(vm.bookmarks[0].label == "Test Mark")
    }
}
