# AGENTS.md

precise//en: learn the English words you could have used in your own prompts. A prompt hook in Claude Code and Codex hands each long prompt to tmux-agent-plane's background agent, which picks the one word that would have said it better; the word goes into a Cloudflare D1 list that a Mac menu bar app and an iPhone app review Anki-style.

## Layout

- `worker/`: the Cloudflare Worker and its D1 database `precise-en`. `src/schedule.ts` is the review schedule, `migrations/` the table.
- `Sources/PreciseKit`: the word model, the API client and the capture status file, shared by everything below.
- `Sources/PreciseUI`: SwiftUI shared by both apps: `WordStore`, Review, Words.
- `Sources/PreciseCLI`: `precise-en hook` (the UserPromptSubmit hook) and `precise-en suggest` (asks the background agent and saves the word). `Capture.swift` holds the prompt to the background agent and the checks on its answer.
- `apps/`: `project.yml` (xcodegen) with the Mac app (`Mac/`, a `MenuBarExtra` plus one window) and the iPhone app (`iOS/`), and `icon.swift`, which renders the app icon.

## Commands

- `swift test`: the Swift tests. `cd worker && npm test && npm run typecheck`: the Worker's tests (in the Workers runtime) and types.
- `./build.sh`: `build/precise::en.app` and `build/precise-en`. `./install.sh`: replaces `/Applications/precise::en.app`, launches it, and installs the CLI to `~/.local/bin/precise-en`. `./install-iphone.sh`: builds and installs the iPhone app on the paired iPhone.
- `cd worker && npm run deploy`: applies D1 migrations and deploys the Worker.
- `apps/configure.sh`: writes `apps/Secrets.xcconfig` and generates `apps/PreciseEN.xcodeproj` for opening in Xcode. Both are git-ignored.
- `echo "<prompt>" | .build/debug/precise-en suggest`: one capture, synchronously, printing what happened. It saves a real word (words are archived rather than deleted through the API, so remove test rows from D1 directly afterwards).

## Important Details

- The scripts use Xcode through `DEVELOPER_DIR`; `xcode-select` points at the Command Line Tools on this Mac. Set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` for `swift` and `xcodebuild` yourself.
- `~/.config/precise-en/config.json` (`url`, `token`, `apple_team_id`, `bundle_id`, mode 600) is the one source of the API URL and token and of the Apple team and bundle ID the apps are signed with. The token is the Worker secret `TOKEN`; never print it or commit it.
- The hook is installed outside this repo, as a `UserPromptSubmit` entry running `~/.local/bin/precise-en hook` in `~/.claude/settings.json` and in `~/.codex/hooks.json`. Codex runs it only once it is trusted in `/hooks`, which records a hash in `~/.codex/config.toml`; editing the entry needs trusting again.
- The hook must print nothing (Claude Code adds hook output to the conversation) and never exit 2 (that blocks the prompt). Everything `suggest` runs carries `PRECISE_EN_CAPTURE`, and the hook ignores prompts in that environment, so a background agent with hooks of its own cannot feed captures back in.
- `suggest` appends one line per prompt to `~/.local/state/precise-en/capture.log` and writes the latest result to `last-capture.json`; the Mac app turns its menu bar icon into a warning when that result is `failed`.
- The Mac app registers itself as a login item only when it runs from `/Applications`. Ice may hide its menu bar item when it first appears.
- Prompts that an orchestrator agent sends to another agent are captured too; nothing yet tells them apart from Alex's.

## Decisions

Read these before changing the area they cover, and write a new one whenever a decision is made (`adr` skill).

- Prompts arrive through a UserPromptSubmit hook that uses tmux-agent-plane's background agent; there is no skill: `docs/adr/2026-11-15-prompts-reach-precise-en-through-a-hook.md`
- One D1 word list behind the Worker holds words and review state for every device, and the Worker owns the schedule: `docs/adr/2026-11-15-one-word-list-in-d1-behind-a-worker.md`
- Cards show the word and ask for its meaning: `docs/adr/2026-11-15-cards-ask-for-the-meaning.md`
- Known words are archived rather than deleted, and difficulty is judged at capture: `docs/adr/2026-11-15-known-words-are-archived-and-judged-at-capture.md`
- The Mac app's file name is `precise::en.app`, which Finder shows as precise//en: `docs/adr/2026-11-16-the-mac-app-file-name-spells-the-name-with-colons.md`

## Changelog and Releases

When a change is finished and tested, run `./install.sh` (and `./install-iphone.sh` if the iPhone app changed) without being asked.

Add an entry to `CHANGELOG.md` (Keep a Changelog) under `## [Unreleased]` for every user-facing change, in the subsections `### Breaking Changes`, `### Added`, `### Changed`, `### Fixed`, `### Removed`: one line, past tense, saying what changed for the user. Released sections are immutable.

To release from a clean, pushed `main`: rename `[Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` with a fresh `## [Unreleased]` above it, set `MARKETING_VERSION` in `apps/project.yml`, commit as `Release vX.Y.Z` and push; then `git tag -a vX.Y.Z -m vX.Y.Z`, `git push origin vX.Y.Z` and `gh release create vX.Y.Z --title "Precise EN vX.Y.Z" --notes "<that version's CHANGELOG section>"`.
