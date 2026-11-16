# Each person's own settings stay out of the repo

## Decision

- Everything that belongs to one person's setup lives in `~/.config/precise-en/config.json`, outside the repo: the Worker's URL, the API token, the Apple developer team and the apps' bundle ID. The app builds take them from there through a git-ignored Xcode configuration; the CLI reads the file when it runs.
- The Worker's configuration names its D1 database and holds no database id. Wrangler finds the database by its name in the Cloudflare account it is logged in to.
- Tracked files hold nothing that differs between people, so anyone builds their own copy from a clean clone without editing a tracked file.

## Why

precise//en is open source, and every copy is its owner's own: their Worker, their database, their token, their Apple team. A bundle ID belongs to the Apple team that registers it, so each person needs their own. One file for everything personal keeps setup to one step and keeps personal values out of every commit. Naming the database instead of pinning its id keeps the Worker's configuration the same for everyone.

## Rejected

- **Committing the maintainer's values and asking others to edit them.** Publishes one person's identifiers and leaves every other clone with a modified tracked file.
- **A second git-ignored settings file in the repo for the Apple values.** Two files to set up instead of one, when the CLI already reads the config file.
- **Environment variables.** Must be set in every shell that builds, where a file is written once.
