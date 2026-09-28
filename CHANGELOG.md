# Changelog

## Unreleased

- Flow 11 covers seeded runs (`customer_domains`, segment selection, results segments); Flow 4 points to it.
- Claude Code plugin no longer auto-approves its skills or `WebFetch` of DiscoLike hosts; both go through the normal permission prompt. The approval hook script and its tests are removed.
- Claude plugin manifest declares the privacy policy and terms of service URLs, and the plugin ships a listing icon.
- The plugin no longer ships the pinned CLI launcher, so it runs no local code. `setup` asks the user to install `discolike-cli` 0.4.1 or later themselves.
- `feedback` hands the user a prefilled GitHub issue link instead of filing through `gh`.
- README lists every service the plugin talks to and what it sends.

## 1.0.1 - 2026-09-30

- Plain `discolike` CLI calls no longer auto-approve: the CLI approval hook is gone from Claude Code, Cursor, and Codex, and no skill pre-approves `Bash`, so every shell command goes through the client's normal permission prompt. Skill and DiscoLike-docs `WebFetch` auto-approval in Claude Code stays.
- Skill no longer pre-approves `uvx --from discolike-cli` or `Write`, and its text no longer tells the agent which calls skip a permission prompt. API keys go into `DISCOLIKE_API_KEY` or `auth login --api-key` run by the user, never through chat. Signup sends only after the user confirms the exact email and name. Skills never install or run packages on their own; installs, including uv, are left to the user.
- Removed the `update` skill: it ran the latest unpinned CLI from PyPI. Update through the client's plugin manager; `setup` covers upgrading a standalone CLI.
- DiscoGen MCP tool renamed in the skill: `research-companies` (was `run-discogen`).
- Codex manifest declares `Read` and `Write` capabilities, website, privacy and terms URLs, and the icon; listing moves to Business & Operations with a 30-character subtitle.

## 1.0.0 - 2026-09-15

- Flow 10 runs on `discolike bulk companies|estimate|contacts` (checkpoint and resume, local validation, one call in flight) instead of an SDK script, and forms go in as `--params-file form.json`. Flows 1, 5, and 9 use `--domains-file` for lists. Needs `discolike-cli` 0.4.1, pinned in `bin/cli-version` (0.4.0 was yanked: it failed to start under Typer 0.27).

- Approval hooks: plain `discolike` CLI calls auto-approve in Claude Code, Cursor, and Codex. `auth`, `signup`, `llm-providers`, `search-providers`, `--base-url`, redirects, chaining, substitution, and out-of-tree paths still prompt. Read-only pipe helpers may take only the operands they need (jq and grep one, tr two, the rest none), so a bare file name has nowhere to go. Test table in `hooks/test-approve-cli.sh`; launcher tests in `hooks/test-launcher.sh`, plus `npm run test:live` to start the pinned CLI from PyPI after a pin bump.
- Skill auto-approval for this plugin's skills, plus `WebFetch` of `docs.discolike.com`, `api.discolike.com`, and the Discolike GitHub org; every other URL and `WebSearch` still prompt. Test table in `hooks/test-approve-skills.sh`.
- Pinned CLI launcher `bin/discolike` running `discolike-cli==<bin/cli-version>` via `uvx`, with a JSON error envelope when uv is missing.
- New skills: `setup`, `update`, `feedback`.
- Main skill split into `SKILL.md` plus `flows.md`, `troubleshooting.md`, `discogen.md`; added a "How to work" section and `allowed-tools`.
- Prettier configuration and `npm test` for the hook table.

## 0.1.0

- Initial release: one skill, adapters for eight agent clients.
