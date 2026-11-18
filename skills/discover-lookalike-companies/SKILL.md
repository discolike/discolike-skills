---
name: discover-lookalike-companies
description: Use when the user asks for a target account list, a list of "companies like X", or to "find businesses that" match an ICP. Follow the discolike skill's access and spend rules.
allowed-tools: Read, Grep
---

# Build a target account list

Follow the `discolike` skill's How to work rules first.

1. **Size it.** MCP `count-matching-domains`. CLI `discolike count --phrase-match "..." --country US`. SDK `client.count(CountParams(...))`. Free.
2. **Discover.** MCP `discover-similar-companies`. CLI `discolike discover --icp-prompt "..." --domain seed.com --country US --max-records 500 --format json`. SDK `client.discover(DiscoverParams(icp_prompt=..., domain=[...], max_records=500))`. Start at 100 to 500, inspect, then scale. Do not set an employee minimum unless asked; small-company headcount data is thin and rarely what disqualifies. After every pull, add its domains to an exclusion list: MCP `save-exclusion-list`, CLI `discolike queries create-exclusion-list --name "tam-round-1" --domains-file round1.csv --tag tam` (a `domain` column or one domain per line; `--domain` for a handful), SDK `client.queries.create_exclusion_list(CreateExclusionListRequest(query_name="tam-round-1", domains=[...], tags=["tam"]))`. Pass that list's id as `exclusion_query_id` on the next pull so rounds never overlap. Save the search itself with `save-mcp-query` or `queries save-results` only when you want to rerun it later.
