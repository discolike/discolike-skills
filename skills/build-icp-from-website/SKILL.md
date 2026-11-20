---
name: build-icp-from-website
description: Use when the user asks to "set up my ICP", "build an ICP from our website", or draft an ICP from a best customer's domain. Follow the discolike skill's access and spend rules.
allowed-tools: Read, Grep
---

# Build an ICP from a website

Follow the `discolike` skill's How to work rules first.

New account, no ICP written down, or "set up my ICP".

1. **Read the source.** MCP `extract-website-text` on the user's own domain, or on their best customer's. CLI `discolike extract https://example.com --format json`. SDK `client.companies.extract(CompaniesExtractParams(domain="example.com"))`.
2. **Draft.** From the text write one `icp_prompt` sentence, two or three `phrase_match` candidates, a `category`, and the filters that are truly hard (country, business model). A candidate phrase has to distinguish the target, not merely appear on its site: if it would be strange for a company printing that phrase prominently _not_ to be in the ICP, keep it, otherwise drop it. Split hard filters from preferences: if the user would still contact a company without it, it is a preference, so leave it out of the filter and let ranking handle it. Target geography is a filter the user sets, not something to infer from where the seed customers happen to be based.
3. **Count each phrase** on its own. A phrase that counts in the hundreds is a filter; one in the tens is a seed list; one in the hundreds of thousands is noise.
4. **Sample 25.** Show domains and one-line descriptions. Ask the user to mark fits and misses in place.
5. **Correct and save.** Adjust from the marks, re-sample once, then save the query with a name and tags. Start every later job from that id.
