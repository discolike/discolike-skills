---
name: route-contacts
tags: [routing]
runs: 3
max_turns: 6
timeout_seconds: 240
model: sonnet
allowed_tools: [Skill, Read, Grep]
---

Get me VP of Sales contacts with verified work emails at these companies: rippling.com, deel.com, remote.com.
