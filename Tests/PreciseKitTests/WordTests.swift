import Foundation
import PreciseKit
import Testing

@Test func decodesTheAPIsWord() throws {
    let json = """
        {"id": 7, "word": "idempotent", "part_of_speech": "adjective", "difficulty": "advanced",
         "definition": "Producing the same result however many times it is applied.",
         "phrase": "running it twice doesn't break anything", "rewrite": "Make the migration idempotent.",
         "created_at": "2026-11-15T21:00:00Z", "seen_at": null, "due_at": "2026-11-16T21:00:00Z",
         "interval_days": 1, "ease": 2.5, "reps": 1, "lapses": 0, "reviewed_at": "2026-11-15T21:00:00Z",
         "archived_at": null}
        """
    let word = try JSONCoding.decoder.decode(Word.self, from: Data(json.utf8))
    #expect(word.partOfSpeech == "adjective")
    #expect(word.difficulty == .advanced)
    #expect(word.isNew)
    #expect(!word.isArchived)
    #expect(!word.isDue(at: Date(timeIntervalSince1970: 1_794_000_000)))
    #expect(word.isDue(at: word.dueAt))

    let archivedJSON = json.replacingOccurrences(of: "\"archived_at\": null", with: "\"archived_at\": \"2026-11-16T22:00:00Z\"")
    let archived = try JSONCoding.decoder.decode(Word.self, from: Data(archivedJSON.utf8))
    #expect(archived.isArchived)
    #expect(!archived.isDue(at: archived.dueAt))
}

@Test func encodesANewWordInTheAPIsKeys() throws {
    let word = NewWord(
        word: "terse", partOfSpeech: "adjective", difficulty: .advanced,
        definition: "d", phrase: "p", rewrite: "r"
    )
    let json = String(decoding: try JSONCoding.encoder.encode(word), as: UTF8.self)
    #expect(json == #"{"definition":"d","difficulty":"advanced","part_of_speech":"adjective","phrase":"p","rewrite":"r","word":"terse"}"#)
}

@Test func roundTripsACaptureStatus() throws {
    let status = CaptureStatus(at: Date(timeIntervalSince1970: 1_794_000_000), outcome: .noWord)
    let json = try JSONCoding.encoder.encode(status)
    #expect(String(decoding: json, as: UTF8.self).contains(#""outcome":"no-word""#))
    #expect(try JSONCoding.decoder.decode(CaptureStatus.self, from: json) == status)
}
