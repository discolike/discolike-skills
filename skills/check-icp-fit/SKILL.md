---
name: check-icp-fit
description: Use when the user asks "which of these fit our ICP", "validate this list", or "only contact companies that fit". Follow the `discolike` skill's access and spend rules.
allowed-tools: Read, Grep
---

# Check company fit

Follow the `discolike` skill's How to work rules first.

1. **Get the criteria and domains.** Ask for the company ICP and the list to assess. Use the `match-company-domains` skill if the list has names only. For an exact list or a contacts handoff, go straight to direct validation in step 4.
2. **Check fit during discovery.** MCP `discover-similar-companies` takes `validate=true` and a `filters` object with `icp_prompt` or `icp_text`, any other company search filters, and `max_records` to cap the companies run. Use `filters.inclusion_query_id` to restrict discovery to a saved list. The native model uses the company profile and homepage text. MCP exposes no context-mode or web-search switch for validation.
3. **Poll an MCP companies run.** Pass its `run_id` to `get-contacts-run`. Read `steps.validate.status` and the `validated` and `fit` counts in `steps.validate.counts` when the step finishes. The poll response omits the stored per-domain verdicts. `fit_label` and `p_fit` are contact row fields. For decisions about individual companies, validate those domains directly.
4. **Validate a list directly.** Use REST `POST /v1/validate/icp` with `domains` and `icp_text`. For the native model, set `integration_id="native-icp"`; it uses website context and disables web search. The native result has `fit` (`Yes` or `No`), `score` (probability from 0 to 1), and a confidence note in `reasoning`. With an LLM integration (omit the ID to use the org default), choose `context_mode` from `website` (default), `profile`, or `domain`. Optional `web_search` defaults to false, and `search_provider_id` selects the search integration. LLM results have `fit` (`Yes` or `No`), `confidence` (`high`, `medium`, or `low`), and `reasoning`. Poll `GET /v1/discogen/status/{task_id}` for the results.
   - CLI `discolike validate-icp --icp "Your company criteria" --domains-file accounts.csv --integration-id native-icp --wait --format json`.
   - SDK `job = client.validate_icp(ValidateIcpRequest(icp_text="Your company criteria", domains=domains, integration_id="native-icp")); job.wait()`.
5. **Hand off the positive domains.** Keep only explicit `Yes` verdicts. Flag low-confidence positives for review and keep missing verdicts and errors out of the list. If the user wants contacts, pass the retained domains to the `find-validated-contacts` skill as a domain list. Keep the company ICP separate from the people criteria.
