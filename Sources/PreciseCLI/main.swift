import Foundation

let usage = """
    usage: precise-en hook      UserPromptSubmit hook: hands a long prompt to suggest and returns at once
           precise-en suggest   read a prompt on stdin, ask the background agent for a word and save it
    """

switch CommandLine.arguments.dropFirst().first {
case "hook":
    do {
        try Hook.run()
    } catch {
        // Exit 1, never 2: exit 2 from a UserPromptSubmit hook blocks the prompt.
        FileHandle.standardError.write(Data("precise-en hook: \(error.localizedDescription)\n".utf8))
        exit(1)
    }
case "suggest":
    exit(await Suggest.run())
default:
    FileHandle.standardError.write(Data((usage + "\n").utf8))
    exit(64)
}
