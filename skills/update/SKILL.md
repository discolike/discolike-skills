---
name: update
description: DiscoLike update — move the plugin and its pinned `discolike` CLI to the latest release. Use when the user asks to update or upgrade DiscoLike, when a skill reports the CLI is out of date, or when a command fails with an unknown-command error naming a subcommand that should exist.
allowed-tools: Bash, Read
---

# Updating DiscoLike

The plugin pins the CLI version it bundles in `bin/cli-version`; the launcher at `bin/discolike` runs exactly that version through `uvx`. Updating the plugin therefore updates the CLI. Updating the CLI independently is only for installs that bypass the launcher.

## 1. What is installed

```bash
discolike --version; cat "<PLUGIN_ROOT>/bin/cli-version"
```

`<PLUGIN_ROOT>` is `$CLAUDE_PLUGIN_ROOT` when exported, otherwise two levels above this skill's directory. Then check the latest published CLI:

```bash
uvx --from discolike-cli@latest discolike --version
```

## 2. Update the plugin

- **Claude Code:** `/plugin marketplace update discolike`, then `/plugin update discolike@discolike`. Both are user-typed slash commands; ask the user to run them, then restart the session so the new skills and pin load.
- **Codex:** `codex plugin marketplace update discolike`, then reinstall from the Plugins panel.
- **Cursor:** reinstall from the marketplace, or `git pull` in the cloned plugin directory.
- **`npx skills add` installs:** rerun `npx skills add Discolike/discolike-skills`.

## 3. Update a standalone CLI

Only when the user installed the CLI themselves and does not use the launcher:

```bash
pip install --upgrade discolike-cli
```

or `uv tool upgrade discolike-cli`. Then `discolike --version` to confirm.

## 4. Verify

```bash
discolike auth status; echo "exit_code=$?"
```

Exit 0 means the session survived the update. Exit 3 means sign in again with the `setup` skill.
