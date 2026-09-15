<p align="center">
  <a href="https://discolike.com">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://discolike.com/images/logo.svg">
      <img src="https://discolike.com/images/logo-dark.svg" alt="DiscoLike" width="220">
    </picture>
  </a>
</p>

<p align="center">
<b>Official DiscoLike skills for coding agents</b><br>
The GTM search engine for the business web, one workflow for Claude Code, Codex, Cursor, Gemini CLI, Copilot, Windsurf, Grok, and agents that honor <code>AGENTS.md</code>.
</p>

<p align="center">
  <a href="https://github.com/Discolike/discolike-skills/blob/main/skills/discolike/SKILL.md"><img src="https://img.shields.io/badge/skill-discolike-3367f1" alt="Skill: discolike"></a>
  <a href="https://github.com/Discolike/discolike-skills/blob/main/.claude-plugin/plugin.json"><img src="https://img.shields.io/badge/plugin-v1.0.0-3367f1" alt="Plugin version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License: MIT"></a>
</p>

<p align="center">
  <a href="https://discolike.com">Website</a> ·
  <a href="https://discolike.com/mcp/">MCP server</a> ·
  <a href="https://docs.discolike.com">API Docs</a> ·
  <a href="https://github.com/Discolike/discolike-python">Python SDK &amp; CLI</a> ·
  <a href="https://discolike.com/signup">Sign up</a> ·
  <a href="https://calendly.com/discolike/introductory-call">Book a demo</a>
</p>

---

DiscoLike is a search engine over **80M+ business websites worldwide**, analyzed in **50 languages** — roughly **3x the coverage of LinkedIn-dependent databases**. It ranks companies by what they actually do on the web, so it reaches niche verticals, local businesses, and non-English markets that other B2B data sources miss.

This repo ships the `discolike` plugin: the [`discolike`](skills/discolike/SKILL.md) skill with its flow, troubleshooting, and DiscoGen references, `setup`, `update`, and `feedback` skills, a pinned `discolike` CLI launcher, and approval hooks so plain CLI calls run without a permission prompt in Claude Code, Cursor, and Codex. The main skill gives a coding agent the operating knowledge to use DiscoLike well: which access mode to pick, how to open an account without a browser, how to search without wasting credits, and the end-to-end flows for the jobs people actually ask for — target account lists, lookalikes, CRM enrichment, ICP segmentation, and contact discovery.

> **If you're a coding agent:** read [`SKILL.md`](skills/discolike/SKILL.md) directly — it is the whole product. The fastest integration is the hosted MCP server at `https://api.discolike.com/v1/mcp` (streamable-http, OAuth, 48 tools). For scripting use `pip install discolike`; for the terminal use `pip install discolike-cli` or `uvx --from discolike-cli discolike`. No account yet? `POST https://api.discolike.com/v1/public/signup` opens one from an email and name; the owner confirms by email. Machine-readable API index: `https://docs.discolike.com/llms.txt`.

## Installation

### Claude Code

Add the marketplace once, then install the plugin:

```
/plugin marketplace add Discolike/discolike-skills
/plugin install discolike@discolike
```

The skill activates automatically when a task involves finding companies, building a target or TAM list, lookalikes, ICP research, company enrichment, or decision-maker contacts.

### Any agent with the `skills` CLI

Works for Codex, Cursor, Gemini CLI, Copilot, Windsurf, OpenCode, and Claude Code alike:

```
npx skills add Discolike/discolike-skills
```

### Codex, Cursor, and other agents

Clone this repository into the project or install it as a plugin where the client supports plugins. Every adapter points back to the same canonical [`skills/discolike/SKILL.md`](skills/discolike/SKILL.md), so clients get the same safeguards and product knowledge without maintaining forks.

| Client         | Included integration                                            | How it activates                                                                                                                |
| -------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Claude Code    | `.claude-plugin/` plus `CLAUDE.md`                              | Install from the Claude marketplace, or open the repo as a project.                                                             |
| Codex          | `.codex-plugin/plugin.json` plus `AGENTS.md`                    | Install the plugin from a marketplace that contains this repo, or open the repo; `AGENTS.md` routes matching work to the skill. |
| Cursor         | `.cursor-plugin/plugin.json` plus `.cursor/rules/discolike.mdc` | Install from the Cursor Marketplace, or open or copy the repository rule into a Cursor project.                                 |
| Gemini CLI     | `gemini-extension.json` plus `GEMINI.md`                        | `gemini extensions install https://github.com/Discolike/discolike-skills`, or open the repo or copy the file into a project.    |
| GitHub Copilot | `.github/copilot-instructions.md`                               | Open or copy the instruction file into a project.                                                                               |
| Windsurf       | `.windsurf/rules/discolike.md`                                  | Open or copy the repository rule into a Windsurf project.                                                                       |
| Grok           | `.grok-plugin/plugin.json` plus `AGENTS.md`                     | Install the plugin where supported, or use the included project instruction file.                                               |
| Other agents   | `AGENTS.md`                                                     | Use the included project instruction file, or add its two paragraphs to the agent's project instructions.                       |

