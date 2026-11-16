# Precise EN

Learn the English words you could have used in your own prompts.

When you send Claude Code or Codex a long prompt, Precise EN asks a cheap background model for the one word that would have said part of it better, such as **idempotent** for *make sure running it twice doesn't break anything*. It saves the word with its definition, your phrase and a tighter rewrite of the prompt. A Mac menu bar app shows how many new words have arrived and reviews them with spaced repetition, Anki-style. An iPhone app reviews the same words.

## How it works

```
prompt ──▶ UserPromptSubmit hook ──▶ precise-en suggest (detached)
                                       │  tmux-agent-plane background "<prompt>"
                                       ▼
                     Cloudflare Worker + D1 ◀── Mac app (menu bar) and iPhone app
```

- **Hook.** `precise-en hook` returns at once, so your agent never waits. Prompts under 50 words are skipped. Longer ones go to `precise-en suggest`, which runs the background agent you chose in [tmux-agent-plane](https://github.com/zazencodes/tmux-agent-plane) (`o` → Configure), checks its answer and saves the word. It refuses a word already in the prompt, a phrase you didn't write, and any word you have already saved.
- **Worker.** One D1 table holds every word and its review state. The Worker requires a bearer token and schedules reviews, so the Mac and the iPhone stay in step.
- **Apps.** Review shows each due word; Space reveals the meaning and 1 to 4 rate it. Words lists everything, with a purple dot on each new word until you open it.

## Setup

Requires macOS 15, Xcode, [xcodegen](https://github.com/yonaskolb/XcodeGen), Node 22, a Cloudflare account, and tmux-agent-plane with a background agent configured.

1. **Deploy the Worker.** In `worker/`: `npm ci`, then `npx wrangler d1 create precise-en --update-config=false`; the Worker finds the database by its name. `npm run deploy` creates the table and prints the Worker's URL.
2. **Configure.** Write `~/.config/precise-en/config.json` (mode 600) with that URL, a random token from `openssl rand -hex 32`, your Apple Developer Team ID and a bundle ID of your own for the apps:

   ```json
   {
     "url": "https://precise-en.<your-subdomain>.workers.dev",
     "token": "<token>",
     "apple_team_id": "<your team ID>",
     "bundle_id": "com.<you>.preciseen"
   }
   ```

   Then give the Worker the same token, from `worker/`:

   ```sh
   python3 -c 'import json, os; print(json.load(open(os.path.expanduser("~/.config/precise-en/config.json")))["token"], end="")' \
     | npx wrangler secret put TOKEN
   ```

3. **Install.** `./install.sh` builds the Mac app into `/Applications`, adds it to Login Items and installs `precise-en` in `~/.local/bin`. `./install-iphone.sh` installs the iPhone app on your paired, unlocked iPhone.
4. **Add the hook** to `UserPromptSubmit` in `~/.claude/settings.json` and `~/.codex/hooks.json`:

   ```json
   { "hooks": [{ "type": "command", "command": "/Users/<you>/.local/bin/precise-en hook" }] }
   ```

   Codex runs a new hook only after you trust it. Start Codex (it opens with "Hooks need review"; choose Review hooks) or run `/hooks`, select `UserPromptSubmit`, press Enter, select the `precise-en hook` entry and press `t`. Codex saves the trust in `~/.codex/config.toml` and asks again if the hook's entry changes.

## Troubleshooting

- `~/.local/state/precise-en/capture.log` has one line per long prompt: `added`, `no-word`, `duplicate`, `rejected` (with why) or `failed` (with the error). When the latest is `failed`, the menu bar icon turns into a warning.
- Test a capture by hand: `echo "<a long prompt>" | precise-en suggest`.
