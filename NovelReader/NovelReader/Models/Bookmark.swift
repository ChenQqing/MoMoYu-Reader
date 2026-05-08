import Foundation

struct Bookmark: Codable, Identifiable, Equatable {
    let id: UUID
    var characterOffset: Int
    var label: String
    var createdAt: Date
}
