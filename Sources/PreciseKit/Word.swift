import Foundation

/// A word saved from one of your prompts, with where it stands in review.
public struct Word: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let word: String
    public let partOfSpeech: String
    public let definition: String
    /// Your own wording that the word replaces, copied from the prompt.
    public let phrase: String
    /// The prompt restated concisely with the word.
    public let rewrite: String
    public let createdAt: Date
    /// Nil until the word is first opened in an app: a new word.
    public let seenAt: Date?
    public let dueAt: Date
    public let intervalDays: Int
    public let ease: Double
    public let reps: Int
    public let lapses: Int
    public let reviewedAt: Date?

    public var isNew: Bool { seenAt == nil }

    public func isDue(at now: Date) -> Bool { dueAt <= now }
}

/// How well you remembered a word, as in Anki.
public enum Rating: String, Codable, CaseIterable, Sendable {
    case again, hard, good, easy

    public var title: String { rawValue.capitalized }
}

/// A word the capture hook asks the API to save.
public struct NewWord: Codable, Equatable, Sendable {
    public let word: String
    public let partOfSpeech: String
    public let definition: String
    public let phrase: String
    public let rewrite: String

    public init(word: String, partOfSpeech: String, definition: String, phrase: String, rewrite: String) {
        self.word = word
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.phrase = phrase
        self.rewrite = rewrite
    }
}
