---
name: setup
description: DiscoLike setup — connect the agent to DiscoLike. Use when no DiscoLike MCP tools are visible and `discolike` is not on PATH, when `discolike auth status` or `account usage` fails on auth, when the CLI on PATH is older than the plugin's pinned version, or when the user asks to set up, connect, or log in to DiscoLike. Signs in, or opens an account when there is none.
allowed-tools: Bash, Read, AskUserQuestion
---

# DiscoLike setup

Two doors: the hosted MCP server (best when the client supports remote MCP) and the `discolike` CLI (best when shelling out). Either one signed in is enough. Work through the steps in order and stop at the first one that proves a working connection.

## 1. Is MCP already connected?

If tools named `discover-similar-companies` or `account-status` are in your tool list, call `account-status`. Success means DiscoLike is connected through MCP: name the plan and remaining quota in one line and stop. Skip the CLI steps unless the user wants the CLI too.

## 2. Is the CLI signed in?

```bash
discolike auth status; echo "exit_code=$?"
```

Read the exit code and the JSON, not any prose.

- **exit_code=0** with `"valid": true`: signed in. Go to step 3 to confirm the version, then stop.
- **exit_code=3**: a credential is missing or rejected. Go to step 4.
- **command not found**: go to step 3.
- **exit_code=5**: network. Say so and stop; nothing here fixes that.

## 3. Put the pinned launcher on PATH

The plugin bundles `bin/discolike`, a launcher that runs `discolike-cli` at the version in `bin/cli-version` through `uvx`. Resolve the plugin root: `$CLAUDE_PLUGIN_ROOT` when the harness exports it, otherwise two levels above this skill's directory.

```bash
"<PLUGIN_ROOT>/bin/discolike" --version; echo "exit_code=$?"
```

- **exit_code=5** with `uv is not installed`: install uv (`curl -LsSf https://astral.sh/uv/install.sh | sh`, or `pip install uv`), then rerun.
- **exit_code=0**: the launcher works. Compare its version against whatever bare `discolike` reports:

  ```bash
  discolike --version 2>/dev/null; cat "<PLUGIN_ROOT>/bin/cli-version"
  ```

  If bare `discolike` is missing or older than the pin, add the launcher to PATH for this session and for future shells. Tell the user which file you are editing before you edit it:

  ```bash
  export PATH="<PLUGIN_ROOT>/bin:$PATH"
  ```

  For a persistent PATH, append the same `export` line to `~/.zshrc` or `~/.bashrc` only with the user's yes. Until a new shell starts, use the launcher's absolute path in place of `discolike` in every command from any DiscoLike skill.

## 4. Sign in, or open an account

Ask, with `AskUserQuestion` when available: does the user already have a DiscoLike account?

**Yes, browser available:**

```bash
discolike auth login
```

Opens the browser for OAuth and stores the session under `~/.config/discolike/`. Over SSH or without a browser, `discolike auth login --no-browser --port 8765` prints the URL to open elsewhere.

**Yes, key in hand:** `discolike auth login --api-key <KEY>`. Take the key from the user; never read it from a file they did not name, and never write it into a config file yourself.

**No account:**

```bash
discolike signup --email <work email> --first-name <first> --last-name <last>
```

Nothing sensitive comes back. The person confirms by email, picks a plan, and then runs `discolike auth login`. Free-mail and disposable domains are rejected; a `409` means the account exists, so send them to log in. Stop here and tell the user what to do next; the rest of setup waits for the confirmed account.

## 5. Verify

```bash
discolike account usage --format json
```

Report the plan and remaining quota in one sentence. Then return to whatever the user asked for; if setup was the whole request, offer one concrete first task: a free `discolike count` for their ICP, or a 25-record `discover` sample.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `discolike: command not found` after step 3 | PATH edit not in this shell | Use the launcher's absolute path, or open a new shell |
| `auth status` exit 3 right after login | Expired OAuth session | `discolike auth logout`, then `discolike auth login` |
| Browser never opens | Headless or SSH session | `discolike auth login --no-browser --port <n>` and forward the port |
| MCP tools missing after adding the server | Client needs a restart, or OAuth was not completed | Restart the client, retry the authorization |
| `exit_code=5` from the launcher | `uv` missing | Install uv, rerun |
| Every CLI call prompts for permission | Hook not active | Reinstall the plugin; only plain `discolike …` calls are auto-approved, redirects and `&&` always prompt |
