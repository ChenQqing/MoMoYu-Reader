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
