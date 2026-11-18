#if os(macOS)
import Foundation

/// The result of the capture hook's latest attempt. The CLI writes it after every prompt it
/// looks at; the Mac app reads it to show when capturing is failing.
public struct CaptureStatus: Codable, Equatable, Sendable {
    public enum Outcome: String, Codable, Sendable {
        /// The word was saved.
        case added
        /// The background agent found nothing worth a word.
        case noWord = "no-word"
        /// The word is already saved.
        case duplicate
        /// The background agent's word broke a rule (it was already in the prompt, say).
        case rejected
        case dailyLimit = "daily-limit"
        /// Something is broken: the background agent, the API or the config.
        case failed
    }

    public let at: Date
    public let outcome: Outcome
    public let word: String?
    public let detail: String?

    public init(at: Date, outcome: Outcome, word: String? = nil, detail: String? = nil) {
        self.at = at
        self.outcome = outcome
        self.word = word
        self.detail = detail
    }

    /// `~/.local/state/precise-en`: the capture log and the latest status.
    public static var stateDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser.appending(path: ".local/state/precise-en")
    }

    public static var url: URL { stateDirectory.appending(path: "last-capture.json") }
    public static var logURL: URL { stateDirectory.appending(path: "capture.log") }

    /// Nil when no prompt has been captured yet.
    public static func read() throws -> CaptureStatus? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONCoding.decoder.decode(CaptureStatus.self, from: Data(contentsOf: url))
    }

    public func write() throws {
        try FileManager.default.createDirectory(at: Self.stateDirectory, withIntermediateDirectories: true)
        try JSONCoding.encoder.encode(self).write(to: Self.url, options: .atomic)
    }
}
#endif
