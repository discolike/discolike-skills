# DiscoLike flows

Read the flow you need, not the file. Use MCP for the contacts and prospecting flows. Other flows include CLI and SDK examples where available. Load `troubleshooting.md` when results look wrong.

Async steps return a job or a run; wait on it before the next step. Save intermediate result sets as queries so later steps reference an id instead of re-sending domains.

Before any flow: check the account with MCP `account-status`, CLI `discolike account usage`, SDK `client.account.usage()`, and report it. Before any paid pull larger than a sample (roughly 100 records), tell the user the size and get a yes. Write raw results to disk as JSON or CSV; chat output truncates.

### Flow 1: discover companies and deliver validated contacts

Build a target list, check company fit if needed, then find people with validated work emails.

1. **Size it.** MCP `count-matching-domains`. CLI `discolike count --phrase-match "..." --country US`. SDK `client.count(CountParams(...))`. Free.
2. **Discover.** MCP `discover-similar-companies`. CLI `discolike discover --icp-prompt "..." --domain seed.com --country US --max-records 500 --format json`. SDK `client.discover(DiscoverParams(icp_prompt=..., domain=[...], max_records=500))`. Start at 100 to 500, inspect, then scale. Do not set an employee minimum unless asked; small-company headcount data is thin and rarely what disqualifies. After every pull, add its domains to an exclusion list: MCP `save-exclusion-list`, CLI `discolike queries create-exclusion-list --name "tam-round-1" --domains-file round1.csv --tag tam` (a `domain` column or one domain per line; `--domain` for a handful), SDK `client.queries.create_exclusion_list(CreateExclusionListRequest(query_name="tam-round-1", domains=[...], tags=["tam"]))`. Pass that list's id as `exclusion_query_id` on the next pull so rounds never overlap. Save the search itself with `save-mcp-query` or `queries save-results` only when you want to rerun it later.
3. **Check company fit if needed.** MCP `discover-similar-companies` with company criteria inside `filters` and `validate=true` returns an automatic companies run. Poll `get-contacts-run` with its `run_id`; read `fit_label` and `p_fit` on each company row. This checks the companies against the ICP.
4. **Start contacts.** MCP `find-contacts` takes a `run` object. Select companies using one of the objects below. Set `run.people.fit` to a plain-language description of the people wanted; the default is "Senior executives and decision makers". Set `run.max_companies` (1 to 10,000, default 500) and `run.per_company` (1 to 50, default 10). `max_companies` counts companies delivering at least one validated contact. Optional `run.email_cap` limits delivery spend in USD; `run.create_key` makes a start retry idempotent. `run.exclude_query_ids` and `run.exclude_domains` exclude companies already worked. The run starts automatically.

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

5. **Follow and page results.** Poll `get-contacts-run` with `run_id`. Pass the returned `next_cursor` as `events_after` for new progress events. `rows_offset` and `rows_limit` page companies, keeping each company's contacts together; MCP allows 1 to 100 companies per page (default 50). Advance the offset by the page size and compare with `companies_total`; `rows_total` counts contacts, not pages. `companies` contains live company status and contacts; `rows` contains the delivered contact rows. Optional `fields` selects fields in `rows`. Omit `run_id` to list 20 recent runs and use `before` to page older ones. Runs expire after 30 days idle.
6. **Read validated delivery.** Contacts appear only with status Validated or Validated (catch-all resolved) and a validated work email. Do not re-verify either status. Validated (catch-all resolved) means the mailbox was proved on a domain that accepts all mail; another verifier may report catch-all or unknown. Search is free. Every delivery, including repeats, costs 5 records per validated contact with a $10 per 1,000 contacts floor, plus 1 record per company delivering at least one. Companies with none are free. On completion or cancellation, report `summary.companies_delivered`, `summary.validated_contacts` and `summary.spent_usd`. Report shortfalls rather than assuming the requested target was met.
7. **Stop or deliver.** Use `cancel-contacts-run` with `run_id` to stop and retain already validated results; reading and cancellation remain available after quota exhaustion. Export validated results as CSV, or use `push-to-crm` with `run_id` and `provider` (`hubspot`, `salesforce`, `pipedrive`). It accepts an owned run with completed or partial validated results. Explain when results are partial. Supply exactly one of `run_id` or `query_id`; `mode="enrich"` updates existing CRM records only, while the default `mode="push"` creates or updates them.

Contacts instructions here describe the verified MCP contract. Check the installed CLI/SDK help before using equivalents; do not translate these arguments into guessed commands. The released `POST /contacts/discover` contract is unchanged.

### Flow 2: enrich a CRM export

