---
name: setup
description: DiscoLike setup — connect the agent to DiscoLike. Use when no DiscoLike MCP tools are visible and `discolike` is not on PATH, when `discolike auth status` or `account usage` fails on auth, when the CLI on PATH is older than 0.4.1, or when the user asks to set up, connect, or log in to DiscoLike. Signs in, or opens an account when there is none.
allowed-tools: Read, AskUserQuestion
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

- **exit_code=0** with `"valid": true`: signed in. Run `discolike --version`; at 0.4.1 or later, stop. Older, go to step 3.
- **exit_code=3**: a credential is missing or rejected. Go to step 4.
- **command not found**: go to step 3.
- **exit_code=5**: network. Say so and stop; nothing here fixes that.

## 3. Install or upgrade the CLI

The skills need `discolike-cli` 0.4.1 or later. Do not install packages yourself; ask the user to run one of these in their own terminal:

```bash
pip install --upgrade discolike-cli
uv tool install discolike-cli   # or: uv tool upgrade discolike-cli
```

Then confirm:

```bash
discolike --version; echo "exit_code=$?"
```

At 0.4.1 or later, go back to step 2. `command not found` right after installing means the install's script directory is not on PATH in this shell; have the user open a new shell.

## 4. Sign in, or open an account

Ask, with `AskUserQuestion` when available: does the user already have a DiscoLike account?

**Yes, browser available:**

```bash
discolike auth login
```

Opens the browser for OAuth and stores the session under `~/.config/discolike/`. Over SSH or without a browser, `discolike auth login --no-browser --port 8765` prints the URL to open elsewhere.

**Yes, key in hand:** ask the user to run `discolike auth login --api-key <KEY>` themselves, or set `DISCOLIKE_API_KEY` in their own shell. Never ask for the key in chat, never read it from a file they did not name, and never write it into a config file yourself.

**No account:** ask for the work email, first and last name, show the user the exact values, and run this only after they say yes.

```bash
discolike signup --email 'jane@acme.com' --first-name 'Jane' --last-name 'Doe'
```

Single-quote every value so spaces and shell characters in a name stay literal; a name with an apostrophe goes in double quotes instead. Nothing sensitive comes back. The person confirms by email, picks a plan, and then runs `discolike auth login`. Free-mail and disposable domains are rejected; a `409` means the account exists, so send them to log in. Stop here and tell the user what to do next; the rest of setup waits for the confirmed account.

## 5. Verify

```bash
discolike account usage --format json
```

Report the plan and remaining quota in one sentence. Then return to whatever the user asked for; if setup was the whole request, offer one concrete first task: a free `discolike count` for their ICP, or a 25-record `discover` sample.

## Troubleshooting

| Symptom                                     | Cause                                              | Fix                                                                 |
| ------------------------------------------- | -------------------------------------------------- | ------------------------------------------------------------------- |
| `discolike: command not found` after step 3 | Install directory not on PATH in this shell        | Open a new shell                                                    |
| `auth status` exit 3 right after login      | Expired OAuth session                              | `discolike auth logout`, then `discolike auth login`                |
| Browser never opens                         | Headless or SSH session                            | `discolike auth login --no-browser --port <n>` and forward the port |
| MCP tools missing after adding the server   | Client needs a restart, or OAuth was not completed | Restart the client, retry the authorization                         |
