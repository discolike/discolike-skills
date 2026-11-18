---
name: discolike-contacts
description: Use when the user asks to "find VP Sales contacts at these companies", "get validated work emails", "check company fit", or deliver contacts at scale. Follow the discolike skill's access and spend rules.
allowed-tools: Read, Grep
---

# Deliver validated contacts

Follow the `discolike` skill's How to work rules first.

Build a target list, check company fit if needed, then find people with validated work emails. If you need to build the list, load the `discolike-target-list` skill.

Use MCP for contacts.

1. **Check company fit if needed.** MCP `discover-similar-companies` with company criteria inside `filters` and `validate=true` returns an automatic companies run. Poll `get-contacts-run` with its `run_id`; read `fit_label` and `p_fit` on each company row. This checks the companies against the ICP.
2. **Start contacts.** MCP `find-contacts` takes a `run` object. Select companies using one of the objects below. Set `run.people.fit` to a plain-language description of the people wanted; the default is "Senior executives and decision makers". Set `run.max_companies` (1 to 10,000, default 500) and `run.per_company` (1 to 50, default 10). `max_companies` counts companies delivering at least one validated contact. Optional `run.email_cap` limits delivery spend in USD; `run.create_key` makes a start retry idempotent. `run.exclude_query_ids` and `run.exclude_domains` exclude companies already worked. The run starts automatically.

   Company selections for `run.companies`:
   - Prompt: `{"source": "prompt", "icp_text": "US cybersecurity consultancies"}`.
   - Domain list: `{"source": "domains", "domains": ["example.com"]}` (up to 10,000 domains).
   - Lookalikes: `{"source": "lookalike", "persona_ids": [123]}` using actual persona IDs from prior results.

   Example MCP arguments:

   ```json
   {
     "run": {
       "companies": { "source": "domains", "domains": ["example.com"] },
       "people": { "fit": "Senior executives and decision makers" },
       "max_companies": 1,
       "per_company": 3,
       "email_cap": 1
     }
   }
   ```

3. **Follow and page results.** Poll `get-contacts-run` with `run_id`. Pass the returned `next_cursor` as `events_after` for new progress events. `rows_offset` and `rows_limit` page companies, keeping each company's contacts together; MCP allows 1 to 100 companies per page (default 50). Advance the offset by the page size and compare with `companies_total`; `rows_total` counts contacts, not pages. `companies` contains live company status and contacts; `rows` contains the delivered contact rows. Optional `fields` selects fields in `rows`. Omit `run_id` to list 20 recent runs and use `before` to page older ones. Runs expire after 30 days idle.
4. **Read validated delivery.** Contacts appear only with status Validated or Validated (catch-all resolved) and a validated work email. Do not re-verify either status. Validated (catch-all resolved) means the mailbox was proved on a domain that accepts all mail; another verifier may report catch-all or unknown. Every delivery, including repeats, costs 5 records per validated contact with a $10 per 1,000 contacts floor, plus 1 record per company delivering at least one when searching without a supplied company list. Companies with none are free. On completion or cancellation, report `summary.companies_delivered`, `summary.validated_contacts` and `summary.spent_usd`. Report shortfalls rather than assuming the requested target was met.
5. **Stop or deliver.** Use `cancel-contacts-run` with `run_id` to stop and retain already validated results; reading and cancellation remain available after quota exhaustion. Export validated results as CSV, or use `push-to-crm` with `run_id` and `provider` (`hubspot`, `salesforce`, `pipedrive`). It accepts an owned run with completed or partial validated results. Explain when results are partial. Supply exactly one of `run_id` or `query_id`; `mode="enrich"` updates existing CRM records only, while the default `mode="push"` creates or updates them.

Contacts instructions here describe the verified MCP contract. Check the installed CLI/SDK help before using equivalents; do not translate these arguments into guessed commands. The released `POST /contacts/discover` contract is unchanged.

## Batch large contact lists

For contacts, use the same validated delivery flow at every size (steps 2 to 5 above). Split company domains into batches of at most 10,000 and set `run.max_companies`, `run.per_company` and an agreed `run.email_cap` for each batch. Poll and page each run by company. Export rows as they arrive and record the run ID and progress cursor so recovery reads the existing run. Use `run.create_key` when retrying the same start request. Starting a new run delivers and bills contacts again, even for companies already processed. Do not estimate yield or throughput from the maximum per company; report actual validated contacts and companies covered.
