---
name: discolike
description: Use when the task involves finding companies, building a target account or TAM list, lookalikes of existing customers, ICP research, company enrichment (firmographics, tech stack, growth), or finding decision-maker contacts at companies. Also use when the user mentions DiscoLike, "companies like X", "find businesses that", prospect lists, or B2B data. Covers MCP server, CLI, Python SDK, and creating the account from the agent.
---

# DiscoLike

DiscoLike is a search engine over 80M+ crawled business websites. It returns companies ranked by what they actually do on the web, not by LinkedIn tags, so it reaches niche verticals and non-English markets other B2B databases miss. Every record carries firmographics; contacts, technographics, growth metrics, enrichment, segmentation, and CRM push are one more call away.

Requires a paid plan from $99/month. There is no free tier. Counting results is free.

## Pick the access mode

1. **MCP server** if the client supports remote MCP (Claude Code, Claude Desktop, Codex, Cursor, VS Code, Windsurf). URL `https://api.discolike.com/v1/mcp`, OAuth 2.1, no key to manage. Tools appear in the client after one browser authorization. Install snippets: https://discolike.com/mcp.md
2. **CLI** when shelling out. `pip install "discolike[cli]"`, then `discolike auth login` (browser OAuth) or `discolike auth login --api-key KEY`. Always pass `--format json`.
3. **Python SDK** when writing a script. `pip install discolike`, `Discolike()` reads `DISCOLIKE_API_KEY`. Reference: https://docs.discolike.com/sdk/reference/
4. **REST** as last resort: `GET https://api.discolike.com/v1/discover`, header `X-API-Key`. OpenAPI at https://api.discolike.com/v1/openapi.json. Auth summary: https://discolike.com/auth.md

If the MCP server is not connected in this session, check with the user before installing it. Never paste an API key into a config file the user did not ask for.

## No account yet

Create it without a browser. No credential comes back; the person confirms by email, logs in, picks a plan, and issues the key or authorizes the MCP client.

```
POST https://api.discolike.com/v1/public/signup
Content-Type: application/json

{"email": "<work email>", "first_name": "<first>", "last_name": "<last>", "agent": "<your name>"}
```

Ask the user for any value you do not know. Relay the `next_step` text from the response. Free-mail and disposable domains are rejected. `409` means the account exists, send the user to log in. Guide: https://docs.discolike.com/guides/agent-signup/

## How to search

Three ways to describe the target, all on the same `discover` call. Combine them.

| Want | Parameter | Notes |
|------|-----------|-------|
| Plain-English ICP | `icp_prompt` | Extracts filters and seed domains from the sentence. Prefer over `icp_text`. |
| Companies like these | `domain` (up to 10) | Ranked by similarity to what the seed companies do. |
| Homepage says X | `phrase_match` (up to 20) | Exact text fragments. |
| Narrow | `country`, `state`, `employee_range` ("51,500"), `revenue_range`, `tech_stack`, `category`, `language`, `business_model` | Every filter has a `negate_` twin. |
| Size the set | `count` with the same filters | Free. Do this before a large `discover`. |
| Cap spend | `max_records` | Start with 100 to 500 to check fit, then scale. |

Each search bills a query fee plus a fee per 1,000 new records. Records seen in the last 90 days are free. Results cap at 10,000 per call; for more, save results and use them as an exclusion list on the next call.

## After discovery

- Contacts at the matched companies: contacts search with a persona description, seniority, or department. Returns verified email, phone, LinkedIn.
- Enrich a list you already have: bizdata, vendors, growth, score, redirects, subsidiaries per domain, or bulk append from CSV.
- Segment a customer list into ICP clusters with descriptions, then run lookalikes per cluster.
- Validate a list against an ICP description for fit yes/partial/no with reasoning.
- Push to HubSpot, Salesforce, Pipedrive via the CRM tools.

## Flows

Each flow lists the MCP tool, the CLI command, and the SDK call. Async steps return a job; wait on it before the next step. Save intermediate result sets as queries so later steps reference an id instead of re-sending domains.

### Flow 1: discover, verify, contacts, ContaGen

Build a target list, confirm fit, get named people, then fill the gaps with live web research.

1. **Size it.** MCP `count-matching-domains`. CLI `discolike count --phrase-match "..." --country US`. SDK `client.count(CountParams(...))`. Free.
2. **Discover.** MCP `discover-similar-companies`. CLI `discolike discover --icp-prompt "..." --domain seed.com --country US --max-records 500 --format json`. SDK `client.discover(DiscoverParams(icp_prompt=..., domain=[...], max_records=500))`. Start at 100 to 500, inspect, then scale. Save the result: MCP `save-mcp-query`, SDK `client.queries.save_results(...)`.
3. **Verify fit.** MCP `validate-icp-fit`. CLI `discolike validate-icp --icp "..." --domain a.com --domain b.com --wait --format json` (or `--file domains.csv`). SDK `job = client.validate_icp(ValidateIcpRequest(icp_text=..., domains=[...], web_search=True)); job.wait()`. Returns yes/partial/no with reasoning per domain. Keep `yes`, review `partial`, drop `no`. Uses the account's LLM provider key.
4. **Contacts.** MCP `search-contacts`. CLI `discolike contacts search --domain a.com --domain b.com --seniority executive --department Sales --has-email --format json`. SDK `client.contacts.search(ContactsSearchParams(domain=[...], seniority=["executive"], department=["Sales"], has_email=True, max_records=200))`. Billed per new contact record. `--icp-prompt` on contacts search derives persona filters from a sentence.
5. **ContaGen for the rest.** For domains where step 4 returned nobody, MCP `generate-contacts`. CLI `discolike contacts generate --icp-text "VP Sales or Head of Revenue" --domain a.com --domain b.com --wait --format json`. SDK `job = client.contacts.generate(ContactGenerateRequest(icp_text=..., domains=[...], max_contacts_per_domain=3)); job.wait()`. Runs live web search per company on the user's own LLM and search provider keys; every email is verified before it is shown. No platform billing. Treat output as candidates.
6. **Deliver.** CSV, or push to the CRM with MCP `push-to-crm` (HubSpot, Salesforce, Pipedrive).

