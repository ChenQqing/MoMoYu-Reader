import Foundation

struct ReadingState: Codable, Equatable {
    var characterOffset: Int = 0
    var currentPage: Int = 0
    var fileName: String?
    var lastOpened: Date = Date()
}
