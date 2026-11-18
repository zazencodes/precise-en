import Foundation

/// A word saved from one of your prompts, with where it stands in review.
public struct Word: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let word: String
    public let partOfSpeech: String
    public let difficulty: Difficulty
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
    public let reps: Int
    public let lapses: Int
    public let reviewedAt: Date?
    /// Set when you swipe the word away as one you already know. An archived word is never
    /// reviewed or suggested again, and stays saved so the capture hook can tell it is taken.
    public let archivedAt: Date?

    public var isNew: Bool { seenAt == nil }

    public var isArchived: Bool { archivedAt != nil }

    public func isDue(at now: Date) -> Bool { !isArchived && dueAt <= now }

    /// Where the word is in review, by Anki's names.
    public var tier: Tier {
        if reviewedAt == nil { return .new }
        if intervalDays == 0 { return .learning }
        return intervalDays < Tier.matureDays ? .young : .mature
    }
}

/// How hard the word is, judged by the background agent when it suggests the word.
public enum Difficulty: String, Codable, CaseIterable, Sendable {
    /// An everyday word most writers use without thinking: relocate, delegate.
    case common
    /// A word educated writers know but rarely reach for: superfluous, idempotent.
    case advanced
    /// A word few people know or use: perspicacious, anfractuous.
    case rare

    public var title: String { rawValue.capitalized }
}

/// Anki's stages of a card: never reviewed, relearning after Again, then young and mature by interval.
public enum Tier: String, CaseIterable, Sendable {
    case new, learning, young, mature

    /// Anki calls a card mature once its interval reaches 21 days.
    public static let matureDays = 21

    public var title: String { rawValue.capitalized }
}

/// Whether you remembered a word: pass/fail grading, as Japanese learners use Anki.
public enum Rating: String, Codable, CaseIterable, Sendable {
    case again, good

    public var title: String { rawValue.capitalized }
}

/// A word the capture hook asks the API to save.
public struct NewWord: Codable, Equatable, Sendable {
    public let word: String
    public let partOfSpeech: String
    public let difficulty: Difficulty
    public let definition: String
    public let phrase: String
    public let rewrite: String

    public init(
        word: String, partOfSpeech: String, difficulty: Difficulty, definition: String, phrase: String, rewrite: String
    ) {
        self.word = word
        self.partOfSpeech = partOfSpeech
        self.difficulty = difficulty
        self.definition = definition
        self.phrase = phrase
        self.rewrite = rewrite
    }
}
