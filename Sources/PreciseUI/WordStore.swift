import Foundation
import Observation
import PreciseKit

/// The word list as the apps see it: loaded from the API, with every change sent straight back.
@MainActor
@Observable
public final class WordStore {
    public private(set) var words: [Word] = []
    /// False until the first load succeeds.
    public private(set) var loaded = false
    /// The last request's failure, until a request succeeds.
    public private(set) var error: String?
    /// When `due` was last worked out; moves on with every request.
    public private(set) var now = Date()

    private let api: PreciseAPI

    public init(api: PreciseAPI) {
        self.api = api
    }

    /// Words to review now, the longest overdue first.
    public var due: [Word] {
        words.filter { $0.isDue(at: now) }.sorted { $0.dueAt < $1.dueAt }
    }

    /// Words saved since you last opened them.
    public var newWords: [Word] { words.filter(\.isNew) }

    public var nextDue: Date? { words.map(\.dueAt).filter { $0 > now }.min() }

    public func refresh() async {
        await perform {
            self.words = try await self.api.words()
            self.loaded = true
        }
    }

    public func review(_ word: Word, _ rating: Rating) async {
        await perform { self.replace(try await self.api.review(word.id, rating)) }
    }

    public func markSeen(_ word: Word) async {
        guard word.isNew else { return }
        await perform { self.replace(try await self.api.markSeen(word.id)) }
    }

    public func delete(_ word: Word) async {
        await perform {
            try await self.api.delete(word.id)
            self.words.removeAll { $0.id == word.id }
        }
    }

    private func replace(_ word: Word) {
        guard let index = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[index] = word
    }

    private func perform(_ work: () async throws -> Void) async {
        do {
            try await work()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        now = Date()
    }
}

extension APIConfig {
    /// The apps' API and token, set in Info.plist at build time from `~/.config/precise-en/config.json`.
    public static func fromInfoPlist(_ bundle: Bundle = .main) -> APIConfig {
        guard let url = (bundle.object(forInfoDictionaryKey: "PreciseENURL") as? String).flatMap(URL.init(string:)),
              url.scheme == "https",
              let token = bundle.object(forInfoDictionaryKey: "PreciseENToken") as? String, !token.isEmpty
        else {
            fatalError("Info.plist has no PreciseENURL and PreciseENToken: build the app with build.sh")
        }
        return APIConfig(url: url, token: token)
    }
}
