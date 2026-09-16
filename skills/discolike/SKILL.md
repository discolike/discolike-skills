---
name: discolike
description: Use when the task involves finding companies, building a target account or TAM list, lookalikes of existing customers, ICP research, company enrichment (firmographics, tech stack, growth), or finding decision-maker contacts at companies. Also use when the user mentions DiscoLike, "companies like X", "find businesses that", prospect lists, or B2B data. Covers MCP server, CLI, Python SDK, and creating the account from the agent.
allowed-tools: Bash(discolike *), Bash(uvx --from discolike-cli *), Bash(jq *), Read, Write, Grep
---

# DiscoLike

DiscoLike is a search engine over 80M+ crawled business websites. It returns companies ranked by what they actually do on the web, not by LinkedIn tags, so it reaches niche verticals and non-English markets other B2B databases miss. Every domain is re-validated by SSL certificate about every 30 days, so results never contain dead or parked domains and none are billed. Every record carries firmographics; contacts, technographics, growth metrics, enrichment, segmentation, and CRM push are one more call away.

Requires a paid plan from $99/month. There is no free tier. Counting results is free.

## Files in this skill

| File                 | Read it when                                                                                                                                                                                              |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `flows.md`           | Running any end-to-end job: target list, CRM enrichment, name-to-domain matching, ICP segmentation, market map, ICP from a website, signal qualification, tech-stack targeting, scoring an existing list. |
| `troubleshooting.md` | Results look noisy, counts do not add up, or the user says "these are wrong".                                                                                                                             |
| `discogen.md`        | The question is research, not a filter ("do they sell to hospitals?", "estimated ad spend?").                                                                                                             |
| `flows.md` Flow 10   | The user wants everything that matches, tens of thousands of companies or 100,000+ contacts, or asks to replicate an app search over the API.                                                             |

Read a file when its row applies; do not load all three up front.

## How to work

- **Confirm the account once.** First DiscoLike call in a session: MCP `account-status`, CLI `discolike account usage`, or SDK `client.account.usage()`. Tell the user the plan and remaining quota in one line. If it fails on auth, run the `setup` skill.
- **Narrate, then summarize.** Say what you are about to run and why; turn JSON into a count, a short table, or a sentence. Raw output only on request. Write full result sets to disk as JSON or CSV; chat output truncates.
- **Position it as DiscoLike's product.** "DiscoLike lets you…", "you can…". Not "skills I have".
- **Spend rule.** Counting is free; discovery, contacts, and enrichment bill per new record. Before any paid pull larger than a sample (about 100 records), state the estimated cost from the count and the plan's per-1,000 rate and get a yes. Reuse that approval for the same scope; ask again only if the scope or estimate grows. Do not volunteer the balance otherwise.
- **Plain CLI calls.** One `discolike` command at a time, `--format json`, optionally piped to `jq`. Redirects, `&&`, `$(…)`, and variables fall through to a permission prompt; a plain call is auto-approved by the plugin hook.

## Pick the access mode

1. **MCP server** if the client supports remote MCP (Claude Code, Claude Desktop, Codex, Cursor, VS Code, Windsurf). URL `https://api.discolike.com/v1/mcp`, OAuth 2.1, no key to manage. Tools appear in the client after one browser authorization. Install snippets: https://discolike.com/mcp.md
2. **CLI** when shelling out. The plugin bundles a pinned launcher at `bin/discolike`; the `setup` skill puts it on PATH. Without the plugin: `pip install discolike-cli` or `uvx --from discolike-cli discolike`. Sign in with `discolike auth login` (browser OAuth) or `discolike auth login --api-key KEY`. Always pass `--format json`. `discolike --help` prints the output contract and exit codes.
3. **Python SDK** when writing a script. `pip install discolike`, `Discolike()` reads `DISCOLIKE_API_KEY`. Reference: https://docs.discolike.com/sdk/reference/
4. **REST** as last resort: `GET https://api.discolike.com/v1/discover`, header `X-API-Key`. OpenAPI at https://api.discolike.com/v1/openapi.json. Auth summary: https://discolike.com/auth.md

If neither MCP nor CLI is signed in, run the `setup` skill. Never paste an API key into a config file the user did not ask for.

## No account yet

