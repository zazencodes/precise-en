import Foundation
import PreciseKit

/// What the capture hook does with a prompt: decide whether it is worth a word, ask the
/// background agent for one, and check the answer before saving it.
enum Capture {
    /// Shorter prompts are skipped: there is too little of your writing to improve.
    static let minimumWords = 50
    /// The rest of a longer prompt (usually pasted material) is not sent to the background agent.
    static let maximumCharacters = 20_000

    static func wordCount(_ prompt: String) -> Int {
        prompt.split(whereSeparator: \.isWhitespace).count
    }

    static func isWorthAWord(_ prompt: String) -> Bool {
        wordCount(prompt) >= minimumWords
    }

    static func agentPrompt(for prompt: String, saved: [String]) -> String {
        """
        You coach a software engineer's English vocabulary. They write long prompts to AI coding \
        agents. Read their prompt below and find the one English word that would most improve it: a \
        precise or expressive word that could replace a longer or vaguer phrase they actually wrote.

        Rules:
        - The word replaces a phrase they wrote: put it in the phrase's place (changing a word or two \
        around it if needed) and the sentence says the same thing in fewer words, or says it more \
        exactly. It is never a synonym of a word they already used.
        - Suggest a word only when it clearly sharpens the prompt. If the prompt is already precise, \
        or no single word replaces something in it, answer {"word": null}.
        - The word is a real, general English word that is useful in many prompts, the kind an \
        educated writer knows but rarely reaches for (like terse, idempotent, verbatim, canonical, \
        orthogonal, distill). No proper nouns, acronyms or names of tools and libraries.
        - Write the word in lowercase, in its dictionary form.
        - The word must not appear anywhere in the prompt, and must not be one of their saved words.
        - "phrase" is their own wording that the word replaces, copied exactly from the prompt: a \
        few words, at most one sentence.
        - "rewrite" restates the prompt's main request in one or two concise sentences that use the \
        word.
        - "definition" is a one-sentence dictionary definition of the word in the sense you mean.
        - "part_of_speech" is noun, verb, adjective or adverb.
        - Ignore code, logs and other pasted material: judge only their own writing.

        Answer with only a JSON object, no Markdown and no other text:
        {"word": "idempotent", "part_of_speech": "adjective", "definition": "...", "phrase": "...", "rewrite": "..."}
        or
        {"word": null}

        Their saved words: \(saved.isEmpty ? "none yet" : saved.sorted().joined(separator: ", "))

        Their prompt:
        <prompt>
        \(prompt.prefix(maximumCharacters))
        </prompt>
        """
    }

    enum Answer: Equatable {
        case none
        case word(NewWord)
    }

    struct ContractError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// The background agent must answer with exactly the JSON object the prompt asks for.
    static func parse(_ output: String) throws -> Answer {
        let text = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let object = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any] else {
            throw ContractError(message: "background agent did not answer with a JSON object: \(text.prefix(300))")
        }
        guard let value = object["word"] else {
            throw ContractError(message: "background agent's answer has no \"word\": \(text.prefix(300))")
        }
        if value is NSNull { return .none }
        func field(_ key: String) throws -> String {
            guard let string = object[key] as? String, !string.isEmpty else {
                throw ContractError(message: "background agent's answer has no \"\(key)\": \(text.prefix(300))")
            }
            return string
        }
        return .word(NewWord(
            word: try field("word"),
            partOfSpeech: try field("part_of_speech"),
            definition: try field("definition"),
            phrase: try field("phrase"),
            rewrite: try field("rewrite")
        ))
    }

    /// Why a suggested word cannot be used, or nil when it can.
    static func rejection(of word: NewWord, prompt: String) -> String? {
        let text = normalized(prompt)
        if text.range(of: "\\b\(NSRegularExpression.escapedPattern(for: word.word.lowercased()))\\b",
                      options: .regularExpression) != nil {
            return "\(word.word) is already in the prompt"
        }
        if !text.contains(normalized(word.phrase)) {
            return "the phrase \"\(word.phrase)\" is not in the prompt"
        }
        return nil
    }

    /// Lowercased with straight quotes and single spaces, so a copied phrase matches its source.
    static func normalized(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "[\u{2018}\u{2019}]", with: "'", options: .regularExpression)
            .replacingOccurrences(of: "[\u{201C}\u{201D}]", with: "\"", options: .regularExpression)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
