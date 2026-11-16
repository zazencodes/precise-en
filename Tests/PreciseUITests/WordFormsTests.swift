import Testing

@testable import PreciseUI

@Test func findsTheWordInAnyForm() {
    let text = "Synchronize the words; synchronizing them keeps devices in sync. Resynchronize never."
    let found = WordForms.ranges(of: "synchronize", in: text).map { String(text[$0]) }
    #expect(found == ["Synchronize", "synchronizing"])
    let terse = "Be terse: write tersely, with terseness."
    #expect(WordForms.ranges(of: "terse", in: terse).map { String(terse[$0]) } == ["terse", "tersely", "terseness"])
    #expect(WordForms.ranges(of: "fault-tolerant", in: "Make it fault-tolerant.").count == 1)
}
