import PreciseKit
import Testing

@testable import PreciseCLI

let prompt = """
    The migration script keeps failing when I run it a second time on the staging database, so \
    please make sure running it twice doesn't break anything, and check the seed data too.
    """

let word = NewWord(
    word: "idempotent",
    partOfSpeech: "adjective",
    definition: "Producing the same result however many times it is applied.",
    phrase: "make sure running it twice doesn't break anything",
    rewrite: "Make the migration idempotent and check the seed data."
)

@Test func onlyLongPromptsAreWorthAWord() {
    #expect(!Capture.isWorthAWord("commit this"))
    #expect(!Capture.isWorthAWord(String(repeating: "word ", count: 49)))
    #expect(Capture.isWorthAWord(String(repeating: "word\n", count: 50)))
}

@Test func theAgentPromptCarriesThePromptAndSavedWords() {
    let text = Capture.agentPrompt(for: prompt, saved: ["terse", "canonical"])
    #expect(text.contains("Their saved words: canonical, terse"))
    #expect(text.contains("<prompt>\n\(prompt)\n</prompt>"))
    #expect(Capture.agentPrompt(for: prompt, saved: []).contains("Their saved words: none yet"))
}

@Test func parsesAWordOrNone() throws {
    #expect(try Capture.parse(#"  {"word": null}  "#) == .none)
    let answer = """
        {"word": "idempotent", "part_of_speech": "adjective",
         "definition": "Producing the same result however many times it is applied.",
         "phrase": "make sure running it twice doesn't break anything",
         "rewrite": "Make the migration idempotent and check the seed data."}
        """
    #expect(try Capture.parse(answer) == .word(word))
}

@Test func refusesAnythingButTheAgreedJSON() {
    #expect(throws: Capture.ContractError.self) { try Capture.parse("idempotent") }
    #expect(throws: Capture.ContractError.self) { try Capture.parse("```json\n{\"word\": null}\n```") }
    #expect(throws: Capture.ContractError.self) { try Capture.parse(#"{"answer": "terse"}"#) }
    #expect(throws: Capture.ContractError.self) { try Capture.parse(#"{"word": "terse", "definition": "x"}"#) }
}

@Test func acceptsAWordWhosePhraseIsInThePrompt() {
    #expect(Capture.rejection(of: word, prompt: prompt) == nil)
    let curly = prompt.replacingOccurrences(of: "doesn't", with: "doesn\u{2019}t")
    #expect(Capture.rejection(of: word, prompt: curly) == nil)
}

@Test func rejectsAWordAlreadyInThePromptOrAnInventedPhrase() {
    #expect(Capture.rejection(of: word, prompt: prompt + " Keep it Idempotent.") == "idempotent is already in the prompt")
    let invented = NewWord(
        word: word.word, partOfSpeech: word.partOfSpeech, definition: word.definition,
        phrase: "ensure reruns are harmless", rewrite: word.rewrite
    )
    #expect(Capture.rejection(of: invented, prompt: prompt) == "the phrase \"ensure reruns are harmless\" is not in the prompt")
}
