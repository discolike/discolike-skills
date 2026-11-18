---
name: route-match
tags: [routing]
runs: 3
max_turns: 6
timeout_seconds: 240
model: sonnet
allowed_tools: [Skill, Read, Grep]
---

I have a spreadsheet of 800 company names with city and state but no websites. Find the domain for each.
