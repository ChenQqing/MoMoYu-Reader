# NovelReader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS floating novel reader app with transparent background, hover-to-show text, and customizable reading experience.

**Architecture:** SwiftUI + AppKit hybrid. SwiftUI for views and settings, AppKit for NSWindow floating control and NSTrackingArea hover detection. Single-window reading view with independent settings window.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit, macOS 13+ (Ventura), Xcode project

---

## File Structure

```
NovelReader/
├── project.yml                          # XcodeGen project spec
├── NovelReader/
│   ├── Info.plist
│   ├── NovelReaderApp.swift             # App entry, window management
│   ├── Models/
│   │   ├── AppSettings.swift            # All user preferences
│   │   ├── ReadingState.swift           # Current reading position & state
│   │   └── Bookmark.swift              # Bookmark data model
│   ├── Services/
│   │   ├── FileManagerService.swift     # File reading + encoding detection
│   │   └── PersistenceService.swift     # UserDefaults + JSON read/write
│   ├── Views/
│   │   ├── ReadingView.swift            # Main reading view (scroll + page)
│   │   ├── ReadingContentView.swift     # Text rendering with hover support
│   │   ├── SettingsView.swift           # Settings window root view
│   │   └── SettingsComponents.swift     # Reusable settings controls
│   ├── ViewModels/
│   │   ├── ReadingViewModel.swift       # Reading logic, navigation, state
│   │   └── SettingsViewModel.swift      # Settings read/write, preview
│   ├── Window/
│   │   ├── FloatingWindow.swift         # NSWindow subclass with floating level
│   │   └── FloatingWindowController.swift # Window lifecycle, resize, drag
│   └── Utils/
│       └── EncodingDetector.swift       # UTF-8 / GBK encoding detection
└── NovelReaderTests/
    ├── Models/
    │   ├── AppSettingsTests.swift
    │   ├── ReadingStateTests.swift
    │   └── BookmarkTests.swift
    ├── Services/
    │   ├── FileManagerServiceTests.swift
    │   └── PersistenceServiceTests.swift
    ├── ViewModels/
    │   ├── ReadingViewModelTests.swift
    │   └── SettingsViewModelTests.swift
    └── Utils/
        └── EncodingDetectorTests.swift
```

---

### Task 1: Project Setup and Xcode Project Generation

**Files:**
- Create: `NovelReader/project.yml`
- Create: `NovelReader/NovelReader/Info.plist`
- Create: `NovelReader/NovelReader/NovelReaderApp.swift`
- Create: `NovelReader/NovelReader/Models/.gitkeep`
- Create: `NovelReader/NovelReader/Services/.gitkeep`
- Create: `NovelReader/NovelReader/Views/.gitkeep`
- Create: `NovelReader/NovelReader/ViewModels/.gitkeep`
- Create: `NovelReader/NovelReader/Window/.gitkeep`
- Create: `NovelReader/NovelReader/Utils/.gitkeep`
- Create: `NovelReader/NovelReaderTests/.gitkeep`

- [ ] **Step 1: Check if XcodeGen is installed, install if needed**

```bash
which xcodegen || brew install xcodegen
```

- [ ] **Step 2: Create XcodeGen project spec**

Create `NovelReader/project.yml`:

```yaml
name: NovelReader
options:
  bundleIdPrefix: com.novelreader
  deploymentTarget:
    macOS: "13.0"
  xcodeVersion: "15.0"
  generateEmptyDirectories: true

targets:
  NovelReader:
    type: application
    platform: macOS
    sources:
      - NovelReader
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.novelreader.app
        INFOPLIST_FILE: NovelReader/Info.plist
        SWIFT_VERSION: "5.9"
        MACOSX_DEPLOYMENT_TARGET: "13.0"
        CODE_SIGN_IDENTITY: "-"
        CODE_SIGNING_REQUIRED: "NO"
    scheme:
      testTargets:
        - NovelReaderTests

  NovelReaderTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - NovelReaderTests
    settings:
      base:
        SWIFT_VERSION: "5.9"
        MACOSX_DEPLOYMENT_TARGET: "13.0"
    dependencies:
      - target: NovelReader
```

- [ ] **Step 3: Create Info.plist**

