import SwiftUI

struct LibraryView: View {
    @ObservedObject var readingVM: ReadingViewModel
    @ObservedObject var settingsVM: SettingsViewModel
    @State private var books: [BookItem] = []
    @State private var showFilePicker = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            backgroundView

            if books.isEmpty {
                emptyStateView
            } else {
                bookListView
            }
        }
        .frame(minWidth: 300, idealWidth: 400, minHeight: 400, idealHeight: 500)
        .contextMenu {
            Button("添加书籍") { showFilePicker = true }
            Button("设置") { showSettings = true }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.plainText],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                addBooks(urls: urls)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: settingsVM)
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
                showFilePicker = true
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
                Button(action: { showFilePicker = true }) {
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

    private func addBooks(urls: [URL]) {
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            let filePath = url.path
            let fileName = url.lastPathComponent

            // Don't add duplicates
            if books.contains(where: { $0.filePath == filePath }) {
                // Update last opened
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
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index].lastOpened = Date()
            PersistenceService.saveBooks(books)
        }
        try? readingVM.loadFile(at: book.filePath)
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
        .onTapGesture { onTap() }
        .contextMenu {
            Button("打开") { onTap() }
            Button("删除", role: .destructive) { onDelete() }
        }
    }
}
