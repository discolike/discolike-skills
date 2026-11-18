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

DiscoLike is a search engine over **80M+ business websites worldwide**, analyzed in **55 languages**; roughly **3x the coverage of LinkedIn-dependent databases**. It ranks companies by what they actually do on the web, so it reaches niche verticals, local businesses, and non-English markets that other B2B data sources miss.

The `discolike` plugin includes the [core skill](skills/discolike/SKILL.md), job skills for tasks such as target account lists, lookalikes, CRM enrichment, ICP segmentation, and contact discovery, and the `setup` and `feedback` skills. The core skill covers choosing an access mode, opening an account without a browser, and managing search spend. The plugin bundles skill documentation, client configuration, and icons. Shell commands suggested by the skills use the client's normal permission prompt.

> **If you're a coding agent:** read the [core skill](skills/discolike/SKILL.md) first and load the skill for the job you need. The fastest integration is the hosted MCP server at `https://api.discolike.com/v1/mcp` (streamable-http, OAuth). For scripting use `pip install discolike`; for the terminal use `pip install discolike-cli` or `uvx --from discolike-cli discolike`. No account yet? `POST https://api.discolike.com/v1/public/signup` opens one from an email and name; the owner confirms by email. Machine-readable API index: `https://docs.discolike.com/llms.txt`.

## Installation

### Claude Code

Add the marketplace once, then install the plugin:

```
/plugin marketplace add Discolike/discolike-skills
/plugin install discolike@discolike
```

The core skill and relevant job skills activate automatically for tasks such as finding companies, building a target or TAM list, lookalikes, ICP research, company enrichment, or decision-maker contacts.

### Any agent with the `skills` CLI

Works for Codex, Cursor, Gemini CLI, Copilot, Windsurf, OpenCode, and Claude Code alike:

```
npx skills add Discolike/discolike-skills
```

### Codex, Cursor, and other agents

Clone this repository into the project or install it as a plugin where the client supports plugins. Each adapter starts with the [core skill](skills/discolike/SKILL.md) for shared safeguards and uses its job table to load the matching skill.

| Client         | Included integration                                            | How it activates                                                                                                                          |
| -------------- | --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Claude Code    | `.claude-plugin/` plus `.claude/CLAUDE.md`                      | Install from the Claude marketplace, or open the repo as a project.                                                                       |
| Codex          | `.codex-plugin/plugin.json` plus `AGENTS.md`                    | Install the plugin from a marketplace that contains this repo, or open the repo; `AGENTS.md` routes matching work through the core skill. |
| Cursor         | `.cursor-plugin/plugin.json` plus `.cursor/rules/discolike.mdc` | Install from the Cursor Marketplace, or open or copy the repository rule into a Cursor project.                                           |
| Gemini CLI     | `gemini-extension.json` plus `GEMINI.md`                        | `gemini extensions install https://github.com/Discolike/discolike-skills`, or open the repo or copy the file into a project.              |
| GitHub Copilot | `.github/copilot-instructions.md`                               | Open or copy the instruction file into a project.                                                                                         |
| Windsurf       | `.windsurf/rules/discolike.md`                                  | Open or copy the repository rule into a Windsurf project.                                                                                 |
| Grok           | `.grok-plugin/plugin.json` plus `AGENTS.md`                     | Install the plugin where supported, or use the included project instruction file.                                                         |
| Other agents   | `AGENTS.md`                                                     | Use the included project instruction file, or add its two paragraphs to the agent's project instructions.                                 |

For a personal global Codex installation, fetch the core skill and the job skills directly:

```bash
for skill in discolike discover-lookalike-companies find-validated-contacts enrich-crm match-company-domains \
  segment-customers map-tam build-icp-from-website target-by-tech-and-signals \
  score-account-list run-app-search fix-bad-results; do
  mkdir -p ~/.agents/skills/$skill
  curl -fsSL https://raw.githubusercontent.com/Discolike/discolike-skills/main/skills/$skill/SKILL.md \
    -o ~/.agents/skills/$skill/SKILL.md
done
```

The core `discolike` skill routes each job to the skill beside it under [`skills/`](skills/), so install them together.

If a client does not support rules or skills, give it the contents of `AGENTS.md` as project instructions. The agent can then read the core skill and the relevant job skill for matching tasks.