The user has a CSV of accounts and wants DiscoLike fields on every row.

1. **Domains, not names.** If the file has websites, use that column, normalized: lowercase, scheme and `www.` stripped, path dropped. If it only has company names, run Flow 3 first. Parse and write CSV with a real CSV library; description fields contain commas.
2. **Append.** MCP `append-data`. CLI `discolike append accounts.csv --domain-column website --dataset bizdata --dataset vendors --dataset growth --output enriched.csv`. SDK `client.append(AppendParams(domain_column="website", dataset=["bizdata", "vendors", "growth"]), file=open("accounts.csv", "rb"))`. Datasets: `bizdata` (name, address, phones, industry, employees, revenue range, description), `domain_status`, `redirects`, `growth`, `vendors`. Up to 10,000 rows per request. Rows seen in the last 24 hours on the free plan or 30 days on subscriptions are not billed again.
3. **Single domains** when it is a handful: MCP `business-profile`, `vendor-and-technology-data`, `growth-metrics`, `digital-footprint-score`. CLI `discolike company data stripe.com --format json`. SDK `client.companies.data(CompaniesDataParams(domain="stripe.com"))`, plus `.vendors`, `.growth`, `.score`, `.redirects`, `.subsidiaries`.
4. **Connected CRM contacts.** MCP `crm-import-companies` with `provider` queues an import; its domain lists appear through `list-saved-queries`. Use the imported domains in `find-contacts`, poll `get-contacts-run`, then `push-to-crm` with the contacts `run_id`, `provider` and `mode="enrich"` to update existing records. For missing company domains, `crm-match-companies` produces a saved match query; `crm-writeback-domains` takes that `query_id` and `provider`.

### Flow 3: match company names to domains

The user has names, maybe city or phone, and no websites.

1. **One at a time.** MCP `match-company-to-domain`. CLI `discolike match --name "Acme Robotics" --city Austin --state TX --country US --format json`. SDK `client.match.company(MatchCompanyParams(name="Acme Robotics", city="Austin", state="TX", country="US"))`. Returns ranked candidates with confidence; nothing below 50 is returned. Raise `min_match_confidence` to tighten.
2. **In bulk.** MCP `bulk-match-company-to-domain`. CLI `discolike match --file companies.csv --name-column company --city-column city --country-column country --wait --format json`. SDK `job = client.match.bulk(MatchBulkParams(name_column="company", city_column="city", country_column="country"), file=open("companies.csv", "rb")); job.wait()`. Rows the backend could not process carry `match_error: search_failed`, which is not the same as no match.
3. **Then enrich** with Flow 2, or match domainless connected CRM companies with MCP `crm-match-companies`.

### Flow 4: segment a client list into ICPs

Prefer Flow 11 with `customer_domains`: it does steps 1 to 3 in one run, splits the target across segments and tags every company with its segment. Use the steps below when the user wants to review clusters before any search, or needs segments without prospecting.

The user has their customers and wants to know what kinds of companies they actually sell to, then find more of each kind.

1. **Segment.** MCP `segment-domains`. CLI `discolike segment --file customers.csv --domain-column website --max-segments 6 --wait --format json`. SDK `job = client.segment_file(SegmentFileParams(domain_column="website", max_segments=6), file=open("customers.csv", "rb")); job.wait()`, or `client.segment(SegmentParams(domains="a.com,b.com,...", max_segments=6))` for an inline list. Output: clusters with an auto-written description and a probability per domain.
2. **Read the clusters.** Present each segment's description and size. Ask which segments matter; the biggest is not always the best.
3. **Lookalikes per segment.** For a chosen segment, run Flow 1 step 2 with that segment's top domains as `domain` seeds (up to 10) and its description as `icp_prompt`. Exclude the existing customers with an exclusion list built from the customer file (MCP `save-exclusion-list`, CLI `discolike queries create-exclusion-list`, SDK `client.queries.create_exclusion_list`) passed as `exclusion_query_id`; `exclude_domain` is for a handful of domains, capped at 100.
4. **Validate and hand off** with Flow 1 steps 3 to 7. Name each segment as a campaign lane and write the label to the CRM with MCP `crm-writeback-segments`, so every account carries exactly one lane and sequences stay separate.

### Flow 5: market map to N

The user wants the whole addressable market, thousands of accounts, not a sample. Past 10,000, or when the user wants contacts at every account, use the paging and contacts batching in Flow 10 once the query is calibrated here.

