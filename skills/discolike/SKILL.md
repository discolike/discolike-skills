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