## What the plugin bundles

| Piece                               | Purpose                                                              |
| ----------------------------------- | -------------------------------------------------------------------- |
| `skills/discolike/`                 | Shared access, account, spend, and search guidance, plus job routing |
| Job skill folders under `skills/`   | Load the matching job skill from the table below                     |
| `skills/setup/`, `skills/feedback/` | Connect and report                                                   |

## What the core skill covers

- **Which door to use.** MCP server for clients that support remote MCP, CLI when shelling out, Python SDK when writing a script, REST as a last resort; and when to ask the user before wiring any of them up.
- **How to open an account from the agent.** One `POST` with an email and name, no browser, no credential returned; the owner confirms by email and picks a plan.
- **How to search.** The three ways to describe a target on one `discover` call; a plain-English `icp_prompt`, up to 10 seed `domain`s for lookalikes, exact `phrase_match` fragments; plus the geo, size, revenue, tech-stack, category, language, and business-model filters, each with a `negate_` twin.
- **How not to burn credits.** Count first (free), start with a small `max_records`, and page past the 10,000-per-call cap with exclusion lists rather than re-running the same search.
- **What to do after discovery.** Contacts at matched companies, enrichment of lists you already have, segmenting a customer list into ICP clusters, validating a list against an ICP, and pushing results to HubSpot, Salesforce, or Pipedrive.
- **How to diagnose bad results.** What to change when results look noisy, and when a question is a research job rather than a filter.

## Job skills

The contacts skill uses MCP. Other job skills include CLI and SDK examples where available.

| Skill                                                                          | What the agent does                                                                                            |
| ------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| [`discover-lookalike-companies`](skills/discover-lookalike-companies/SKILL.md) | Size the target set, discover companies, and build nonoverlapping rounds                                       |
| [`find-validated-contacts`](skills/find-validated-contacts/SKILL.md)           | Check company fit and deliver Validated and Validated (catch-all resolved) contacts with validated work emails |
| [`enrich-crm`](skills/enrich-crm/SKILL.md)                                     | Append firmographics, tech stack, growth, and scores to a domain list                                          |
| [`match-company-domains`](skills/match-company-domains/SKILL.md)               | Resolve company names to domains, individually or in bulk                                                      |
| [`segment-customers`](skills/segment-customers/SKILL.md)                       | Cluster existing customers, describe each cluster, and run lookalikes per cluster                              |
| [`map-tam`](skills/map-tam/SKILL.md)                                           | Grow a list to a target size with exclusion-list paging                                                        |
| [`build-icp-from-website`](skills/build-icp-from-website/SKILL.md)             | Derive a target profile from one URL and search on it                                                          |
| [`target-by-tech-and-signals`](skills/target-by-tech-and-signals/SKILL.md)     | Find companies by vendor, tech stack, or signals such as hiring SDRs or having a pricing page                  |
| [`score-account-list`](skills/score-account-list/SKILL.md)                     | Rank or filter an existing account list                                                                        |
| [`run-app-search`](skills/run-app-search/SKILL.md)                             | Replicate a Discover or Contacts search from a screenshot or form settings                                     |
| [`fix-bad-results`](skills/fix-bad-results/SKILL.md)                           | Diagnose noisy results, unexpected counts, and contact delivery or billing issues                              |

## Data and privacy

The plugin talks to these services, and only these:

| Service                               | When                                                                              | What is sent                                                                              |
| ------------------------------------- | --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `api.discolike.com`                   | Every MCP, CLI, SDK, or REST call, and account signup                             | Search filters, domains, uploaded lists, and the email and name given at signup           |
| GitHub (`github.com`)                 | `feedback` skill: the user opens a prefilled issue link and submits it themselves | The issue title and body the user approved, as a public issue in a `Discolike` repository |
| `discolike.com`, `docs.discolike.com` | When the agent reads DiscoLike documentation                                      | Page requests; no user data                                                               |

Results that include contacts (names, emails) are written to local files the agent creates, and saved queries and exclusion lists are stored in the user's DiscoLike account. See the [privacy policy](https://discolike.com/privacy-policy/) for retention.

## Related

- **MCP server**: [discolike.com/mcp](https://discolike.com/mcp/); hosted, OAuth 2.1, install snippets for every major client
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
