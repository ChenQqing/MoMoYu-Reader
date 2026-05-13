import SwiftUI
import Combine

@main
struct NovelReaderApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView(appState: appState)
                .environmentObject(appState)
                .background(WindowAccessor { window in
                    appState.configureWindow(window)
                })
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("打开文件...") {
                    appState.showFilePicker()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .appSettings) {
                Button("设置...") {
                    appState.showSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

/// Main view that switches between library and reading
struct MainView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        if appState.isFileLoaded {
            ReadingView(
                readingVM: appState.readingVM,
                settingsVM: appState.settingsVM
            )
        } else {
            LibraryView(
                readingVM: appState.readingVM,
                settingsVM: appState.settingsVM
            )
        }
    }
}

/// Top-level app state coordinator
class AppState: ObservableObject {
    @Published var isSettingsOpen = false
    @Published var isFileLoaded = false

    let readingVM = ReadingViewModel()
    let settingsVM = SettingsViewModel()
    private let windowController = FloatingWindowController()

    init() {
        readingVM.$currentFileName
            .map { $0 != nil }
            .receive(on: RunLoop.main)
            .assign(to: &$isFileLoaded)

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.readingVM.saveState()
        }
    }

    func configureWindow(_ window: NSWindow) {
        window.level = .floating

        let settings = settingsVM.settings
        windowController.openWindow(
            size: NSSize(
                width: settings.windowWidth,
                height: settings.windowHeight
            ),
            content: MainView(appState: self)
        )

        window.close()
    }

    func showFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            try? readingVM.loadFile(at: url.path)
        }
    }

    func showSettings() {
        isSettingsOpen = true
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "设置"
        settingsWindow.contentView = NSHostingView(
            rootView: SettingsView(viewModel: settingsVM)
        )
        settingsWindow.center()
        settingsWindow.makeKeyAndOrderFront(nil)
    }
}

/// Helper to access the underlying NSWindow
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