Create `NovelReader/NovelReader/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>NovelReader</string>
    <key>CFBundleDisplayName</key>
    <string>NovelReader</string>
    <key>CFBundleIdentifier</key>
    <string>com.novelreader.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>NovelReader</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 4: Create app entry point**

Create `NovelReader/NovelReader/NovelReaderApp.swift`:

```swift
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
```

- [ ] **Step 5: Create placeholder directories**

```bash
mkdir -p NovelReader/NovelReader/{Models,Services,Views,ViewModels,Window,Utils}
mkdir -p NovelReader/NovelReaderTests/{Models,Services,ViewModels,Utils}
touch NovelReader/NovelReader/Models/.gitkeep
touch NovelReader/NovelReader/Services/.gitkeep
touch NovelReader/NovelReader/Views/.gitkeep
touch NovelReader/NovelReader/ViewModels/.gitkeep
touch NovelReader/NovelReader/Window/.gitkeep
touch NovelReader/NovelReader/Utils/.gitkeep
touch NovelReader/NovelReaderTests/.gitkeep
```

- [ ] **Step 6: Generate Xcode project**

```bash
cd NovelReader && xcodegen generate
```

Expected: `NovelReader.xcodeproj` generated successfully.

- [ ] **Step 7: Verify build compiles**

```bash
cd NovelReader && xcodebuild -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Commit**

```bash
cd /Users/jake/Documents/cc
git init
git add NovelReader/
git commit -m "feat: initial project setup with XcodeGen and SwiftUI app skeleton"
```

---

### Task 2: Data Models

**Files:**
- Create: `NovelReader/NovelReader/Models/AppSettings.swift`
- Create: `NovelReader/NovelReader/Models/ReadingState.swift`
- Create: `NovelReader/NovelReader/Models/Bookmark.swift`
- Create: `NovelReader/NovelReaderTests/Models/AppSettingsTests.swift`
- Create: `NovelReader/NovelReaderTests/Models/ReadingStateTests.swift`
- Create: `NovelReader/NovelReaderTests/Models/BookmarkTests.swift`

- [ ] **Step 1: Write AppSettings tests**

Create `NovelReader/NovelReaderTests/Models/AppSettingsTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -only-testing:NovelReaderTests/AppSettingsTests 2>&1 | tail -10
```

Expected: FAIL — `AppSettings` not found.

- [ ] **Step 3: Implement AppSettings**

Create `NovelReader/NovelReader/Models/AppSettings.swift`:

```swift
import SwiftUI

struct AppSettings: Codable {
    var fontSize: CGFloat = 16
    var fontName: String = "Helvetica"
    var lineSpacing: CGFloat = 1.5
    var textColor: CodableColor = CodableColor(.white)
    var backgroundColor: CodableColor = CodableColor(Color(red: 0.15, green: 0.15, blue: 0.15))
    var backgroundOpacity: Double = 0.85
    var hoverToShowEnabled: Bool = true
    var readingMode: ReadingMode = .scroll
    var windowWidth: CGFloat = 400
    var windowHeight: CGFloat = 600

    enum ReadingMode: String, Codable, CaseIterable {
        case scroll
        case pagination
    }
}

/// Wrapper to make SwiftUI Color Codable
struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ color: Color) {
        // Default to white if extraction fails
        self.red = 1; self.green = 1; self.blue = 1; self.alpha = 1
        // Extract from NSColor for reliability
        if let nsColor = NSColor(color).usingColorSpace(.deviceRGB) {
            self.red = Double(nsColor.redComponent)
            self.green = Double(nsColor.greenComponent)
            self.blue = Double(nsColor.blueComponent)
            self.alpha = Double(nsColor.alphaComponent)
        }
    }

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    var nsColor: NSColor {
        NSColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
}
```

- [ ] **Step 4: Run AppSettings tests**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -only-testing:NovelReaderTests/AppSettingsTests 2>&1 | tail -10
```

Expected: PASS

- [ ] **Step 5: Write ReadingState and Bookmark tests**

Create `NovelReader/NovelReaderTests/Models/ReadingStateTests.swift`:

```swift
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
```

Create `NovelReader/NovelReaderTests/Models/BookmarkTests.swift`:

```swift
import Testing
@testable import NovelReader

@Suite("Bookmark Tests")
struct BookmarkTests {
    @Test("Bookmark stores position and label")
    func testBookmarkCreation() {
        let bookmark = Bookmark(
            id: UUID(),
            characterOffset: 500,
            label: "Chapter 3",
            createdAt: Date()
        )
        #expect(bookmark.characterOffset == 500)
        #expect(bookmark.label == "Chapter 3")
    }

