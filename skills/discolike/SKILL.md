---
name: discolike
description: Use when the task involves finding companies, building a target account or TAM list, lookalikes of existing customers, ICP research, company enrichment (firmographics, tech stack, growth), or finding decision-maker contacts at companies. Also use when the user mentions DiscoLike, "companies like X", "find businesses that", prospect lists, or B2B data. Covers MCP server, CLI, Python SDK, and creating the account from the agent.
allowed-tools: Read, Grep
---

# DiscoLike

DiscoLike is a search engine over 80M+ crawled business websites. It returns companies ranked by what they actually do on the web, including niche verticals and non-English markets. Every domain is re-validated by SSL certificate about every 30 days, so results never contain dead or parked domains and none are billed. Every record carries firmographics; contacts, technographics, growth metrics, enrichment, segmentation, and CRM push are one more call away.

Requires a paid plan. Counting results is free.

## Files in this skill

| File                 | Read it when                                                                                                                                                                                              |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `flows.md`           | Running any end-to-end job: target list, CRM enrichment, name-to-domain matching, ICP segmentation, market map, ICP from a website, signal qualification, tech-stack targeting, scoring an existing list. |
| `troubleshooting.md` | Results look noisy, counts do not add up, or the user says "these are wrong".                                                                                                                             |
| `flows.md` Flow 10   | The user wants everything that matches, tens of thousands of companies or 100,000+ contacts, or asks to replicate an app search over the API.                                                             |

Read a file when its row applies; do not load both up front. A question that no filter or signal answers ("do they sell to hospitals?", "estimated ad spend?") is research: use the deterministic signals in `flows.md` Flow 7 first, and if the question still needs research, tell the user DiscoLike's web app and REST API cover it.

## How to work

- **Confirm the account once.** First DiscoLike call in a session: MCP `account-status`, CLI `discolike account usage`, or SDK `client.account.usage()`. Tell the user the plan and remaining quota in one line. If it fails on auth, run the `setup` skill.
- **Narrate, then summarize.** Say what you are about to run and why; turn JSON into a count, a short table, or a sentence. Raw output only on request. Write full result sets to disk as JSON or CSV; chat output truncates.
- **Position it as DiscoLike's product.** "DiscoLike lets you…", "you can…". Not "skills I have".
- **Spend rule.** Counting is free. Company discovery and enrichment use the plan's quota. Contacts delivery costs 5 records per validated contact, with a $10 per 1,000 contacts floor, plus 1 record per company delivering at least one when searching without a supplied company list. Both contact statuses cost the same. Every delivery is billed, including repeats. Before a paid pull larger than a sample (about 100 records), explain the scope and cost and get a yes. For contacts, agree the company target, maximum per company and delivery budget before starting; the run proceeds automatically. Reuse approval for the same scope; ask again only if the scope or estimate grows. Do not volunteer the balance otherwise.
- **Plain CLI calls.** One `discolike` command at a time, `--format json`, optionally piped to `jq`.

## Pick the access mode

1. **MCP server** if the client supports remote MCP (Claude Code, Claude Desktop, Codex, Cursor, VS Code, Windsurf). URL `https://api.discolike.com/v1/mcp`, OAuth 2.1, no key to manage. Tools appear in the client after one browser authorization. Install snippets: https://discolike.com/mcp.md
2. **CLI** when shelling out. Ask the user to install it (`pip install discolike-cli`, 0.4.1 or later); do not install packages yourself. The `setup` skill walks through it. Sign in with `discolike auth login` (browser OAuth). With an API key, the user sets `DISCOLIKE_API_KEY` in their own shell or runs `discolike auth login --api-key` themselves; never ask for the key in chat. Always pass `--format json`. `discolike --help` prints the output contract and exit codes.
3. **Python SDK** when writing a script. The user adds the `discolike` package to their project; `Discolike()` reads `DISCOLIKE_API_KEY`. Reference: https://docs.discolike.com/sdk/reference/
4. **REST** as last resort: `GET https://api.discolike.com/v1/discover`, header `X-API-Key`. OpenAPI at https://api.discolike.com/v1/openapi.json. Auth summary: https://discolike.com/auth.md

If neither MCP nor CLI is signed in, run the `setup` skill. Never paste an API key into a config file the user did not ask for.

## No account yet

Create it without a browser. No credential comes back; the person confirms by email, logs in, picks a plan, and issues the key or authorizes the MCP client. Before either method below, ask the user for any value you do not know, show them the exact email and name, and send only after they say yes.

```
POST https://api.discolike.com/v1/public/signup
Content-Type: application/json

{"email": "<work email>", "first_name": "<first>", "last_name": "<last>", "agent": "<your name>"}
```

CLI equivalent: `discolike signup --email 'jane@acme.com' --first-name 'Jane' --last-name 'Doe'`, every value single-quoted (double quotes for a name with an apostrophe). Relay the `next_step` text from the response. Free-mail and disposable domains are rejected. `409` means the account exists, send the user to log in. Guide: https://docs.discolike.com/guides/agent-signup/

## How to search

Three ways to describe the target, all on the same `discover` call. Combine them.

