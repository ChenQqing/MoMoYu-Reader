import SwiftUI

@main
struct NovelReaderApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

/// Top-level app state coordinator
class AppState: ObservableObject {
    @Published var isSettingsOpen = false
    @Published var currentFilePath: String?

    let readingVM = ReadingViewModel()
    let settingsVM = SettingsViewModel()
}