    @Test("Bookmark is Codable")
    func testCodable() throws {
        let bookmark = Bookmark(
            id: UUID(),
            characterOffset: 100,
            label: "Start",
            createdAt: Date()
        )
        let data = try JSONEncoder().encode(bookmark)
        let decoded = try JSONDecoder().decode(Bookmark.self, from: data)
        #expect(decoded.characterOffset == 100)
        #expect(decoded.label == "Start")
    }
}
```

- [ ] **Step 6: Implement ReadingState and Bookmark**

Create `NovelReader/NovelReader/Models/ReadingState.swift`:

```swift
import Foundation

struct ReadingState: Codable, Equatable {
    var characterOffset: Int = 0
    var currentPage: Int = 0
    var fileName: String?
    var lastOpened: Date = Date()
}
```

Create `NovelReader/NovelReader/Models/Bookmark.swift`:

```swift
import Foundation

struct Bookmark: Codable, Identifiable, Equatable {
    let id: UUID
    var characterOffset: Int
    var label: String
    var createdAt: Date
}
```

- [ ] **Step 7: Run all model tests**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -only-testing:NovelReaderTests 2>&1 | tail -10
```

Expected: All tests PASS.

- [ ] **Step 8: Commit**

```bash
git add NovelReader/NovelReader/Models/ NovelReader/NovelReaderTests/Models/
git commit -m "feat: add data models (AppSettings, ReadingState, Bookmark)"
```

---

### Task 3: Encoding Detection and File Reading Service

**Files:**
- Create: `NovelReader/NovelReader/Utils/EncodingDetector.swift`
- Create: `NovelReader/NovelReader/Services/FileManagerService.swift`
- Create: `NovelReader/NovelReaderTests/Utils/EncodingDetectorTests.swift`
- Create: `NovelReader/NovelReaderTests/Services/FileManagerServiceTests.swift`

- [ ] **Step 1: Write EncodingDetector tests**

Create `NovelReader/NovelReaderTests/Utils/EncodingDetectorTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -only-testing:NovelReaderTests/EncodingDetectorTests 2>&1 | tail -10
```

Expected: FAIL — `EncodingDetector` not found.

- [ ] **Step 3: Implement EncodingDetector**

Create `NovelReader/NovelReader/Utils/EncodingDetector.swift`:

```swift
import Foundation

enum EncodingDetector {
    /// Detect text encoding from raw data.
    /// Checks BOM first, then tries UTF-8, then falls back to GBK.
    static func detectEncoding(for data: Data) -> String.Encoding {
        guard !data.isEmpty else { return .utf8 }

        // Check for UTF-8 BOM
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            return .utf8
        }

        // Check for UTF-16 BOM
        if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) {
            return .utf16
        }

        // Try UTF-8 validation
        if let _ = String(data: data, encoding: .utf8) {
            return .utf8
        }

        // Try GBK (GB18030 superset)
        if let _ = String(data: data, encoding: .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))) {
            return .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        }

        // Final fallback
        return .utf8
    }
}
```

- [ ] **Step 4: Run EncodingDetector tests**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -only-testing:NovelReaderTests/EncodingDetectorTests 2>&1 | tail -10
```

Expected: PASS

- [ ] **Step 5: Write FileManagerService tests**

Create `NovelReader/NovelReaderTests/Services/FileManagerServiceTests.swift`:

```swift
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
```

- [ ] **Step 6: Implement FileManagerService**

Create `NovelReader/NovelReader/Services/FileManagerService.swift`:

```swift
import Foundation

enum FileManagerServiceError: LocalizedError {
    case fileNotFound
    case readError(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "File not found"
        case .readError(let msg): return "Read error: \(msg)"
        }
    }
}

struct FileReadResult {
    let text: String
    let paragraphs: [String]
    let encoding: String.Encoding
}

enum FileManagerService {
    /// Read a .txt file with automatic encoding detection.
    static func readFile(at path: String) throws -> FileReadResult {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw FileManagerServiceError.fileNotFound
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw FileManagerServiceError.readError(error.localizedDescription)
        }

        let encoding = EncodingDetector.detectEncoding(for: data)
        guard let text = String(data: data, encoding: encoding) else {
            throw FileManagerServiceError.readError("Unable to decode file with detected encoding")
        }