| Want                 | Parameter                                                                                                                                | Notes                                                                                                                                                                                                                                                                                                                                          |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Plain-English ICP    | `icp_prompt`                                                                                                                             | Extracts filters and seed domains from the sentence. This is how an ICP is described on `discover`.                                                                                                                                                                                                                                            |
| Companies like these | `domain` (up to 10)                                                                                                                      | Ranked by similarity to what the seed companies do. Confirm each one with `extract-website-text` before the first pull; a guessed domain that resolves to the wrong business drags the whole ranking with it.                                                                                                                                  |
| Homepage says X      | `phrase_match` (up to 20)                                                                                                                | Exact text fragments, OR by default: every phrase added widens the set. Prefix with `+` to require one.                                                                                                                                                                                                                                        |
| Narrow               | `country`, `state`, `employee_range` ("51,500"), `revenue_range`, `tech_stack`, `category`, `sub_industry`, `language`, `business_model` | Every filter has a `negate_` twin. `sub_industry` is a second-level label, bare or `PARENT/SUB` (`ROOFING`, `CONSTRUCTION/ROOFING`). `country` also takes region codes: `EUROPE`, `ASIA` and the other continents, or `EU` for the 27 member states only.                                                                                      |
| Near a place         | `lat`, `lon`, `radius` (`50km`, `30mi`; default 50km) or `bbox` (`min_lat,min_lon,max_lat,max_lon`)                                      | Radius and bbox are mutually exclusive.                                                                                                                                                                                                                                                                                                        |
| Size the set         | `count` with the same filters                                                                                                            | Free. Do this before a large `discover`. It sizes the hard market definition, not the lookalike ranking: it takes no seed `domain` and no ICP description, and defaults `exclude_leadgen` to false where `discover` defaults it to true, so it reads higher than the pull that follows. Pass `exclude_leadgen=true` to compare like with like. |
| Cap spend            | `max_records`                                                                                                                            | Start with 100 to 500 to check fit, then scale.                                                                                                                                                                                                                                                                                                |

Company discovery and enrichment records seen in the last 24 hours on Pay as you go or 30 days on subscriptions are not billed again. Contacts delivery is billed every time. Results cap at 10,000 per call: 10,000 is a page size, not a total. For more, put what you have into an exclusion list and run the next call with `exclusion_query_id`, and keep turning pages until the results run dry; `discolike bulk companies` runs that loop (`flows.md` Flow 10). Exclusion lists hold up to 250,000 domains and 500,000 contacts on every plan. `max_records` has a floor of 20.

Set `relevance` on discover (MCP, API, CLI, SDK) to stop the ranked list once estimated ICP fit drops too low: `BALANCED` by default for mapping a market, `MAX_RELEVANCE` when the user wants only the closest matches, `MAX_COVERAGE` when they want the whole market and accept a borderline tail. Leaving it out means no automatic stop. An empty later page means the search reached the edge of the market. `variance` is deprecated; old values map onto `relevance`.

## After discovery

- Contacts at the matched companies: MCP `find-contacts`, then `get-contacts-run`; optionally `cancel-contacts-run` or `push-to-crm` with the contacts run. Inputs are companies, fit text (default "Senior executives and decision makers"), maximum companies and maximum per company (`flows.md` Flow 1). Only Validated and Validated (catch-all resolved) contacts are delivered, with their work emails already validated. Do not re-verify them: Validated (catch-all resolved) proves the mailbox even when another verifier reports catch-all or unknown.
- Enrich a list you already have: bizdata, vendors, growth, score, redirects, subsidiaries per domain, or bulk append from CSV.
- Find lookalikes of a customer list segment by segment: segment the customers, then run lookalikes per cluster (Flow 4).
- Validate a list against an ICP description: fit per company with a confidence level (`flows.md` Flow 1 step 3).
- Push to HubSpot, Salesforce, Pipedrive via the CRM tools.

Every one of these is a numbered flow in `flows.md`. Async steps return a job; wait on it before the next step. Save intermediate result sets as queries so later steps reference an id instead of re-sending domains.

## Examples

CLI:

```bash
discolike count --phrase-match "managed detection and response" --country DE
discolike discover --domain stripe.com --domain adyen.com --employee-range 51,500 --param relevance=BALANCED --max-records 500 --format json
discolike discover --icp-prompt "cybersecurity for SMBs, managed IT, endpoint protection" --country US --param relevance=MAX_RELEVANCE --max-records 100 --format json
```

Python:

```python
from discolike import Discolike
from discolike.requests import DiscoverParams, CountParams

client = Discolike()
n = client.count(CountParams(phrase_match=["managed detection and response"], country=["DE"])).count
companies = client.discover(DiscoverParams(domain=["stripe.com", "adyen.com"], employee_range="51,500", relevance="BALANCED", max_records=500))
```

## Related skills

- `setup`: get the CLI installed, sign in, verify the connection.
- `feedback`: file a bug or product feedback with the DiscoLike team.

## Pointers

- MCP page and install snippets: https://discolike.com/mcp.md
- API page with examples: https://discolike.com/api.md
- Everything: https://discolike.com/llms.txt
