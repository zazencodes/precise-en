import Darwin
import Foundation
import PreciseKit

/// `precise-en hook`, the UserPromptSubmit hook for Claude Code and Codex.
///
/// It returns at once and prints nothing: Claude Code adds a hook's output to the conversation,
/// and the agent should never wait on a word. A long prompt goes to `precise-en suggest`,
/// started in a session of its own so it outlives the hook, writing to the capture log.
enum Hook {
    /// Set for everything `suggest` runs, so a prompt it sends to an agent is never captured.
    static let guardVariable = "PRECISE_EN_CAPTURE"

    static func run() throws {
        if ProcessInfo.processInfo.environment[guardVariable] != nil { return }
        let input = FileHandle.standardInput.readDataToEndOfFile()
        guard let payload = try? JSONSerialization.jsonObject(with: input) as? [String: Any] else {
            throw CLIError("hook input is not a JSON object: \(String(decoding: input.prefix(200), as: UTF8.self))")
        }
        guard let prompt = payload["prompt"] as? String else {
            throw CLIError("hook input has no \"prompt\"")
        }
        guard Capture.isWorthAWord(prompt) else { return }
        try detachSuggest(prompt: prompt)
    }

    private static func detachSuggest(prompt: String) throws {
        guard let executable = Bundle.main.executablePath else { throw CLIError("cannot find precise-en's own path") }
        try FileManager.default.createDirectory(at: CaptureStatus.stateDirectory, withIntermediateDirectories: true)

        var pipe: [Int32] = [0, 0]
        guard Darwin.pipe(&pipe) == 0 else { throw CLIError.posix("pipe") }

        var actions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&actions)
        defer { posix_spawn_file_actions_destroy(&actions) }
        posix_spawn_file_actions_adddup2(&actions, pipe[0], 0)
        posix_spawn_file_actions_addopen(&actions, 1, CaptureStatus.logURL.path, O_WRONLY | O_APPEND | O_CREAT, 0o644)
        posix_spawn_file_actions_adddup2(&actions, 1, 2)

        // A new session survives the agent ending the hook's process group. Every descriptor
        // but the three above closes, so the agent is not left waiting on the hook's output.
        var attributes: posix_spawnattr_t?
        posix_spawnattr_init(&attributes)
        defer { posix_spawnattr_destroy(&attributes) }
        posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETSID | POSIX_SPAWN_CLOEXEC_DEFAULT))

        var environment = ProcessInfo.processInfo.environment
        environment[guardVariable] = "1"
        let arguments: [UnsafeMutablePointer<CChar>?] = [strdup(executable), strdup("suggest"), nil]
        let variables: [UnsafeMutablePointer<CChar>?] = environment.map { strdup("\($0.key)=\($0.value)") } + [nil]
        defer { (arguments + variables).forEach { free($0) } }

        var pid = pid_t()
        let spawned = posix_spawn(&pid, executable, &actions, &attributes, arguments, variables)
        close(pipe[0])
        guard spawned == 0 else {
            close(pipe[1])
            throw CLIError("starting precise-en suggest: \(String(cString: strerror(spawned)))")
        }
        signal(SIGPIPE, SIG_IGN)
        let written = FileHandle(fileDescriptor: pipe[1], closeOnDealloc: true)
        try written.write(contentsOf: Data(prompt.utf8))
    }
}

struct CLIError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }

    static func posix(_ call: String) -> CLIError {
        CLIError("\(call): \(String(cString: strerror(errno)))")
    }
}
