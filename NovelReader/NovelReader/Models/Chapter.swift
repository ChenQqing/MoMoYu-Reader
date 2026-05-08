import Foundation

struct Chapter: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let offset: Int
}
