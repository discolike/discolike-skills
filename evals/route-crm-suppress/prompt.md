---
name: route-crm-suppress
tags: [routing]
runs: 3
max_turns: 6
timeout_seconds: 240
model: sonnet
allowed_tools: [Skill, Read, Grep]
---

Don't show me companies that are already in my Salesforce in future DiscoLike searches.
