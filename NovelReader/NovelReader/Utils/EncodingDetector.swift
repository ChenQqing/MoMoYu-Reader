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
