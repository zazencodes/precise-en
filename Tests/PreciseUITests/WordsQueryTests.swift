import Foundation
import PreciseKit
import Testing

@testable import PreciseUI

private func makeWord(
    id: Int,
    word: String,
    difficulty: Difficulty = .advanced,
    definition: String = "A clear definition.",
    createdAt: Date = Date(timeIntervalSince1970: 1_794_800_000),
    dueAt: Date = Date(timeIntervalSince1970: 1_794_800_000),
    intervalDays: Int = 0,
    reviewedAt: Date? = nil,
    archivedAt: Date? = nil
) -> Word {
    let iso = ISO8601DateFormatter()
    var payload: [String: Any] = [
        "id": id,
        "word": word,
        "part_of_speech": "adjective",
        "difficulty": difficulty.rawValue,
        "definition": definition,
        "phrase": "some phrase",
        "rewrite": "Some rewrite with \(word).",
        "created_at": iso.string(from: createdAt),
        "due_at": iso.string(from: dueAt),
        "interval_days": intervalDays,
        "reps": reviewedAt == nil ? 0 : 1,
        "lapses": 0,
    ]
    payload["seen_at"] = NSNull()
    payload["reviewed_at"] = reviewedAt.map { iso.string(from: $0) } ?? NSNull()
    payload["archived_at"] = archivedAt.map { iso.string(from: $0) } ?? NSNull()
    let data = try! JSONSerialization.data(withJSONObject: payload)
    return try! JSONCoding.decoder.decode(Word.self, from: data)
}

@Test func filtersByDifficulty() {
    let words = [
        makeWord(id: 1, word: "relocate", difficulty: .common),
        makeWord(id: 2, word: "idempotent", difficulty: .advanced),
        makeWord(id: 3, word: "perspicacious", difficulty: .rare),
    ]

    #expect(WordsQuery.filter(words, difficulty: .all, query: "").map(\.word) == ["relocate", "idempotent", "perspicacious"])
    #expect(WordsQuery.filter(words, difficulty: .common, query: "").map(\.word) == ["relocate"])
    #expect(WordsQuery.filter(words, difficulty: .advanced, query: "").map(\.word) == ["idempotent"])
    #expect(WordsQuery.filter(words, difficulty: .rare, query: "").map(\.word) == ["perspicacious"])
}

@Test func matchesWordAndDefinitionCaseInsensitively() {
    let words = [
        makeWord(id: 1, word: "Terse", definition: "Brief and to the point."),
        makeWord(id: 2, word: "Caveat", definition: "A warning of specific stipulations."),
        makeWord(id: 3, word: "Rudimentary", definition: "Involving basic principles."),
    ]

    #expect(WordsQuery.filter(words, difficulty: .all, query: "  ").map(\.word) == ["Terse", "Caveat", "Rudimentary"])
    #expect(WordsQuery.filter(words, difficulty: .all, query: "ters").map(\.word) == ["Terse"])
    #expect(WordsQuery.filter(words, difficulty: .all, query: "WARNING").map(\.word) == ["Caveat"])
    #expect(WordsQuery.filter(words, difficulty: .all, query: "  basic ").map(\.word) == ["Rudimentary"])
    #expect(WordsQuery.filter(words, difficulty: .all, query: "nonexistent").isEmpty)
}

@Test func combinesFilterSearchAndSort() {
    let base = Date(timeIntervalSince1970: 1_794_800_000)
    let words = [
        makeWord(id: 1, word: "zeta", difficulty: .advanced, definition: "Last letter", createdAt: base.addingTimeInterval(100)),
        makeWord(id: 2, word: "Alpha", difficulty: .advanced, definition: "First letter", createdAt: base.addingTimeInterval(300)),
        makeWord(id: 3, word: "beta", difficulty: .common, definition: "Second letter", createdAt: base.addingTimeInterval(200)),
    ]

    let newest = WordsQuery.visible(words, difficulty: .advanced, query: "letter", sort: .newest)
    #expect(newest.map(\.word) == ["Alpha", "zeta"])

    let alpha = WordsQuery.visible(words, difficulty: .all, query: "", sort: .alphabetical)
    #expect(alpha.map(\.word) == ["Alpha", "beta", "zeta"])
}

@Test func sortsNewestWithDeterministicIdTieBreaker() {
    let sameDate = Date(timeIntervalSince1970: 1_794_800_000)
    let words = [
        makeWord(id: 2, word: "second", createdAt: sameDate),
        makeWord(id: 5, word: "fifth", createdAt: sameDate),
    ]
    #expect(WordsQuery.sort(words, by: .newest).map(\.id) == [5, 2])
}

@Test func listsScheduleFactsForActiveNewAndArchivedWords() {
    let now = Date(timeIntervalSince1970: 1_794_800_000) // 2026-11-15
    let threeDaysOut = Calendar.current.date(byAdding: .day, value: 3, to: now)!
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    let saved = now.formatted(.dateTime.month(.abbreviated).day())

    let young = makeWord(id: 1, word: "terse", createdAt: now, dueAt: threeDaysOut, intervalDays: 3, reviewedAt: yesterday)
    #expect(WordsQuery.scheduleFacts(for: young, now: now) == [
        .init(label: "Tier", value: "Young"),
        .init(label: "Saved", value: saved),
        .init(label: "Next review", value: "In 3 days"),
        .init(label: "Last review", value: "Yesterday"),
    ])

    let fresh = makeWord(id: 2, word: "caveat", createdAt: now, dueAt: now)
    #expect(WordsQuery.scheduleFacts(for: fresh, now: now) == [
        .init(label: "Tier", value: "New"),
        .init(label: "Saved", value: saved),
        .init(label: "Next review", value: "Due now"),
        .init(label: "Last review", value: "Never"),
    ])

    let archived = makeWord(id: 3, word: "relocate", createdAt: now, archivedAt: now)
    #expect(WordsQuery.scheduleFacts(for: archived, now: now) == [
        .init(label: "Tier", value: "New"),
        .init(label: "Saved", value: saved),
        .init(label: "Archived", value: saved),
        .init(label: "Last review", value: "Never"),
    ])
}
