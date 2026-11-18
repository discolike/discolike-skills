---
name: route-enrich
tags: [routing]
runs: 3
max_turns: 6
timeout_seconds: 240
model: sonnet
allowed_tools: [Skill, Read, Grep]
---

Append firmographics, employee counts and tech stack to every row of this CSV of account websites.
