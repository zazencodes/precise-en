import Testing

@testable import PreciseUI

@Test func ticksKeepTheirPitchUntilTheyRunOutOfRoom() {
    #expect(TickLayout.pitch(count: 10, length: 300, preferred: 14) == 14)
    #expect(TickLayout.pitch(count: 35, length: 245, preferred: 14) == 7)
    #expect(TickLayout.pitch(count: 0, length: 245, preferred: 14) == 14)
}
