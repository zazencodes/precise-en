# Changelog

All notable changes to precise//en are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Added a prompt hook for Claude Code and Codex that saves the one word that would have said a long prompt better, with its definition, the phrase it replaces and a tighter rewrite of the prompt.
- Added a Mac menu bar app whose book icon fills in while there are new words, that opens at login, and reviews saved words Anki-style with Again, Hard, Good and Easy (keys 1 to 4, Space to show the answer).
- Added an iPhone app with the same Review and Words, sharing words and progress with the Mac through Cloudflare D1.
- Added a warning in the menu bar when the latest capture failed, with the error and the capture log one click away.
- Added a difficulty to every word (common, advanced or rare), judged when the word is captured and shown on its card, its row and its page.
- Added Archive, I know it (key a on the Mac) under a revealed answer in Review, to archive a word you already know without leaving the card.
- Added swiping a word away in Words to archive it as known: it leaves review, is never suggested again, and can be restored from Show Archived Words.
- Added difficulty filters, sorting by newest or A–Z, and search by word or definition to Words.
- Added a Stats screen that sums up words saved, learned, known and due in one sentence, and draws every word as a tick by tier, by difficulty and by week saved.

### Changed

- Renamed the apps to precise//en, all lowercase, on the iPhone home screen and throughout the Mac app, including Finder, Spotlight and Launchpad.
- Moved the Mac app to /Applications/precise::en.app, a file name Finder shows as precise//en.
- Redesigned the app in dark grays and heavy type: the review card sets the word large across the screen, Show Answer is a large gray button, and the brand pink stays on the word in its rewrite and the new-word dot.
- Moved the due count to the top of Review and showed new words by their pink dot, in place of tab bar badges.
- Replaced the app icon with a custom off-white //en mark on charcoal, the same on the iPhone and the Mac.
- Showed the 1 to 4 key hints on the rating buttons only on the Mac.
- Showed the Mac app in the Dock and the app switcher while its window is open.
- Kept Review, Words and Stats centered at the top of the Mac window when Words shows its list.

### Removed

- Removed deleting words: Archive replaces it, keeping the word so it is never suggested again.
