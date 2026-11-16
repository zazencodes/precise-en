import Foundation
import PreciseKit

/// The difficulty filter at the top of the words list.
public enum WordsFilter: String, CaseIterable, Hashable, Sendable {
    case all
    case common
    case advanced
    case rare

    public var title: String {
        switch self {
        case .all: "All"
        case .common: Difficulty.common.title
        case .advanced: Difficulty.advanced.title
        case .rare: Difficulty.rare.title
        }
    }

    public var difficulty: Difficulty? {
        switch self {
        case .all: nil
        case .common: .common
        case .advanced: .advanced
        case .rare: .rare
        }
    }
}

/// Sort orders available in the words toolbar menu.
public enum WordsSort: String, CaseIterable, Hashable, Sendable {
    case newest
    case alphabetical

    public var title: String {
        switch self {
        case .newest: "Newest"
        case .alphabetical: "A–Z"
        }
    }
}

/// Plain filtering, sorting and search for the words list, and the schedule facts on a word's page.
enum WordsQuery {
    static func matches(_ word: Word, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return word.word.localizedCaseInsensitiveContains(trimmed)
            || word.definition.localizedCaseInsensitiveContains(trimmed)
    }

    static func filter(_ words: [Word], difficulty: WordsFilter, query: String) -> [Word] {
        words.filter { word in
            if let required = difficulty.difficulty, word.difficulty != required {
                return false
            }
            return matches(word, query: query)
        }
    }

    static func sort(_ words: [Word], by order: WordsSort) -> [Word] {
        words.sorted { lhs, rhs in
            switch order {
            case .newest:
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
                return lhs.id > rhs.id
            case .alphabetical:
                let comparison = lhs.word.localizedCaseInsensitiveCompare(rhs.word)
                if comparison != .orderedSame { return comparison == .orderedAscending }
                return lhs.id < rhs.id
            }
        }
    }

    static func visible(
        _ words: [Word],
        difficulty: WordsFilter,
        query: String,
        sort order: WordsSort
    ) -> [Word] {
        sort(filter(words, difficulty: difficulty, query: query), by: order)
    }

    /// One line of a word's place in review, shown under its meaning on the word's page.
    struct Fact: Equatable {
        let label: String
        let value: String
    }

    static func scheduleFacts(for word: Word, now: Date) -> [Fact] {
        var facts = [
            Fact(label: "Tier", value: word.tier.title),
            Fact(label: "Saved", value: shortDate(word.createdAt, relativeTo: now)),
        ]
        if let archivedAt = word.archivedAt {
            facts.append(Fact(label: "Archived", value: shortDate(archivedAt, relativeTo: now)))
        } else {
            let next = word.isDue(at: now) ? "Due now" : sentenceCase(relativeDate(word.dueAt, relativeTo: now))
            facts.append(Fact(label: "Next review", value: next))
        }
        let last = word.reviewedAt.map { sentenceCase(relativeDate($0, relativeTo: now)) } ?? "Never"
        facts.append(Fact(label: "Last review", value: last))
        return facts
    }

    private static func sentenceCase(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }

    private static func shortDate(_ date: Date, relativeTo now: Date) -> String {
        if Calendar.current.isDate(date, equalTo: now, toGranularity: .year) {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private static func relativeDate(_ date: Date, relativeTo now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
