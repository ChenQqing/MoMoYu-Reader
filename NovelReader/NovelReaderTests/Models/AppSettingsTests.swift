import Testing
@testable import NovelReader

@Suite("AppSettings Tests")
struct AppSettingsTests {
    @Test("Default settings have correct values")
    func testDefaults() {
        let settings = AppSettings()
        #expect(settings.fontSize == 16)
        #expect(settings.fontName == "Helvetica")
        #expect(settings.lineSpacing == 1.5)
        #expect(settings.textColor == .white)
        #expect(settings.backgroundOpacity == 0.85)
        #expect(settings.hoverToShowEnabled == true)
        #expect(settings.readingMode == .scroll)
    }

    @Test("Codable roundtrip preserves all fields")
    func testCodableRoundtrip() throws {
        var settings = AppSettings()
        settings.fontSize = 20
        settings.lineSpacing = 2.0
        settings.hoverToShowEnabled = false

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        #expect(decoded.fontSize == 20)
        #expect(decoded.lineSpacing == 2.0)
        #expect(decoded.hoverToShowEnabled == false)
    }
}