        let paragraphs = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return FileReadResult(text: text, paragraphs: paragraphs, encoding: encoding)
    }
}
```

- [ ] **Step 7: Run FileManagerService tests**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -only-testing:NovelReaderTests/FileManagerServiceTests 2>&1 | tail -10
```

Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add NovelReader/NovelReader/Utils/ NovelReader/NovelReader/Services/
git commit -m "feat: add encoding detection and file reading service"
```

---

### Task 4: Floating Window Infrastructure

**Files:**
- Create: `NovelReader/NovelReader/Window/FloatingWindow.swift`
- Create: `NovelReader/NovelReader/Window/FloatingWindowController.swift`

- [ ] **Step 1: Create FloatingWindow NSWindow subclass**

Create `NovelReader/NovelReader/Window/FloatingWindow.swift`:

```swift
import AppKit
import SwiftUI

/// NSWindow subclass configured for floating above all other windows.
class FloatingWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        // Float above all windows
        self.level = .floating

        // Transparent background support
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true

        // Title bar
        self.title = "NovelReader"
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden

        // Allow dragging from content area
        self.isMovableByWindowBackground = true

        // Minimum size
        self.minSize = NSSize(width: 250, height: 300)
    }

    /// Update window background based on settings
    func applyBackground(color: NSColor, opacity: Double) {
        if opacity <= 0.01 {
            self.backgroundColor = .clear
            self.isOpaque = false
            self.hasShadow = false
        } else {
            self.backgroundColor = color.withAlphaComponent(CGFloat(opacity))
            self.isOpaque = false
            self.hasShadow = true
        }
    }
}
```

- [ ] **Step 2: Create FloatingWindowController**

Create `NovelReader/NovelReader/Window/FloatingWindowController.swift`:

```swift
import AppKit
import SwiftUI

/// Manages the floating reading window lifecycle.
class FloatingWindowController {
    private var window: FloatingWindow?
    private var hostingView: NSHostingView<AnyView>?

    func openWindow<Content: View>(
        size: NSSize,
        content: Content
    ) {
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.midY - size.height / 2
        )
        let rect = NSRect(origin: origin, size: size)

        let floatingWindow = FloatingWindow(contentRect: rect)
        let hosting = NSHostingView(rootView: AnyView(content))
        hosting.frame = floatingWindow.contentView!.bounds
        hosting.autoresizingMask = [.width, .height]

        floatingWindow.contentView?.addSubview(hosting)
        floatingWindow.makeKeyAndOrderFront(nil)

        self.window = floatingWindow
        self.hostingView = hosting
    }

    func closeWindow() {
        window?.close()
        window = nil
        hostingView = nil
    }

    func updateBackground(color: NSColor, opacity: Double) {
        window?.applyBackground(color: color, opacity: opacity)
    }

    var isVisible: Bool {
        window?.isVisible ?? false
    }
}
```

- [ ] **Step 3: Verify build compiles**

```bash
cd NovelReader && xcodebuild -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add NovelReader/NovelReader/Window/
git commit -m "feat: add floating window infrastructure (NSWindow + controller)"
```

---

### Task 5: Persistence Service

**Files:**
- Create: `NovelReader/NovelReader/Services/PersistenceService.swift`
- Create: `NovelReader/NovelReaderTests/Services/PersistenceServiceTests.swift`

- [ ] **Step 1: Write PersistenceService tests**

Create `NovelReader/NovelReaderTests/Services/PersistenceServiceTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -only-testing:NovelReaderTests/PersistenceServiceTests 2>&1 | tail -10
```

Expected: FAIL — `PersistenceService` not found.

- [ ] **Step 3: Implement PersistenceService**

Create `NovelReader/NovelReader/Services/PersistenceService.swift`:

```swift
import Foundation

enum PersistenceService {
    private enum Keys {
        static let settings = "NovelReader.Settings"
        static let readingState = "NovelReader.ReadingState"
        static let bookmarks = "NovelReader.Bookmarks"
    }

    // MARK: - Settings

