import Foundation
import AppKit
import Combine

class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            save()
        }
    }

    init() {
        self.settings = PersistenceService.loadSettings()
    }

    func save() {
        PersistenceService.saveSettings(settings)
    }

    func resetToDefaults() {
        settings = AppSettings()
    }

    /// Get all available system font names
    static var availableFontNames: [String] {
        NSFontManager.shared.availableFontFamilies
    }
}
