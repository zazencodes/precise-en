import Foundation
import Testing

@testable import PreciseKit
@testable import PreciseUI

private func makeWord(
    id: Int,
    difficulty: Difficulty = .advanced,
    createdAt: Date,
    dueAt: Date? = nil,
    intervalDays: Int = 0,
    reviewedAt: Date? = nil,
    archivedAt: Date? = nil
) -> Word {
    Word(
        id: id,
        word: "word\(id)",
        partOfSpeech: "verb",
        difficulty: difficulty,
        definition: "definition",
        phrase: "phrase",
        rewrite: "rewrite",
        createdAt: createdAt,
        seenAt: nil,
        dueAt: dueAt ?? createdAt,
        intervalDays: intervalDays,
        reps: reviewedAt == nil ? 0 : 1,
        lapses: 0,
        reviewedAt: reviewedAt,
        archivedAt: archivedAt
    )
}

private var utcCalendar: Calendar {
    var calendar = Calendar(identifier: .iso8601)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}

private func utcDate(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
    utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}

@Test func emptyStatsHaveZeroCountsAndEightWeeks() {
    let now = utcDate(2026, 11, 15)
    let stats = WordStats(words: [], now: now, calendar: utcCalendar)
    #expect(stats.totalSaved == 0)
    #expect(stats.savedLast7Days == 0)
    #expect(stats.learned == 0)
    #expect(stats.known == 0)
    #expect(stats.dueNow == 0)
    #expect(stats.activeCount == 0)
    #expect(stats.byTier == [.new: 0, .learning: 0, .young: 0, .mature: 0])
    #expect(stats.byDifficulty == [.common: 0, .advanced: 0, .rare: 0])
    #expect(stats.weeklySaved.count == 8)
    #expect(stats.weeklySaved.allSatisfy { $0.count == 0 })
}

@Test func countsSavedLastSevenDaysAtExactBoundary() {
    let now = utcDate(2026, 11, 15, hour: 12)
    let words = [
        makeWord(id: 1, createdAt: utcDate(2026, 11, 8, hour: 12)),  // exactly 7 days ago -> included
        makeWord(id: 2, createdAt: utcDate(2026, 11, 8, hour: 11)),  // 7 days + 1 hour ago -> excluded
        makeWord(id: 3, createdAt: utcDate(2026, 11, 15, hour: 12), archivedAt: now),  // archived today -> included
        makeWord(id: 4, createdAt: utcDate(2026, 11, 16, hour: 12)), // future -> excluded
    ]
    #expect(WordStats.countSavedInLast7Days(words, now: now, calendar: utcCalendar) == 2)
}

@Test func countsSummaryTiersAndDifficultiesExcludingArchived() {
    let now = utcDate(2026, 11, 15)
    let yesterday = utcDate(2026, 11, 14)
    let tomorrow = utcDate(2026, 11, 16)

    let words = [
        // Active new, common, due now
        makeWord(id: 1, difficulty: .common, createdAt: yesterday, dueAt: yesterday),
        // Active learning (reviewed, 0d), advanced, due now
        makeWord(id: 2, difficulty: .advanced, createdAt: yesterday, dueAt: now, intervalDays: 0, reviewedAt: yesterday),
        // Active young (20d < 21), rare, not due
        makeWord(id: 3, difficulty: .rare, createdAt: yesterday, dueAt: tomorrow, intervalDays: 20, reviewedAt: yesterday),
        // Active mature (21d), rare, not due -> counts as learned
        makeWord(id: 4, difficulty: .rare, createdAt: yesterday, dueAt: tomorrow, intervalDays: 21, reviewedAt: yesterday),
        // Archived mature word -> counts as known, not learned, not due, not in active tier/difficulty
        makeWord(id: 5, difficulty: .common, createdAt: yesterday, dueAt: yesterday, intervalDays: 30, reviewedAt: yesterday, archivedAt: now),
    ]

    let stats = WordStats(words: words, now: now, calendar: utcCalendar)
    #expect(stats.totalSaved == 5)
    #expect(stats.learned == 1)
    #expect(stats.known == 1)
    #expect(stats.dueNow == 2)
    #expect(stats.activeCount == 4)
    #expect(stats.byTier == [.new: 1, .learning: 1, .young: 1, .mature: 1])
    #expect(stats.byDifficulty == [.common: 1, .advanced: 1, .rare: 2])
}

@Test func countsSavedPerWeekOverEightWeeksAcrossYearBoundary() {
    // 2026-01-07 is Wednesday in ISO week 2 of 2026 (starts Mon 2026-01-05).
    // 8-week window starts 7 weeks prior: Mon 2025-11-17.
    let now = utcDate(2026, 1, 7)
    let words = [
        makeWord(id: 1, createdAt: utcDate(2025, 11, 16, hour: 23)), // week before window -> excluded
        makeWord(id: 2, createdAt: utcDate(2025, 11, 17, hour: 0)),  // bucket 0 (oldest)
        makeWord(id: 3, createdAt: utcDate(2025, 12, 29, hour: 10), archivedAt: now), // bucket 6 (archived still counts)
        makeWord(id: 4, createdAt: utcDate(2026, 1, 2, hour: 18)),   // bucket 6 (same ISO week Dec 29..Jan 4)
        makeWord(id: 5, createdAt: utcDate(2026, 1, 5, hour: 9)),    // bucket 7 (current week)
    ]

    let weekly = WordStats.countSavedPerWeek(words, weeks: 8, now: now, calendar: utcCalendar)
    #expect(weekly.count == 8)
    #expect(weekly.map(\.count) == [1, 0, 0, 0, 0, 0, 2, 1])
    #expect(weekly.first?.weekStart == utcDate(2025, 11, 17, hour: 0))
    #expect(weekly.last?.weekStart == utcDate(2026, 1, 5, hour: 0))
}
