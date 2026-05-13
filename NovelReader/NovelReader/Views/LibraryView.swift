import SwiftUI

struct LibraryView: View {
    @ObservedObject var readingVM: ReadingViewModel
    @ObservedObject var settingsVM: SettingsViewModel
    @State private var books: [BookItem] = []
    @State private var showSettings = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            backgroundView
                .onTapGesture(count: 2) { showAddBookPicker() }

            if books.isEmpty {
                emptyStateView
            } else {
                bookListView
            }
        }
        .frame(minWidth: 300, idealWidth: 400, minHeight: 400, idealHeight: 500)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: settingsVM)
        }
        .alert("错误", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("确定", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            books = PersistenceService.loadBooks()
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

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("书库为空")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("右键点击添加书籍，或点击下方按钮")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("添加书籍") {
                showAddBookPicker()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var bookListView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("书库")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showAddBookPicker() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("添加书籍")
                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("设置")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Book list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(books) { book in
                        BookRow(book: book) {
                            openBook(book)
                        } onDelete: {
                            deleteBook(book)
                        }
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
    }

    private func showAddBookPicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            addBooks(urls: panel.urls)
        }
    }

    private func addBooks(urls: [URL]) {
        for url in urls {
            let filePath = url.path
            let fileName = url.lastPathComponent

            guard FileManager.default.fileExists(atPath: filePath) else {
                errorMessage = "文件不存在: \(fileName)"
                continue
            }

            // Don't add duplicates
            if books.contains(where: { $0.filePath == filePath }) {
                if let index = books.firstIndex(where: { $0.filePath == filePath }) {
                    books[index].lastOpened = Date()
                }
                continue
            }

            var book = BookItem(fileName: fileName, filePath: filePath)
            book.addedAt = Date()
            books.append(book)
        }
        PersistenceService.saveBooks(books)
    }

    private func openBook(_ book: BookItem) {
        guard FileManager.default.fileExists(atPath: book.filePath) else {
            errorMessage = "文件不存在或已被移动: \(book.fileName)"
            return
        }

        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index].lastOpened = Date()
            PersistenceService.saveBooks(books)
        }

        do {
            try readingVM.loadFile(at: book.filePath)
        } catch {
            errorMessage = "无法打开文件: \(error.localizedDescription)"
        }
    }

    private func deleteBook(_ book: BookItem) {
        books.removeAll { $0.id == book.id }
        PersistenceService.saveBooks(books)
    }
}

struct BookRow: View {
    let book: BookItem
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.fileName)
                    .font(.body)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                Text("上次打开: \(book.lastOpened, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button("打开") { onTap() }
            Button("删除", role: .destructive) { onDelete() }
        }
    }
}
