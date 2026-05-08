import Testing
@testable import NovelReader

@Suite("SettingsViewModel Tests")
struct SettingsViewModelTests {
    @Test("Load settings from persistence")
    func testLoadSettings() {
        let vm = SettingsViewModel()
        // Should load defaults if nothing saved
        #expect(vm.settings.fontSize == 16)
    }

    @Test("Update fontSize persists change")
    func testUpdateFontSize() {
        let vm = SettingsViewModel()
        vm.settings.fontSize = 24
        vm.save()

        let reloaded = SettingsViewModel()
        // Note: In real test we'd use injected UserDefaults
        #expect(reloaded.settings.fontSize == 24)
    }
}