    static func saveSettings(_ settings: AppSettings, to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Keys.settings)
        }
    }

    static func loadSettings(from defaults: UserDefaults = .standard) -> AppSettings {
        guard let data = defaults.data(forKey: Keys.settings),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    // MARK: - Reading State

    static func saveReadingState(_ state: ReadingState, to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Keys.readingState)
        }
    }

    static func loadReadingState(from defaults: UserDefaults = .standard) -> ReadingState? {
        guard let data = defaults.data(forKey: Keys.readingState) else { return nil }
        return try? JSONDecoder().decode(ReadingState.self, from: data)
    }

    // MARK: - Bookmarks

    static func saveBookmarks(_ bookmarks: [Bookmark], fileName: String) {
        let url = bookmarksURL(for: fileName)
        if let data = try? JSONEncoder().encode(bookmarks) {
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: url)
        }
    }

    static func loadBookmarks(fileName: String) -> [Bookmark] {
        let url = bookmarksURL(for: fileName)
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Bookmark].self, from: data)) ?? []
    }

    private static func bookmarksURL(for fileName: String) -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let safeName = fileName.replacingOccurrences(of: "/", with: "_")
        return appSupport.appendingPathComponent("NovelReader/Bookmarks/\(safeName).json")
    }
}
```

- [ ] **Step 4: Run PersistenceService tests**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -only-testing:NovelReaderTests/PersistenceServiceTests 2>&1 | tail -10
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add NovelReader/NovelReader/Services/PersistenceService.swift NovelReader/NovelReaderTests/Services/
git commit -m "feat: add persistence service for settings, reading state, and bookmarks"
```

---

### Task 6: Reading ViewModel

**Files:**
- Create: `NovelReader/NovelReader/ViewModels/ReadingViewModel.swift`
- Create: `NovelReader/NovelReaderTests/ViewModels/ReadingViewModelTests.swift`

- [ ] **Step 1: Write ReadingViewModel tests**

Create `NovelReader/NovelReaderTests/ViewModels/ReadingViewModelTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -only-testing:NovelReaderTests/ReadingViewModelTests 2>&1 | tail -10
```

Expected: FAIL — `ReadingViewModel` not found.

- [ ] **Step 3: Implement ReadingViewModel**

Create `NovelReader/NovelReader/ViewModels/ReadingViewModel.swift`:

```swift
import Foundation
import Combine

class ReadingViewModel: ObservableObject {
    @Published var paragraphs: [String] = []
    @Published var fullText: String = ""
    @Published var currentFileName: String?
    @Published var characterOffset: Int = 0
    @Published var currentPage: Int = 0
    @Published var bookmarks: [Bookmark] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Load a .txt file and restore reading position.
    func loadFile(at path: String) throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = try FileManagerService.readFile(at: path)
        fullText = result.text
        paragraphs = result.paragraphs
        currentFileName = (path as NSString).lastPathComponent

        // Load bookmarks
        if let fileName = currentFileName {
            bookmarks = PersistenceService.loadBookmarks(fileName: fileName)
        }

        // Restore reading position
        if let fileName = currentFileName,
           let state = PersistenceService.loadReadingState(),
           state.fileName == fileName {
            characterOffset = min(state.characterOffset, fullText.count)
            currentPage = state.currentPage
        } else {
            characterOffset = 0
            currentPage = 0
        }
    }

    /// Navigate to a specific character offset.
    func navigateToOffset(_ offset: Int) {
        characterOffset = max(0, min(offset, fullText.count))
        saveState()
    }

    /// Navigate to a specific page (pagination mode).
    func navigateToPage(_ page: Int) {
        currentPage = max(0, page)
        saveState()
    }

    /// Add a bookmark at current position.
    func addBookmark(label: String) {
        let bookmark = Bookmark(
            id: UUID(),
            characterOffset: characterOffset,
            label: label,
            createdAt: Date()
        )
        bookmarks.append(bookmark)
        if let fileName = currentFileName {
            PersistenceService.saveBookmarks(bookmarks, fileName: fileName)
        }
    }

    /// Remove a bookmark by ID.
    func removeBookmark(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        if let fileName = currentFileName {
            PersistenceService.saveBookmarks(bookmarks, fileName: fileName)
        }
    }

    /// Navigate to a bookmark's position.
    func goToBookmark(_ bookmark: Bookmark) {
        navigateToOffset(bookmark.characterOffset)
    }

    /// Save current reading state.
    func saveState() {
        guard let fileName = currentFileName else { return }
        var state = ReadingState()
        state.characterOffset = characterOffset
        state.currentPage = currentPage
        state.fileName = fileName
        state.lastOpened = Date()
        PersistenceService.saveReadingState(state)
    }
}
```

