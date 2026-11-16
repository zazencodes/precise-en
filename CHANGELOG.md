# Changelog

All notable changes to Precise EN are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Added a prompt hook for Claude Code and Codex that saves the one word that would have said a long prompt better, with its definition, the phrase it replaces and a tighter rewrite of the prompt.
- Added a Mac menu bar app that counts new words, opens at login, and reviews saved words Anki-style with Again, Hard, Good and Easy (keys 1 to 4, Space to show the answer).
- Added an iPhone app with the same Review and Words, sharing words and progress with the Mac through Cloudflare D1.
- Added a warning in the menu bar when the latest capture failed, with the error and the capture log one click away.
- Added a difficulty to every word (common, advanced or rare), judged when the word is captured and shown on its card, its row and its page.
- Added swiping a word away in Words to archive it as known: it leaves review, is never suggested again, and can be restored from Show Archived Words.
- Added difficulty filters, sorting by newest or A–Z, and search by word or definition to Words.

### Changed

- Redesigned the app in dark grays and heavy type: the review card sets the word large across the screen, Show Answer is a white button, and the brand pink stays on the word in its rewrite and the new-word dot.
- Moved the due count to the top of Review and showed new words by their pink dot, in place of tab bar badges.
- Showed the 1 to 4 key hints on the rating buttons only on the Mac.

### Removed

- Removed deleting words: Archive replaces it, keeping the word so it is never suggested again.
