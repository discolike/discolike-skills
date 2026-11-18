---
name: discolike-market-map
description: Use when the user asks to "map our whole addressable market", "find thousands of accounts", or "get every company that matches", including pulls past 10,000 companies. Follow the discolike skill's access and spend rules.
allowed-tools: Read, Grep
---

# Map an addressable market

Follow the `discolike` skill's How to work rules first.

The user wants the whole addressable market, thousands of accounts, not a sample. Once the query is calibrated, use the paging instructions below past 10,000 companies. When the user wants contacts at every account, use the batching instructions in the `discolike-contacts` skill.

1. **Anchor.** Count with the structural filters alone (country, size, category). That number is the ceiling; if it is far from the user's own estimate, the filters are wrong, fix them before spending.
2. **Calibrate on 50.** One inclusion-only pull, `max_records=50`, seeds plus `icp_prompt`, `relevance="BALANCED"`, no negations. Validate fit. Then change one lever per round: first exclude the high-similarity wrong-category anchors, then add two or three confirmed fits as seeds, and only then add a phrase. Never negate a phrase the real targets also use. Excluding a domain: MCP `discover-similar-companies` with `negate_domain` (shapes the ranking), CLI `--param negate_domain=a.com,b.com`, SDK `exclude_domain` (hard filter only). Re-run at 200 and read ranks 1 to 10, 90 to 100, and 190 to 200; quality decays with rank, and the tail tells you where to stop.
3. **Round.** Pull 500 to 1,000. Add every domain to the exclusion list. Validate. Record fit rate.
4. **Next round.** Same query, `exclusion_query_id` pointing at the exclusion list, two new seeds from the last round's best fits, `max_records` up to 1,000. Repeat. One list per market map, grown each round, is simpler than one list per round.
5. **Stop.** When a round's fit rate drops under about 30 percent, or net-new fits fall under 5 percent of the pull, the market is mapped. Push past that only with a different `icp_prompt` (an adjacent segment), not a bigger `max_records`.
6. **Deliver.** Union the rounds, dedupe on bare domain, keep the round number and similarity on each row.

A 70/20/10 split works for a portfolio: 70 percent of records from the proven prompt, 20 from an adjacent one, 10 from an experimental one, all sharing the one exclusion list.

## Page large company pulls

Calibrate the company query first using the steps above. Page company discovery with exclusion lists so pages do not overlap; 10,000 is the per-call company limit. Count the market before committing to a large paid company pull.
