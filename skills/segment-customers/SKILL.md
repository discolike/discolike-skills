---
name: segment-customers
description: Use when the user asks to "segment our customer list", "what kinds of companies do we sell to?", or "find more customers like each segment". Follow the discolike skill's access and spend rules.
allowed-tools: Read, Grep
---

# Segment a client list into ICPs

Follow the `discolike` skill's How to work rules first.

The user has their customers and wants to know what kinds of companies they actually sell to, then find more of each kind.

1. **Segment.** MCP `segment-domains`. CLI `discolike segment --file customers.csv --domain-column website --max-segments 6 --wait --format json`. SDK `job = client.segment_file(SegmentFileParams(domain_column="website", max_segments=6), file=open("customers.csv", "rb")); job.wait()`, or `client.segment(SegmentParams(domains="a.com,b.com,...", max_segments=6))` for an inline list. Output: clusters with an auto-written description and a probability per domain.
2. **Read the clusters.** Present each segment's description and size. Ask which segments matter; the biggest is not always the best.
3. **Lookalikes per segment.** For a chosen segment, follow the Discover step in the `discover-lookalike-companies` skill with that segment's top domains as `domain` seeds (up to 10) and its description as `icp_prompt`. Exclude the existing customers with an exclusion list built from the customer file (MCP `save-exclusion-list`, CLI `discolike queries create-exclusion-list`, SDK `client.queries.create_exclusion_list`) passed as `exclusion_query_id`; `exclude_domain` is for a handful of domains, capped at 100.
4. **Validate and hand off** with the `find-validated-contacts` skill. Name each segment as a campaign lane and write the label to the CRM with MCP `crm-writeback-segments`, so every account carries exactly one lane and sequences stay separate.
