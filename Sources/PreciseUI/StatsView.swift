import PreciseKit
import SwiftUI

/// How the word list stands, worked out from the words themselves: the counts in one sentence,
/// then every active word as a tick by tier and by difficulty, and the words saved each week.
public struct StatsView: View {
    @Environment(WordStore.self) private var store
    /// One width for every row name, so the tick tracks of every section start on the same line.
    @ScaledMetric(relativeTo: .subheadline) private var labelWidth: CGFloat = 76

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                if store.loaded {
                    content(WordStats(words: store.words, now: store.now))
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 32)
                        .frame(maxWidth: 640, alignment: .leading)
                        .frame(maxWidth: .infinity)
                } else if store.error == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 240)
                }
            }
            .background(Theme.canvas)
            .navigationTitle("Stats")
            #if os(iOS)
            .toolbarBackground(Theme.canvas, for: .navigationBar)
            #endif
            .refreshable { await store.refresh() }
        }
    }

    private func content(_ stats: WordStats) -> some View {
        VStack(alignment: .leading, spacing: 44) {
            summary(stats)
            section("Tiers", detail: "\(stats.activeCount) active") {
                rows(Tier.allCases.map { (label: $0.rawValue, count: stats.byTier[$0, default: 0]) }, of: stats.activeCount)
            }
            section("Difficulty", detail: "\(stats.activeCount) active") {
                rows(Difficulty.allCases.map { (label: $0.rawValue, count: stats.byDifficulty[$0, default: 0]) }, of: stats.activeCount)
            }
            section("Saved per week", detail: "last 8 weeks") {
                weeks(stats.weeklySaved)
            }
        }
    }

    /// The headline counts as a sentence, numbers heavy and white, words gray.
    private func summary(_ stats: WordStats) -> some View {
        let number = { (value: Int) in Text("\(value)").fontWeight(.heavy).foregroundStyle(.white) }
        let words = { (text: String) in Text(text).foregroundStyle(Theme.secondary) }
        // No-break spaces keep every number on the same line as the words it counts.
        let saved = stats.totalSaved == 1 ? "\u{00A0}word\u{00A0}saved, " : "\u{00A0}words\u{00A0}saved, "
        return VStack(alignment: .leading, spacing: 14) {
            Text("""
                \(number(stats.totalSaved))\(words(saved))\(number(stats.savedLast7Days))\(words("\u{00A0}in the last 7\u{00A0}days. "))\
                \(number(stats.dueNow))\(words("\u{00A0}due\u{00A0}now. "))\
                \(number(stats.learned))\(words("\u{00A0}learned, "))\(number(stats.known))\(words("\u{00A0}known."))
                """)
                .font(.title.weight(.semibold))
                .tracking(-0.4)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Text("Learned words have reached a review interval of \(Tier.matureDays) days. Known words are the ones you archived.")
                .font(TypeScale.note)
                .foregroundStyle(Theme.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func section(_ title: String, detail: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text(detail)
                    .font(TypeScale.statLabel.monospacedDigit())
                    .foregroundStyle(Theme.tertiary)
            }
            content()
        }
    }

    /// One row per group: its name, its words lit among all `total`, and the count.
    private func rows(_ groups: [(label: String, count: Int)], of total: Int) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 14) {
            ForEach(groups, id: \.label) { group in
                GridRow {
                    Text(group.label)
                        .font(TypeScale.statLabel)
                        .foregroundStyle(Theme.secondary)
                        .frame(width: labelWidth, alignment: .leading)
                    TickRow(lit: group.count, total: total)
                        .frame(height: 18)
                    Text("\(group.count)")
                        .font(TypeScale.statLabel.weight(.semibold).monospacedDigit())
                        .foregroundStyle(group.count == 0 ? Theme.tertiary : .white)
                        .gridColumnAlignment(.trailing)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(group.label): \(group.count) of \(total)")
            }
        }
    }

    private func weeks(_ weeks: [WordStats.WeekCount]) -> some View {
        let height: CGFloat = 120
        let pitch = TickLayout.pitch(count: weeks.map(\.count).max() ?? 0, length: height, preferred: TickLayout.columnPitch)
        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(weeks) { week in
                let date = week.weekStart.formatted(.dateTime.month(.abbreviated).day())
                VStack(spacing: 8) {
                    Text(week.count > 0 ? "\(week.count)" : "")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white)
                    TickColumn(count: week.count, pitch: pitch)
                        .frame(maxWidth: 26)
                        .frame(height: height)
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(Theme.tertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Week of \(date): \(week.count) saved")
            }
        }
    }
}
