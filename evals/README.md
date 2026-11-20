# Skill routing evals

Each `route-*` case sends one user prompt and checks which skill the agent loads: `graders/routed.md` requires the expected skill, and `graders/not-*.md` fail if a confusable sibling loads instead. The two `route-neg-*` cases must load no DiscoLike skill at all. The DiscoLike MCP server is not started, so the runs never touch an account.

```bash
claude plugin eval . --ablation none --case 'route-*'
```

Each case runs 3 times on Sonnet; a full pass costs about $3. Run it after changing any skill `description`, since descriptions are what route the agent. A case that passes only some runs is a description overlap, not noise: tighten the two descriptions rather than the prompt.

Add a case when you add a skill, and add a `not-<skill>.md` grader for each sibling it could be confused with.
