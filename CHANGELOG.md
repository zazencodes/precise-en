# Changelog

All notable changes to Precise EN are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Added a prompt hook for Claude Code and Codex that saves the one word that would have said a long prompt better, with its definition, the phrase it replaces and a tighter rewrite of the prompt.
- Added a Mac menu bar app that counts new words, opens at login, and reviews saved words Anki-style with Again, Hard, Good and Easy (keys 1 to 4, Space to show the answer).
- Added an iPhone app with the same Review and Words, sharing words and progress with the Mac through Cloudflare D1.
- Added a warning in the menu bar when the latest capture failed, with the error and the capture log one click away.
- Added a difficulty to every word (common, advanced or rare), judged when the word is captured.
- Added swiping a word away in Words to archive it as known: it leaves review and is never suggested again.

### Removed

- Removed deleting words: Archive replaces it, keeping the word so it is never suggested again.