1. **Anchor.** Count with the structural filters alone (country, size, category). That number is the ceiling; if it is far from the user's own estimate, the filters are wrong, fix them before spending.
2. **Calibrate on 50.** One inclusion-only pull, `max_records=50`, seeds plus `icp_prompt`, `relevance="BALANCED"`, no negations. Validate fit. Then change one lever per round: first exclude the high-similarity wrong-category anchors, then add two or three confirmed fits as seeds, and only then add a phrase. Never negate a phrase the real targets also use. Excluding a domain: MCP `discover-similar-companies` with `negate_domain` (shapes the ranking), CLI `--param negate_domain=a.com,b.com`, SDK `exclude_domain` (hard filter only). Re-run at 200 and read ranks 1 to 10, 90 to 100, and 190 to 200; quality decays with rank, and the tail tells you where to stop.
3. **Round.** Pull 500 to 1,000. Add every domain to the exclusion list. Validate. Record fit rate.
4. **Next round.** Same query, `exclusion_query_id` pointing at the exclusion list, two new seeds from the last round's best fits, `max_records` up to 1,000. Repeat. One list per market map, grown each round, is simpler than one list per round.
5. **Stop.** When a round's fit rate drops under about 30 percent, or net-new fits fall under 5 percent of the pull, the market is mapped. Push past that only with a different `icp_prompt` (an adjacent segment), not a bigger `max_records`.
6. **Deliver.** Union the rounds, dedupe on bare domain, keep the round number and similarity on each row.

A 70/20/10 split works for a portfolio: 70 percent of records from the proven prompt, 20 from an adjacent one, 10 from an experimental one, all sharing the one exclusion list.

### Flow 6: ICP from a website

New account, no ICP written down, or "set up my ICP".

1. **Read the source.** MCP `extract-website-text` on the user's own domain, or on their best customer's. CLI `discolike extract https://example.com --format json`. SDK `client.companies.extract(CompaniesExtractParams(domain="example.com"))`.
2. **Draft.** From the text write one `icp_prompt` sentence, two or three `phrase_match` candidates, a `category`, and the filters that are truly hard (country, business model). A candidate phrase has to distinguish the target, not merely appear on its site: if it would be strange for a company printing that phrase prominently _not_ to be in the ICP, keep it, otherwise drop it. Split hard filters from preferences: if the user would still contact a company without it, it is a preference, so leave it out of the filter and let ranking handle it. Target geography is a filter the user sets, not something to infer from where the seed customers happen to be based.
3. **Count each phrase** on its own. A phrase that counts in the hundreds is a filter; one in the tens is a seed list; one in the hundreds of thousands is noise.
4. **Sample 25.** Show domains and one-line descriptions. Ask the user to mark fits and misses in place.
5. **Correct and save.** Adjust from the marks, re-sample once, then save the query with a name and tags. Every later flow starts from that id.

### Flow 7: signal-qualified list

"Find X that run Shopify", "that are hiring SDRs", "that publish case studies", "that have a pricing page".

1. **Base list.** Flow 1 steps 1 and 2, or an existing saved query.
2. **Deterministic signals first.** Technology in use: `tech_stack` on discover, or MCP `vendor-and-technology-data`, CLI `discolike company vendors example.com --format json`, SDK `client.companies.vendors(CompaniesVendorsParams(domain=..., match="client"))`. Growth and footprint: `growth-metrics`, `digital-footprint-score`. Homepage wording: `phrase_match`. No model call for anything a filter answers.
3. **Research for the rest.** A question no filter or signal answers ("do they publish hospital case studies?") is a research job, which the MCP tools do not run; DiscoLike's web app and REST API do.
4. **Route.** `yes` rows go to the campaign with the evidence quote carried as a merge field, so the first line of outreach cites the fact. Everything else goes to a separate list or waits for the next signal.
5. **Contacts** for the qualified set only, Flow 1 steps 4 to 7.

### Flow 8: technology and infrastructure targeting

"Companies running Shopify and Klaviyo", "who uses SendGrid", "who advertises on Meta", "what does acme.com run".