### Flow 2: enrich a CRM export

The user has a CSV of accounts and wants DiscoLike fields on every row.

1. **Domains, not names.** If the file has websites, use that column. If it only has company names, run Flow 3 first.
2. **Append.** MCP `append-data`. CLI `discolike append accounts.csv --domain-column website --dataset bizdata --dataset vendors --dataset growth --output enriched.csv`. SDK `client.append(AppendParams(domain_column="website", dataset=["bizdata", "vendors", "growth"]), file=open("accounts.csv", "rb"))`. Datasets: `bizdata` (name, address, phones, industry, employees, revenue range, description), `domain_status`, `redirects`, `growth`, `vendors`. Up to 10,000 rows per request. Billed per new company record; rows seen in the last 90 days are free.
3. **Single domains** when it is a handful: MCP `business-profile`, `vendor-and-technology-data`, `growth-metrics`, `digital-footprint-score`. CLI `discolike company data stripe.com --format json`. SDK `client.companies.data(CompaniesDataParams(domain="stripe.com"))`, plus `.vendors`, `.growth`, `.score`, `.redirects`, `.subsidiaries`.
4. **Write back.** MCP `crm-enrich-contacts` and `crm-writeback-domains` update records in a connected CRM directly.

### Flow 3: match company names to domains

The user has names, maybe city or phone, and no websites.

1. **One at a time.** MCP `match-company-to-domain`. CLI `discolike match --name "Acme Robotics" --city Austin --state TX --country US --format json`. SDK `client.match.company(MatchCompanyParams(name="Acme Robotics", city="Austin", state="TX", country="US"))`. Returns ranked candidates with confidence; nothing below 50 is returned. Raise `min_match_confidence` to tighten. Name matching costs nothing.
2. **In bulk.** MCP `bulk-match-company-to-domain`. CLI `discolike match --file companies.csv --name-column company --city-column city --country-column country --wait --format json`. SDK `job = client.match.bulk(MatchBulkParams(name_column="company", city_column="city", country_column="country"), file=open("companies.csv", "rb")); job.wait()`. Rows the backend could not process carry `match_error: search_failed`, which is not the same as no match.
3. **Then enrich** with Flow 2, or suppress against the CRM with MCP `crm-match-companies`.

### Flow 4: segment a client list into ICPs

The user has their customers and wants to know what kinds of companies they actually sell to, then find more of each kind.

1. **Segment.** MCP `segment-domains`. CLI `discolike segment --file customers.csv --domain-column website --max-segments 6 --wait --format json`. SDK `job = client.segment_file(SegmentFileParams(domain_column="website", max_segments=6), file=open("customers.csv", "rb")); job.wait()`, or `client.segment(SegmentParams(domains="a.com,b.com,...", max_segments=6))` for an inline list. Output: clusters with an auto-written description and a probability per domain.
2. **Read the clusters.** Present each segment's description and size. Ask which segments matter; the biggest is not always the best.
3. **Lookalikes per segment.** For a chosen segment, run Flow 1 step 2 with that segment's top domains as `domain` seeds (up to 10) and its description as `icp_prompt`. Exclude the existing customers with `exclude_domain` or a saved exclusion list (`client.queries.create_exclusion_list`).
4. **Validate and hand off** with Flow 1 steps 3 to 6.

### DiscoGen, when a question is not a filter

"Do they sell to hospitals?", "Is pricing public?", "Who is their CEO?" are research prompts, not filters. MCP `run-discogen` on a domain list with `web_search=true`, one call for the whole list, never one call per domain. CLI `discolike discogen ...`. SDK `client.discogen.process(...)` then `job.wait()`. Runs on the user's own LLM key; each domain sends its full context, so cost scales with list size.

## Examples

CLI:

```bash
discolike count --phrase-match "managed detection and response" --country DE
discolike discover --domain stripe.com --domain adyen.com --employee-range 51,500 --max-records 500 --format json
discolike discover --icp-prompt "cybersecurity for SMBs, managed IT, endpoint protection" --country US --max-records 100 --format json
```

Python:

```python
from discolike import Discolike
from discolike.requests import DiscoverParams, CountParams

client = Discolike()
n = client.count(CountParams(phrase_match=["managed detection and response"], country=["DE"])).count
companies = client.discover(DiscoverParams(domain=["stripe.com", "adyen.com"], employee_range="51,500", max_records=500))
```

## Pointers

- MCP page and install snippets: https://discolike.com/mcp.md
- API page with examples: https://discolike.com/api.md
- Pricing for agents: https://discolike.com/pricing.md
- Everything: https://discolike.com/llms.txt