- [ ] **Step 4: Run ReadingViewModel tests**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -only-testing:NovelReaderTests/ReadingViewModelTests 2>&1 | tail -10
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add NovelReader/NovelReader/ViewModels/ReadingViewModel.swift NovelReader/NovelReaderTests/ViewModels/
git commit -m "feat: add reading view model with file loading, navigation, bookmarks"
```

---

### Task 7: Settings ViewModel

**Files:**
- Create: `NovelReader/NovelReader/ViewModels/SettingsViewModel.swift`
- Create: `NovelReader/NovelReaderTests/ViewModels/SettingsViewModelTests.swift`

- [ ] **Step 1: Write SettingsViewModel tests**

Create `NovelReader/NovelReaderTests/ViewModels/SettingsViewModelTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -only-testing:NovelReaderTests/SettingsViewModelTests 2>&1 | tail -10
```

Expected: FAIL — `SettingsViewModel` not found.

- [ ] **Step 3: Implement SettingsViewModel**

Create `NovelReader/NovelReader/ViewModels/SettingsViewModel.swift`:

```swift
import Foundation
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
```

- [ ] **Step 4: Run SettingsViewModel tests**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -only-testing:NovelReaderTests/SettingsViewModelTests 2>&1 | tail -10
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add NovelReader/NovelReader/ViewModels/SettingsViewModel.swift NovelReader/NovelReaderTests/ViewModels/SettingsViewModelTests.swift
git commit -m "feat: add settings view model with auto-persistence"
```

---

### Task 8: Reading Content View with Hover Support

**Files:**
- Create: `NovelReader/NovelReader/Views/ReadingContentView.swift`

- [ ] **Step 1: Create ReadingContentView with NSTrackingArea hover detection**

Create `NovelReader/NovelReader/Views/ReadingContentView.swift`:

```swift
import SwiftUI
import AppKit

/// NSViewRepresentable that wraps an NSTextView with hover detection.
struct ReadingContentView: NSViewRepresentable {
    let text: String
    let font: NSFont
    let textColor: NSColor
    let lineSpacing: CGFloat
    let hoverToShowEnabled: Bool
    @Binding var isHovering: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 10, height: 10)

        // Configure tracking area
        let trackingArea = NSTrackingArea(
            rect: scrollView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: context.coordinator,
            userInfo: nil
        )
        scrollView.addTrackingArea(trackingArea)

        context.coordinator.scrollView = scrollView
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        textView.textStorage?.setAttributedString(
            NSAttributedString(string: text, attributes: attributes)
        )

        // Update hover opacity
        let opacity: Double = hoverToShowEnabled ? (isHovering ? 1.0 : 0.0) : 1.0
        textView.alphaValue = CGFloat(opacity)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isHovering: $isHovering)
    }

    class Coordinator: NSObject {
        var isHovering: Binding<Bool>
        weak var scrollView: NSScrollView?
        weak var textView: NSTextView?

        init(isHovering: Binding<Bool>) {
            self.isHovering = isHovering
        }

        override func mouseEntered(with event: NSEvent) {
            DispatchQueue.main.async {
                self.isHovering.wrappedValue = true
            }
        }

        override func mouseExited(with event: NSEvent) {
            DispatchQueue.main.async {
                self.isHovering.wrappedValue = false
            }
        }
    }
}
```

- [ ] **Step 2: Verify build compiles**

```bash
cd NovelReader && xcodebuild -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add NovelReader/NovelReader/Views/ReadingContentView.swift
git commit -m "feat: add reading content view with hover-to-show text support"
```

---

### Task 9: Main Reading View

**Files:**
- Create: `NovelReader/NovelReader/Views/ReadingView.swift`

- [ ] **Step 1: Create the main ReadingView**

Create `NovelReader/NovelReader/Views/ReadingView.swift`:

