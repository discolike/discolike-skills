# Changelog

## 1.0.0 - 2026-09-15

- Approval hooks: plain `discolike` CLI calls auto-approve in Claude Code, Cursor, and Codex. `auth`, `signup`, `llm-providers`, `search-providers`, `--base-url`, redirects, chaining, substitution, and out-of-tree paths still prompt. Read-only pipe helpers may take only the operands they need (jq and grep one, tr two, the rest none), so a bare file name has nowhere to go. Test table in `hooks/test-approve-cli.sh`; launcher tests in `hooks/test-launcher.sh`.
- Skill auto-approval for this plugin's skills plus WebFetch and WebSearch.
- Pinned CLI launcher `bin/discolike` running `discolike-cli==<bin/cli-version>` via `uvx`, with a JSON error envelope when uv is missing.
- New skills: `setup`, `update`, `feedback`.
- Main skill split into `SKILL.md` plus `flows.md`, `troubleshooting.md`, `discogen.md`; added a "How to work" section and `allowed-tools`.
- Prettier configuration and `npm test` for the hook table.

## 0.1.0

- Initial release: one skill, adapters for eight agent clients.
