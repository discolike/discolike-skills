---
name: feedback
description: DiscoLike feedback — file a bug report or product feedback with the DiscoLike team as a GitHub issue. Use when the user wants to report a problem with DiscoLike, the skills, the CLI, the MCP server, or the SDK, or says "send feedback", "report this", or "this should work differently".
allowed-tools: Bash, AskUserQuestion
---

# DiscoLike feedback

Feedback goes to a public GitHub issue. Nothing is sent without the user seeing the exact text first.

## 1. Classify

- **bug**: something that worked, or is documented, now fails. Include the exact command, the JSON error envelope from stderr, the exit code, and `discolike --version`.
- **feedback**: missing behavior, confusing flow, a filter or field that should exist, pricing questions, docs gaps.

Default to feedback when unsure.

## 2. Pick the repository

| About | Repository |
|---|---|
| This plugin, hooks, skills text | `Discolike/discolike-skills` |
| CLI or Python SDK | `Discolike/discolike-python` |
| MCP server, API, data quality, billing | `Discolike/discolike-skills` (the team routes it) |

## 3. Draft and confirm

Write the title and body. Strip API keys, emails of third parties, and full result sets; keep one or two example domains. Show the user the draft and ask for a yes with `AskUserQuestion` when available.

## 4. File it

With the GitHub CLI signed in (`gh auth status` exit 0):

```bash
gh issue create --repo Discolike/<repo> --title "<title>" --body "<body>" --label "<bug|feedback>"
```

Without `gh`, print a prefilled link for the user to open:

```
https://github.com/Discolike/<repo>/issues/new?title=<url-encoded title>&body=<url-encoded body>
```

Relay the issue URL. For account or billing matters that should not be public, point the user to support@discolike.com instead.
