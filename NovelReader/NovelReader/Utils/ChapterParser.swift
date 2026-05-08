import Foundation

enum ChapterParser {
    /// Parse chapter titles and their character offsets from text.
    static func parseChapters(from text: String) -> [Chapter] {
        let patterns = [
            "第[零一二三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟0-9]+[章回节卷部篇集]",
            "Chapter\\s+\\d+",
            "CHAPTER\\s+\\d+",
            "卷[零一二三四五六七八九十百千万0-9]+",
        ]

        let combinedPattern = patterns.joined(separator: "|")
        guard let regex = try? NSRegularExpression(pattern: combinedPattern, options: []) else {
            return []
        }

        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        let matches = regex.matches(in: text, options: [], range: fullRange)

        return matches.compactMap { match in
            guard match.range.location != NSNotFound else { return nil }
            // Get the full line containing the match
            let matchStart = match.range.location
            // Find line start
            var lineStart = matchStart
            while lineStart > 0 {
                let prev = lineStart - 1
                let c = nsString.character(at: prev)
                if c == 0x000A || c == 0x000D { break } // newline
                lineStart = prev
            }
            // Find line end
            var lineEnd = matchStart + match.range.length
            while lineEnd < nsString.length {
                let c = nsString.character(at: lineEnd)
                if c == 0x000A || c == 0x000D { break }
                lineEnd += 1
            }
            let lineRange = NSRange(location: lineStart, length: lineEnd - lineStart)
            let title = nsString.substring(with: lineRange).trimmingCharacters(in: .whitespaces)
            return Chapter(title: title, offset: match.range.location)
        }
    }
}
