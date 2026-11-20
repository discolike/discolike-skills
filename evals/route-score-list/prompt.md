---
name: route-score-list
tags: [routing]
runs: 3
max_turns: 6
timeout_seconds: 240
model: sonnet
allowed_tools: [Skill, Read, Grep]
---

Rank the 3,000 accounts in our CRM export by how similar they are to our best customers, stripe.com and plaid.com.
