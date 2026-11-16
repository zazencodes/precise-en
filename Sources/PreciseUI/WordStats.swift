import Foundation
import PreciseKit

/// Learning metrics derived purely from the saved `Word` list, with no separate history API.
public struct WordStats: Equatable, Sendable {
    public struct WeekCount: Identifiable, Equatable, Sendable {
        public let weekStart: Date
        public let count: Int
        public var id: Date { weekStart }

        public init(weekStart: Date, count: Int) {
            self.weekStart = weekStart
            self.count = count
        }
    }

    public let totalSaved: Int
    public let savedLast7Days: Int
    /// Active words whose review interval has reached Anki's mature threshold (21+ days).
    public let learned: Int
    /// Words archived as already known.
    public let known: Int
    public let dueNow: Int
    public let activeCount: Int
    public let byTier: [Tier: Int]
    public let byDifficulty: [Difficulty: Int]
    public let weeklySaved: [WeekCount]

    public init(words: [Word], now: Date = Date(), calendar: Calendar = .current) {
        let active = words.filter { !$0.isArchived }
        self.totalSaved = words.count
        self.savedLast7Days = Self.countSavedInLast7Days(words, now: now, calendar: calendar)
        self.learned = active.filter { $0.tier == .mature }.count
        self.known = words.count - active.count
        self.dueNow = active.filter { $0.isDue(at: now) }.count
        self.activeCount = active.count
        self.byTier = Self.countByTier(active)
        self.byDifficulty = Self.countByDifficulty(active)
        self.weeklySaved = Self.countSavedPerWeek(words, weeks: 8, now: now, calendar: calendar)
    }

    public static func countSavedInLast7Days(
        _ words: [Word], now: Date = Date(), calendar: Calendar = .current
    ) -> Int {
        guard let cutoff = calendar.date(byAdding: .day, value: -7, to: now) else { return 0 }
        return words.filter { $0.createdAt >= cutoff && $0.createdAt <= now }.count
    }

    public static func countByTier(_ words: [Word]) -> [Tier: Int] {
        var counts = Dictionary(uniqueKeysWithValues: Tier.allCases.map { ($0, 0) })
        for word in words where !word.isArchived {
            counts[word.tier, default: 0] += 1
        }
        return counts
    }

    public static func countByDifficulty(_ words: [Word]) -> [Difficulty: Int] {
        var counts = Dictionary(uniqueKeysWithValues: Difficulty.allCases.map { ($0, 0) })
        for word in words where !word.isArchived {
            counts[word.difficulty, default: 0] += 1
        }
        return counts
    }

    public static func countSavedPerWeek(
        _ words: [Word], weeks: Int = 8, now: Date = Date(), calendar: Calendar = .current
    ) -> [WeekCount] {
        guard weeks > 0, let currentWeek = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return []
        }
        return (-(weeks - 1)...0).compactMap { offset in
            guard let weekAnchor = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeek.start),
                  let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekAnchor)
            else { return nil }
            let count = words.filter { word in
                word.createdAt >= weekInterval.start && word.createdAt < weekInterval.end
            }.count
            return WeekCount(weekStart: weekInterval.start, count: count)
        }
    }
}
