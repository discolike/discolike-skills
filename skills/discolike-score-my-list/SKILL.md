---
name: discolike-score-my-list
description: Use when the user asks to "score these 3,000 accounts against our ICP", "which of our customers run HubSpot", or "run research on this list". Follow the discolike skill's access and spend rules.
allowed-tools: Read, Grep
---

# Rank or filter a list the user already has

Follow the `discolike` skill's How to work rules first.

"Score these 3,000 accounts against our ICP", "which of our customers run HubSpot", "run research on this list".

1. **Load the list.** A saved domain list serves as inclusion scope as well as exclusion; the upload path is the same. MCP `save-exclusion-list`; CLI `discolike queries create-exclusion-list --name "crm-accounts" --domains-file crm.csv`; SDK `client.queries.create_exclusion_list(CreateExclusionListRequest(query_name="crm-accounts", domains=[...]))`. Minimum 20 domains. Names first? Load the `discolike-match-domains` skill.
2. **Rank it.** Discover with `inclusion_query_id` set to that list plus an `icp_prompt` or seed domains; the response is the user's own companies ordered by similarity, with firmographics. Available from Starter. CLI `--inclusion-query-id <id>`; SDK `DiscoverParams(inclusion_query_id=[...], icp_prompt=...)`.
3. **Bucket it.** Same call with `tech_stack` instead of a prompt returns only the companies on that vendor. Repeat per vendor to split the list.
4. **Check and staff it.** Use the `discolike-contacts` skill to verify fit and find people with a contacts run on the list (`run.companies` set to a domain list, up to 10,000 domains per run). For questions no filter answers, see Research for the rest in the `discolike-signals-and-tech` skill.
5. **Explain the gaps.** Domains that return no profile are not lost: `append` with dataset `domain_status` says why (non-business, parked, dead, redirect, no certificate).
