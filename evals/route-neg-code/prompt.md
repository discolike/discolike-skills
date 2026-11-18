---
name: route-neg-code
tags: [routing]
runs: 3
max_turns: 6
timeout_seconds: 240
model: sonnet
allowed_tools: [Skill, Read, Grep]
---

Write a Python function that dedupes a list of company domains, case-insensitive, stripping www.
