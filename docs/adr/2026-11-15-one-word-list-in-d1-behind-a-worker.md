# One word list in Cloudflare D1, behind a Worker, shared by every device

## Decision

- The word list and each word's review state live in one D1 table behind a small Worker API that requires a bearer token. The Mac app, the iPhone app and the capture hook all read and write it there; nothing is stored on disk.
- The Worker applies the review schedule (Anki-style SM-2), so every device schedules the same way. Apps send a rating and show what comes back.
- The apps take the API's URL and token from `~/.config/precise-en/config.json` at build time; the CLI reads that file when it runs.

## Why

The iPhone and the Mac must share words and progress. Alex asked for something simple: a D1 table is the smallest shared store, and keeping the schedule on the server means there is one copy of it.

## Rejected

- **Files on disk, synced between devices.** The iPhone cannot see them without a sync service, and two writers can conflict.
- **Scheduling in the apps.** Two copies of the schedule could drift apart.
- **A settings screen for the token.** Every build is Alex's own, so baking it in at build time is one step fewer on the phone.
