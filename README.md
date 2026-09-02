# DiscoLike skills

Skills that teach coding agents how to find companies, enrich them, and reach the right people with [DiscoLike](https://discolike.com), a search engine over 80M+ business websites.

## Install

Claude Code:

```
/plugin marketplace add Discolike/discolike-skills
/plugin install discolike@discolike
```

Codex, Cursor, or any agent that reads skill files: copy `skills/discolike/SKILL.md` into the skills directory your client uses (`~/.codex/skills/discolike/SKILL.md`, `.cursor/rules/discolike.mdc`, `AGENTS.md`).

## What the skill knows

- When DiscoLike is the right tool and which access mode to pick: MCP server, CLI, Python SDK, or REST.
- How to open an account from the agent without a browser.
- The three search modes (`icp_prompt`, seed `domain`s, `phrase_match`), the filters, and how to count before spending credits.
- What to do after discovery: contacts, enrichment, segmentation, validation, CRM push.

## Related

- MCP server: https://discolike.com/mcp/
- API and SDK: https://discolike.com/api/
- Python SDK and CLI source: https://github.com/Discolike/discolike-python
- Docs: https://docs.discolike.com/
