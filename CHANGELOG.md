# Changelog

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
