import Foundation

enum WordForms {
    /// Where the word appears in the text in any form: whole words that begin with it, or with it
    /// minus a final e (synchronize → synchronizing).
    static func ranges(of word: String, in text: String) -> [Range<String.Index>] {
        let stems = [word, word.hasSuffix("e") ? String(word.dropLast()) : nil]
            .compactMap { $0 }
            .map(NSRegularExpression.escapedPattern(for:))
        let pattern = try! NSRegularExpression(pattern: "\\b(?:\(stems.joined(separator: "|")))[\\w-]*", options: .caseInsensitive)
        return pattern.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range, in: text) }
    }
}
