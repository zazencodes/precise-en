import Foundation
import PreciseKit

/// `precise-en suggest`: reads a prompt on stdin, asks the background agent for a word and saves
/// it. Prints one line saying what happened and records it as the latest capture status.
enum Suggest {
    static func run() async -> Int32 {
        let prompt = String(decoding: FileHandle.standardInput.readDataToEndOfFile(), as: UTF8.self)
        let status: CaptureStatus
        do {
            status = try await capture(prompt)
        } catch {
            status = CaptureStatus(at: Date(), outcome: .failed, detail: error.localizedDescription)
        }
        print(line(for: status))
        do {
            try status.write()
        } catch {
            print("\(timestamp(Date())) failed: writing \(CaptureStatus.url.path): \(error.localizedDescription)")
            return 1
        }
        return status.outcome == .failed ? 1 : 0
    }

    static func capture(_ prompt: String) async throws -> CaptureStatus {
        let api = PreciseAPI(config: try loadConfig())
        let available = try await api.captureLimits().filter(\.hasRoom).map(\.difficulty)
        guard !available.isEmpty else {
            return CaptureStatus(at: Date(), outcome: .dailyLimit)
        }
        let saved = try await api.words().map(\.word)
        let output = try BackgroundAgent.ask(Capture.agentPrompt(for: prompt, saved: saved, available: available))
        guard case .word(let word) = try Capture.parse(output) else {
            return CaptureStatus(at: Date(), outcome: .noWord)
        }
        if saved.contains(word.word.lowercased()) {
            return CaptureStatus(at: Date(), outcome: .duplicate, word: word.word)
        }
        if let reason = Capture.rejection(of: word, prompt: prompt) {
            return CaptureStatus(at: Date(), outcome: .rejected, word: word.word, detail: reason)
        }
        guard available.contains(word.difficulty) else {
            return CaptureStatus(at: Date(), outcome: .dailyLimit, detail: word.difficulty.rawValue)
        }
        do {
            _ = try await api.add(word)
        } catch let error as APIError where error.status == 429 {
            return CaptureStatus(at: Date(), outcome: .dailyLimit, detail: word.difficulty.rawValue)
        } catch let error as APIError where error.status == 409 {
            return CaptureStatus(at: Date(), outcome: .duplicate, word: word.word)
        }
        return CaptureStatus(at: Date(), outcome: .added, word: word.word)
    }

    static func line(for status: CaptureStatus) -> String {
        [timestamp(status.at), status.outcome.rawValue, status.word, status.detail]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    static func timestamp(_ date: Date) -> String {
        date.formatted(.iso8601)
    }

    /// `~/.config/precise-en/config.json`: `{"url": "...", "token": "..."}`.
    static func loadConfig() throws -> APIConfig {
        let url = FileManager.default.homeDirectoryForCurrentUser.appending(path: ".config/precise-en/config.json")
        do {
            return try JSONDecoder().decode(APIConfig.self, from: Data(contentsOf: url))
        } catch {
            throw CLIError("reading \(url.path): \(error.localizedDescription)")
        }
    }
}

/// The background agent configured in tmux-agent-plane (`o` → Configure), run once.
enum BackgroundAgent {
    static func ask(_ prompt: String) throws -> String {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/env")
        process.arguments = ["tmux-agent-plane", "background", prompt]
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        process.standardInput = FileHandle.nullDevice
        try process.run()
        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        let errors = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(decoding: errors, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            throw CLIError("tmux-agent-plane background failed (\(process.terminationStatus)): \(message)")
        }
        return String(decoding: output, as: UTF8.self)
    }
}