```swift
import SwiftUI

struct ReadingView: View {
    @ObservedObject var readingVM: ReadingViewModel
    @ObservedObject var settingsVM: SettingsViewModel
    @State private var isHovering = false
    @State private var showFilePicker = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Background
            backgroundView

            // Content
            if readingVM.fullText.isEmpty {
                emptyStateView
            } else {
                readingContentView
            }
        }
        .frame(
            minWidth: 250, idealWidth: settingsVM.settings.windowWidth,
            minHeight: 300, idealHeight: settingsVM.settings.windowHeight
        )
        .toolbar {
            ToolbarItemGroup {
                Button(action: { showFilePicker = true }) {
                    Image(systemName: "doc.badge.plus")
                }
                .help("Open File (⌘O)")

                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                }
                .help("Settings (⌘,)")

                Button(action: { readingVM.addBookmark(label: "Bookmark \(readingVM.bookmarks.count + 1)") }) {
                    Image(systemName: "bookmark")
                }
                .help("Add Bookmark")
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.plainText]
        ) { result in
            if case .success(let url) = result {
                try? readingVM.loadFile(at: url.path)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: settingsVM)
        }
        .onAppear {
            isHovering = true // Start visible
        }
        .onDisappear {
            readingVM.saveState()
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        let settings = settingsVM.settings
        if settings.backgroundOpacity <= 0.01 {
            Color.clear
        } else {
            settings.backgroundColor.color
                .opacity(settings.backgroundOpacity)
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Open a .txt file to start reading")
                .font(.headline)
                .foregroundColor(.secondary)
            Button("Open File") {
                showFilePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private var readingContentView: some View {
        ReadingContentView(
            text: readingVM.fullText,
            font: NSFont(
                name: settingsVM.settings.fontName,
                size: settingsVM.settings.fontSize
            ) ?? NSFont.systemFont(ofSize: settingsVM.settings.fontSize),
            textColor: settingsVM.settings.textColor.nsColor,
            lineSpacing: settingsVM.settings.lineSpacing,
            hoverToShowEnabled: settingsVM.settings.hoverToShowEnabled,
            isHovering: $isHovering
        )
        .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
}
```

- [ ] **Step 2: Verify build compiles**

```bash
cd NovelReader && xcodebuild -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add NovelReader/NovelReader/Views/ReadingView.swift
git commit -m "feat: add main reading view with toolbar and file picker"
```

---

### Task 10: Settings View

**Files:**
- Create: `NovelReader/NovelReader/Views/SettingsComponents.swift`
- Create: `NovelReader/NovelReader/Views/SettingsView.swift`

- [ ] **Step 1: Create reusable settings components**

Create `NovelReader/NovelReader/Views/SettingsComponents.swift`:

```swift
import SwiftUI

/// Color picker that binds to CodableColor
struct CodableColorPicker: View {
    let title: String
    @Binding var color: CodableColor

    var body: some View {
        ColorPicker(title, selection: Binding(
            get: { color.color },
            set: { newColor in
                color = CodableColor(newColor)
            }
        ))
    }
}

/// Opacity slider with label
struct OpacitySlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(title)
            Slider(value: $value, in: 0...1, step: 0.05)
            Text("\(Int(value * 100))%")
                .monospacedDigit()
                .frame(width: 40)
        }
    }
}

/// Font picker dropdown
struct FontPicker: View {
    @Binding var fontName: String
    let availableFonts: [String]

    var body: some View {
        Picker("Font", selection: $fontName) {
            ForEach(availableFonts, id: \.self) { name in
                Text(name).font(.custom(name, size: 14))
            }
        }
    }
}
```

- [ ] **Step 2: Create SettingsView**

Create `NovelReader/NovelReader/Views/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("Appearance") {
                    CodableColorPicker(
                        title: "Text Color",
                        color: $viewModel.settings.textColor
                    )
                    CodableColorPicker(
                        title: "Background Color",
                        color: $viewModel.settings.backgroundColor
                    )
                    OpacitySlider(
                        title: "Background Opacity",
                        value: $viewModel.settings.backgroundOpacity
                    )
                }

                Section("Font") {
                    FontPicker(
                        fontName: $viewModel.settings.fontName,
                        availableFonts: SettingsViewModel.availableFontNames
                    )
                    HStack {
                        Text("Size")
                        Slider(value: $viewModel.settings.fontSize, in: 12...36, step: 1)
                        Text("\(Int(viewModel.settings.fontSize))pt")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                    HStack {
                        Text("Line Spacing")
                        Slider(value: $viewModel.settings.lineSpacing, in: 1.0...3.0, step: 0.1)
                        Text(String(format: "%.1f", viewModel.settings.lineSpacing))
                            .monospacedDigit()
                            .frame(width: 30)
                    }
                }

                Section("Behavior") {
                    Toggle("Show text on hover only", isOn: $viewModel.settings.hoverToShowEnabled)
                    Picker("Reading Mode", selection: $viewModel.settings.readingMode) {
                        Text("Scroll").tag(AppSettings.ReadingMode.scroll)
                        Text("Pagination").tag(AppSettings.ReadingMode.pagination)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Window") {
                    HStack {
                        Text("Width")
                        Slider(value: $viewModel.settings.windowWidth, in: 250...1200, step: 10)
                        Text("\(Int(viewModel.settings.windowWidth))px")
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                    HStack {
                        Text("Height")
                        Slider(value: $viewModel.settings.windowHeight, in: 300...1000, step: 10)
                        Text("\(Int(viewModel.settings.windowHeight))px")
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Reset to Defaults") {
                    viewModel.resetToDefaults()
                }
                .foregroundColor(.red)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 350, height: 450)
    }
}
```

