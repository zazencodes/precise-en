import Foundation

/// Where the precise-en Worker is and the bearer token it requires.
public struct APIConfig: Codable, Sendable {
    public let url: URL
    public let token: String

    public init(url: URL, token: String) {
        self.url = url
        self.token = token
    }
}

public struct APIError: LocalizedError, Sendable {
    public let status: Int
    public let message: String

    public var errorDescription: String? { "precise-en API \(status): \(message)" }
}

/// The precise-en Worker: the word list in D1 that every app and the capture hook share.
public struct PreciseAPI: Sendable {
    public let config: APIConfig

    public init(config: APIConfig) {
        self.config = config
    }

    public func words() async throws -> [Word] {
        struct Body: Decodable { let words: [Word] }
        return try await send("GET", "words", as: Body.self).words
    }

    /// Throws an `APIError` with status 409 when the word is already saved.
    public func add(_ word: NewWord) async throws -> Word {
        try await send("POST", "words", body: word, as: WordBody.self).word
    }

    public func review(_ id: Int, _ rating: Rating) async throws -> Word {
        struct Body: Encodable { let rating: Rating }
        return try await send("POST", "words/\(id)/review", body: Body(rating: rating), as: WordBody.self).word
    }

    public func markSeen(_ id: Int) async throws -> Word {
        try await send("POST", "words/\(id)/seen", as: WordBody.self).word
    }

    public func delete(_ id: Int) async throws {
        _ = try await request("DELETE", "words/\(id)", body: nil)
    }

    private struct WordBody: Decodable { let word: Word }

    private func send<Response: Decodable>(
        _ method: String, _ path: String, body: (some Encodable)? = Optional<Int>.none, as: Response.Type
    ) async throws -> Response {
        let data = try await request(method, path, body: try body.map { try JSONCoding.encoder.encode($0) })
        return try JSONCoding.decoder.decode(Response.self, from: data)
    }

    private func request(_ method: String, _ path: String, body: Data?) async throws -> Data {
        var request = URLRequest(url: config.url.appending(path: path))
        request.httpMethod = method
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as! HTTPURLResponse).statusCode
        guard (200..<300).contains(status) else {
            struct Failure: Decodable { let error: String }
            let message = (try? JSONDecoder().decode(Failure.self, from: data))?.error
                ?? String(decoding: data, as: UTF8.self)
            throw APIError(status: status, message: message)
        }
        return data
    }
}

/// The API's JSON: snake_case keys and ISO 8601 times to the second.
public enum JSONCoding {
    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
}