Create it without a browser. No credential comes back; the person confirms by email, logs in, picks a plan, and issues the key or authorizes the MCP client.

```
POST https://api.discolike.com/v1/public/signup
Content-Type: application/json

{"email": "<work email>", "first_name": "<first>", "last_name": "<last>", "agent": "<your name>"}
```

CLI equivalent: `discolike signup --email <work email> --first-name <first> --last-name <last>`. Ask the user for any value you do not know. Relay the `next_step` text from the response. Free-mail and disposable domains are rejected. `409` means the account exists, send the user to log in. Guide: https://docs.discolike.com/guides/agent-signup/

## How to search

Three ways to describe the target, all on the same `discover` call. Combine them.

| Want                 | Parameter                                                                                                                | Notes                                                                        |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| Plain-English ICP    | `icp_prompt`                                                                                                             | Extracts filters and seed domains from the sentence. Prefer over `icp_text`. |
| Companies like these | `domain` (up to 10)                                                                                                      | Ranked by similarity to what the seed companies do.                          |
| Homepage says X      | `phrase_match` (up to 20)                                                                                                | Exact text fragments.                                                        |
| Narrow               | `country`, `state`, `employee_range` ("51,500"), `revenue_range`, `tech_stack`, `category`, `language`, `business_model` | Every filter has a `negate_` twin.                                           |
| Size the set         | `count` with the same filters                                                                                            | Free. Do this before a large `discover`.                                     |
| Cap spend            | `max_records`                                                                                                            | Start with 100 to 500 to check fit, then scale.                              |

Each search bills a query fee plus a fee per 1,000 new records. Records seen in the last 90 days are free. Results cap at 10,000 per call: 10,000 is a page size, not a total. For more, put what you have into an exclusion list and run the next call with `exclusion_query_id`, and keep turning pages until the results run dry; `discolike bulk companies` runs that loop (`flows.md` Flow 10). Exclusion lists hold up to 250,000 domains and 500,000 contacts on every plan. `max_records` has a floor of 20. Contacts pulled per domain list have no 10,000 ceiling; page them by slicing the domain list, since `offset` is ignored when `results_by_company` is set.

Always set `variance` explicitly on API, CLI, and SDK calls (`MEDIUM` is the app default; the API default `UNRESTRICTED` turns the industry-drift guard off).

## After discovery

- Contacts at the matched companies: contacts search with a persona description, seniority, or department. Returns email, phone, LinkedIn. Emails are pattern-derived unless `email_validated` is set, which keeps only addresses we have verified.
- Enrich a list you already have: bizdata, vendors, growth, score, redirects, subsidiaries per domain, or bulk append from CSV.
- Segment a customer list into ICP clusters with descriptions, then run lookalikes per cluster.
- Validate a list against an ICP description: fit yes/no with a confidence level and reasoning per domain.
- Push to HubSpot, Salesforce, Pipedrive via the CRM tools.

Every one of these is a numbered flow in `flows.md`. Async steps return a job; wait on it before the next step. Save intermediate result sets as queries so later steps reference an id instead of re-sending domains.

## Examples

CLI:

```bash
discolike count --phrase-match "managed detection and response" --country DE
discolike discover --domain stripe.com --domain adyen.com --employee-range 51,500 --variance MEDIUM --max-records 500 --format json
discolike discover --icp-prompt "cybersecurity for SMBs, managed IT, endpoint protection" --country US --variance MEDIUM --max-records 100 --format json
```

Python:

```python
from discolike import Discolike
from discolike.requests import DiscoverParams, CountParams

client = Discolike()
n = client.count(CountParams(phrase_match=["managed detection and response"], country=["DE"])).count
companies = client.discover(DiscoverParams(domain=["stripe.com", "adyen.com"], employee_range="51,500", variance="MEDIUM", max_records=500))
```

## Related skills

- `setup`: install the pinned CLI launcher, sign in, verify the connection.
- `update`: move the plugin and its pinned CLI to the latest release.
- `feedback`: file a bug or product feedback with the DiscoLike team.

## Pointers

- MCP page and install snippets: https://discolike.com/mcp.md
- API page with examples: https://discolike.com/api.md
- Pricing for agents: https://discolike.com/pricing.md
- Everything: https://discolike.com/llms.txt
