import Foundation

struct BookItem: Codable, Identifiable, Equatable {
    let id: UUID
    var fileName: String
    var filePath: String
    var lastOpened: Date
    var addedAt: Date

    init(fileName: String, filePath: String) {
        self.id = UUID()
        self.fileName = fileName
        self.filePath = filePath
        self.lastOpened = Date()
        self.addedAt = Date()
    }
}