1. **Which direction.** Find companies that use a vendor: `tech_stack` on discover or count, CLI `--tech-stack shopify.com`, SDK `DiscoverParams(tech_stack=[...])`, MCP `discover-similar-companies`. Find what one company uses: MCP `vendor-and-technology-data` with `match=client`, CLI `discolike company vendors acme.com --format json`, SDK `client.companies.vendors(CompaniesVendorsParams(domain="acme.com", match="client"))`. `match=vendor` on the same call lists a vendor's clients.
2. **Vendors are domains.** `shopify.com`, `hubspot.com`, `klaviyo.com`, up to 20 per search. Count each vendor alone first; anything under about 1,000 companies worldwide is too thin to build a segment on.
3. **AND, not OR.** Multiple `tech_stack` values are OR by default. Prefix with `+` to require all: `+shopify.com +klaviyo.com +gorgias.com`. Same rule for `phrase_match`.
4. **Fragmented stacks.** Consolidation pitches want companies on point tools with no suite. AND the point tools, then `negate_tech_stack` the suites that would replace them (`salesforce.com`, `hubspot.com`).
5. **Advertisers.** Meta: `facebook.net` (pixel), `facebook.com`, `meta.com`, `instagram.com`. Google Ads, tight: `doubleclick.net`, `googlesyndication.com`, `googleadservices.com`. Google, broad: `googletagmanager.com` and analytics domains, which most advertisers have and many non-advertisers too. Pixel present is binary; spend or volume is a research question (Flow 7 step 3).
6. **Email sending stack.** Filter on the ESP or sequencer as `tech_stack` (`sendgrid.com`, `instantly.ai`, `smartlead.ai`, `mailgun.com`, `marketo.com`). The discover response carries `mx_provider` inline (`google.com`, `microsoft.com`, `no_mx` means the domain does not receive mail, a parked-domain filter). Sending-domain portfolio size: reverse redirects, MCP `domain-redirects` with `match=linked`, CLI `discolike company redirects acme.com --match linked`, SDK `client.companies.redirects(CompaniesRedirectsParams(domain=..., match="linked"))`, or bulk `append` with dataset `redirects` for `redirect_count`. Newest rotated domains can lag a crawl cycle.
7. **Detection limits.** Signals come from scripts, meta tags, tag-manager containers, and certificates on the public site. A tool with no web-facing footprint (a CRM used only internally) will not show; an empty result means no public signal, not no tool. Vendors that provision customers on subdomains (`client.vendor.com`) are not mapped automatically; pull the vendor's certificate set, extract the client names, and run them through Flow 3 bulk match. There is no Google Business Profile filter; that is a research question (Flow 7 step 3).

### Flow 9: rank or filter a list the user already has

"Score these 3,000 accounts against our ICP", "which of our customers run HubSpot", "run research on this list".

1. **Load the list.** A saved domain list serves as inclusion scope as well as exclusion; the upload path is the same. MCP `save-exclusion-list`; CLI `discolike queries create-exclusion-list --name "crm-accounts" --domains-file crm.csv`; SDK `client.queries.create_exclusion_list(CreateExclusionListRequest(query_name="crm-accounts", domains=[...]))`. Minimum 20 domains. Names first? Flow 3.
2. **Rank it.** Discover with `inclusion_query_id` set to that list plus an `icp_prompt` or seed domains; the response is the user's own companies ordered by similarity, with firmographics. Available from Starter. CLI `--inclusion-query-id <id>`; SDK `DiscoverParams(inclusion_query_id=[...], icp_prompt=...)`.
3. **Bucket it.** Same call with `tech_stack` instead of a prompt returns only the companies on that vendor. Repeat per vendor to split the list.
4. **Check and staff it.** Verify fit with Flow 1 step 3 and find people with a contacts run on the list (Flow 1 steps 4 to 7, `run.companies` set to a domain list, up to 10,000 domains per run). Questions no filter answers follow Flow 7 step 3.
5. **Explain the gaps.** Domains that return no profile are not lost: `append` with dataset `domain_status` says why (non-business, parked, dead, redirect, no certificate).

### Flow 10: large company and contacts lists

Calibrate the company query first (Flow 5). Page company discovery with exclusion lists so pages do not overlap; 10,000 is the per-call company limit. Count the market before committing to a large paid company pull.

For contacts, use the same validated delivery flow at every size (Flow 1 steps 4 to 7). Split company domains into batches of at most 10,000 and set `run.max_companies`, `run.per_company` and an agreed `run.email_cap` for each batch. Poll and page each run by company. Export rows as they arrive and record the run ID and progress cursor so recovery reads the existing run. Use `run.create_key` when retrying the same start request. Starting a new run delivers and bills contacts again, even for companies already processed. Do not estimate yield or throughput from the maximum per company; report actual validated contacts and companies covered.

### Flow 11: agentic prospecting run

Use this for a chat-driven brief instead of a hand-tuned discovery call. Prospecting delivers only Validated and Validated (catch-all resolved) contacts, with validated work emails, using the same automatic contacts flow as Flow 1. Do not re-verify them. Contacts search is free; each delivery costs 5 records per validated contact with a $10 per 1,000 contacts floor, plus 1 record per company delivering at least one. Repeated deliveries are billed; companies with none are free.