For a personal global Codex installation, fetch the canonical skill directly:

```bash
mkdir -p ~/.agents/skills/discolike
curl -fsSL https://raw.githubusercontent.com/Discolike/discolike-skills/main/skills/discolike/SKILL.md \
  -o ~/.agents/skills/discolike/SKILL.md
```

If a client does not support rules or skills, give it the contents of `AGENTS.md` as project instructions. The agent will then load the canonical skill only for relevant tasks instead of carrying the full workflow in every prompt.

## What the plugin bundles

| Piece                                                 | Purpose                                                                                                                                                     |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `skills/discolike/`                                   | Entry-point skill plus `flows.md`, `troubleshooting.md`, `discogen.md`, loaded on demand                                                                    |
| `skills/setup/`, `skills/update/`, `skills/feedback/` | Connect, upgrade, and report                                                                                                                                |
| `bin/discolike`                                       | Launcher that runs `discolike-cli` at the version pinned in `bin/cli-version` through `uvx`                                                                 |
| `hooks/approve-cli.sh`                                | Auto-approves plain `discolike` commands; credential and provider-key subcommands, redirects, `&&`, `$(…)`, and paths outside the working tree still prompt |
| `hooks/approve-skills.sh`                             | Auto-approves this plugin's own skills and read-only web tools in Claude Code                                                                               |

Run the hook tests with `sh hooks/test-approve-cli.sh`.

## What the skill knows

- **Which door to use.** MCP server for clients that support remote MCP, CLI when shelling out, Python SDK when writing a script, REST as a last resort — and when to ask the user before wiring any of them up.
- **How to open an account from the agent.** One `POST` with an email and name, no browser, no credential returned; the owner confirms by email and picks a plan.
- **How to search.** The three ways to describe a target on one `discover` call — a plain-English `icp_prompt`, up to 10 seed `domain`s for lookalikes, exact `phrase_match` fragments — plus the geo, size, revenue, tech-stack, category, language, and business-model filters, each with a `negate_` twin.
- **How not to burn credits.** Count first (free), start with a small `max_records`, and page past the 10,000-per-call cap with exclusion lists rather than re-running the same search.
- **What to do after discovery.** Contacts at matched companies, enrichment of lists you already have, segmenting a customer list into ICP clusters, validating a list against an ICP, and pushing results to HubSpot, Salesforce, or Pipedrive.
- **How to diagnose bad results.** What to change when results look noisy, and when a question is a DiscoGen research job rather than a filter.

## Flows

Each flow in the skill lists the MCP tool, the CLI command, and the SDK call side by side, so the agent can execute it in whichever mode is connected.

| Flow                                       | What the agent does                                                                                                  |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------- |
| Discover, verify, contacts, ContaGen       | Build a target list, confirm fit, get named people, fill the gaps with live web research                             |
| Enrich a CRM export                        | Append firmographics, tech stack, growth, and scores to a domain list                                                |
| Match company names to domains             | Turn a messy name column into resolved domains, single or bulk                                                       |
| Segment a client list into ICPs            | Cluster existing customers, describe each cluster, run lookalikes per cluster                                        |
| Market map to N                            | Grow a list to a target size with exclusion-list paging                                                              |
| ICP from a website                         | Derive a target profile from one URL and search on it                                                                |
| Signal-qualified list                      | "Find X that run Shopify", "that are hiring SDRs", "that have a pricing page" — discover, then qualify on the signal |
| Technology and infrastructure targeting    | Find companies by the vendors and stack they run                                                                     |
| Rank or filter a list the user already has | Score an existing list against an ICP instead of discovering new companies                                           |

## Related

- **MCP server**: [discolike.com/mcp](https://discolike.com/mcp/) — hosted, OAuth 2.1, install snippets for every major client
- **Python SDK and CLI**: [github.com/Discolike/discolike-python](https://github.com/Discolike/discolike-python)
- **API documentation**: [docs.discolike.com](https://docs.discolike.com)
- **Agent signup guide**: [docs.discolike.com/guides/agent-signup](https://docs.discolike.com/guides/agent-signup/)

## Support & contact

- **Sign up**: [discolike.com/signup](https://discolike.com/signup)
- **Book a demo**: [calendly.com/discolike/introductory-call](https://calendly.com/discolike/introductory-call)
- **LinkedIn**: [linkedin.com/company/discolike](https://www.linkedin.com/company/discolike/)
- **Issues with this skill**: [GitHub issues](https://github.com/Discolike/discolike-skills/issues)

## License

[MIT](LICENSE)