- [ ] **Step 3: Verify build compiles**

```bash
cd NovelReader && xcodebuild -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add NovelReader/NovelReader/Views/SettingsView.swift NovelReader/NovelReader/Views/SettingsComponents.swift
git commit -m "feat: add settings view with color, font, opacity, and behavior controls"
```

---

### Task 11: App Entry Point Integration and Keyboard Shortcuts

**Files:**
- Modify: `NovelReader/NovelReader/NovelReaderApp.swift`

- [ ] **Step 1: Rewrite NovelReaderApp to wire everything together**

Replace `NovelReader/NovelReader/NovelReaderApp.swift`:

```swift
import SwiftUI

@main
struct NovelReaderApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ReadingView(
                readingVM: appState.readingVM,
                settingsVM: appState.settingsVM
            )
            .environmentObject(appState)
            .onAppear {
                appState.openFileIfNeeded()
            }
            .background(WindowAccessor { window in
                appState.configureWindow(window)
            })
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open File...") {
                    appState.showFilePicker()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appState.showSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

/// Top-level app state coordinator
class AppState: ObservableObject {
    @Published var isSettingsOpen = false

    let readingVM = ReadingViewModel()
    let settingsVM = SettingsViewModel()
    private let windowController = FloatingWindowController()

    func openFileIfNeeded() {
        // On first launch, prompt for file
        if readingVM.currentFileName == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showFilePicker()
            }
        }
    }

    func configureWindow(_ window: NSWindow) {
        // Apply floating level
        window.level = .floating

        // Apply background from settings
        let settings = settingsVM.settings
        windowController.openWindow(
            size: NSSize(
                width: settings.windowWidth,
                height: settings.windowHeight
            ),
            content: ReadingView(
                readingVM: readingVM,
                settingsVM: settingsVM
            )
        )

        // Close the default window, use our floating one
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
        settingsWindow.title = "Settings"
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
```

- [ ] **Step 2: Verify build compiles**

```bash
cd NovelReader && xcodebuild -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add NovelReader/NovelReader/NovelReaderApp.swift
git commit -m "feat: integrate all components with app entry point and keyboard shortcuts"
```

---

### Task 12: Final Build, Test, and Polish

**Files:**
- Modify: `NovelReader/project.yml` (if needed)
- Modify: Various files for bug fixes

- [ ] **Step 1: Run full test suite**

```bash
cd NovelReader && xcodebuild test -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' 2>&1 | tail -20
```

Expected: All tests PASS.

- [ ] **Step 2: Build release configuration**

```bash
cd NovelReader && xcodebuild -project NovelReader.xcodeproj -scheme NovelReader -destination 'platform=macOS' -configuration Release build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Locate and verify the app bundle**

```bash
find ~/Library/Developer/Xcode/DerivedData -name "NovelReader.app" -type d 2>/dev/null | head -1
```

Expected: Path to built `.app` bundle.

- [ ] **Step 4: Test the app manually**

```bash
# Launch the app
open "$(find ~/Library/Developer/Xcode/DerivedData -name 'NovelReader.app' -type d 2>/dev/null | head -1)"
```

Manual verification checklist:
- App launches and shows file picker
- Selecting a .txt file opens the floating reading window
- Window stays on top of other windows
- Background color and opacity can be changed in settings
- Hover-to-show text works when enabled
- Reading position is saved and restored
- Keyboard shortcuts work (⌘O, ⌘,)

- [ ] **Step 5: Fix any issues found during manual testing**

Address bugs found in step 4.

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "feat: NovelReader v1.0 - macOS floating novel reader"
```