1. **Start.** MCP `start-prospecting` takes `brief` and `idempotency_key`. Put the description in `brief.brief` (10 to 4,000 characters), the company target in `brief.target_companies` (1 to 10,000, MCP default 100), and the maximum contacts per company in `brief.contacts_per_company`. Agree the delivery scope and costs before starting. Reuse the key only when retrying the same start request. MCP auto-approves its plan and runs the contacts work automatically.
2. **Select companies.** `brief.domains` means prospect exactly those domains; `brief.company_names` supplies company names. For lookalikes of existing customers, use `brief.customer_domains` instead, which cannot be combined with either of those inputs. `brief.exclude_domains` excludes companies. Describe the desired people in the brief.
3. **Poll.** Call `get-prospecting-run` with `run_id` every 5 seconds. Use `offset` and `limit` (1 to 100, default 100) to page partial results, and `events_after` to read later progress events. If it returns `needs_input` with a `question`, relay the question to the user. Send their answer through `answer-prospecting` with `run_id`, the current `question_seq`, their `text`, and a fresh `idempotency_key`; reuse that key only for a retry of the same answer. Never invent an answer. Keep polling until `completed`, `failed` or `cancelled`; relay `run_timeout` or `action_uncertain` for user intervention.
4. **Deliver or stop.** `cancel-prospecting` with `run_id` stops further work and retains completed results. Check `status`, `stop_reason`, `error` and actual delivered counts before reporting success. Completed does not necessarily mean the target was reached. Export every ID in `saved_query_ids`, or push each with `push-to-crm` using `query_id` and `provider`; the prospecting run ID is not a contacts run ID. Tell the user when results are partial before a CRM push.
5. **Quota errors.** Reading, answering and cancellation remain available on an active eligible account after quota exhaustion, although an answer that schedules paid work may fail until quota is refilled. Relay the actual error instead of guessing whether it means missing payment setup, plan eligibility or a daily limit.

### Replicating a search from the app

Users paste screenshots of the Discover and Contacts forms and ask for "this exact search". Company search parameters belong inside MCP `discover-similar-companies` `filters`; contacts parameters below belong inside MCP `find-contacts` `run`. The names that differ from the label:

| App field                              | Parameter                                                                                                                                      |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Lookalike Domains                      | `domain`                                                                                                                                       |
| Lookalike Text                         | `icp_text`, never `icp_prompt`: the prompt extracts and applies its own filters, ICP text and seed domains, so the run stops matching the form |
| Homepage Text chips (thumbs up / down) | `phrase_match` / `negate_phrase_match`; a starred chip is `+phrase`                                                                            |
| Industry Group                         | `category`, upper snake case (`ADVERTISING_AND_MARKETING`, `HEALTHCARE`)                                                                       |
| Employees, Revenue                     | `employee_range` `"11,200"`, `revenue_range` `"1000000,50000000"` (strings)                                                                    |
| Digital Footprint slider               | `min_digital_footprint`, `max_digital_footprint`                                                                                               |
| Precision: Domain Consensus            | `consensus`                                                                                                                                    |
| Precision: Relevance                   | `relevance` (`MAX_RELEVANCE`, `BALANCED`, `MAX_COVERAGE`); `variance` is deprecated; old values map onto `relevance`                           |
| Precision: Minimum Similarity          | `min_similarity`                                                                                                                               |
| Skip Profiles with Redirects           | `redirect: false`                                                                                                                              |
| Include Lookalike Query Domains        | `include_search_domains: true`                                                                                                                 |
| Exclude Lead Gen                       | `exclude_leadgen: true`                                                                                                                        |
| Contacts: Companies                    | `run.companies`, using a prompt, domain list or lookalike selection from Flow 1                                                                |
| Contacts: Who                          | `run.people.fit`, default "Senior executives and decision makers"                                                                              |
| Contacts: Max Companies                | `run.max_companies`, companies delivering at least one validated contact                                                                       |
| Contacts: Max Per Company              | `run.per_company`, integer from 1 to 50                                                                                                        |
| Contacts: Spend Cap                    | `run.email_cap`, USD delivery limit on MCP `find-contacts`                                                                                     |

For company search, CLI flags follow the parameter names (`--min-similarity 70`, `--no-redirect`, `--exclude-leadgen`); anything without a flag goes through `--param key=value`, and a whole form goes in as `--params-file form.json` (a JSON object keyed by these parameter names, for company `discover` and `count`). The CLI validates the assembled request against the SDK model before the first billable call; in a script, `DiscoverParams.model_validate(...)` does the same.
