import Testing
import Foundation
@testable import NovelReader

@Suite("PersistenceService Tests")
struct PersistenceServiceTests {
    let suiteName = "TestSuite_\(UUID().uuidString)"
    lazy var defaults = UserDefaults(suiteName: suiteName)!

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("Save and load AppSettings roundtrip")
    func testSettingsRoundtrip() {
        var settings = AppSettings()
        settings.fontSize = 22
        settings.hoverToShowEnabled = false

        PersistenceService.saveSettings(settings, to: defaults)
        let loaded = PersistenceService.loadSettings(from: defaults)

        #expect(loaded.fontSize == 22)
        #expect(loaded.hoverToShowEnabled == false)
    }

    @Test("Save and load ReadingState roundtrip")
    func testReadingStateRoundtrip() {
        var state = ReadingState()
        state.characterOffset = 999
        state.fileName = "novel.txt"

        PersistenceService.saveReadingState(state, to: defaults)
        let loaded = PersistenceService.loadReadingState(from: defaults)

        #expect(loaded?.characterOffset == 999)
        #expect(loaded?.fileName == "novel.txt")
    }

    @Test("Load settings returns defaults when nothing saved")
    func testLoadDefaults() {
        let freshDefaults = UserDefaults(suiteName: "Empty_\(UUID().uuidString)")!
        let settings = PersistenceService.loadSettings(from: freshDefaults)
        #expect(settings.fontSize == 16) // default value
    }
}
