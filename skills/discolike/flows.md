# DiscoLike flows

Read the flow you need, not the file. Each step lists the MCP tool, the CLI command, and the SDK call. Load `troubleshooting.md` when results look wrong and `discogen.md` before any research prompt.

Each flow lists the MCP tool, the CLI command, and the SDK call. Async steps return a job; wait on it before the next step. Save intermediate result sets as queries so later steps reference an id instead of re-sending domains.

Before any flow: check spend with MCP `account-status`, CLI `discolike account usage`, SDK `client.account.usage()`, and report it. Before any paid pull larger than a sample (roughly 100 records), state the estimated cost from the count and the plan's per-1,000 rate and get a yes. Write raw results to disk as JSON or CSV; chat output truncates.

### Flow 1: discover, verify, contacts, ContaGen

Build a target list, confirm fit, get named people, then fill the gaps with live web research.

1. **Size it.** MCP `count-matching-domains`. CLI `discolike count --phrase-match "..." --country US`. SDK `client.count(CountParams(...))`. Free.
2. **Discover.** MCP `discover-similar-companies`. CLI `discolike discover --icp-prompt "..." --domain seed.com --country US --max-records 500 --format json`. SDK `client.discover(DiscoverParams(icp_prompt=..., domain=[...], max_records=500))`. Start at 100 to 500, inspect, then scale. Do not set an employee minimum unless asked; small-company headcount data is thin and rarely what disqualifies. After every pull, add its domains to an exclusion list: MCP `save-exclusion-list`, CLI `discolike queries create-exclusion-list --name "tam-round-1" --domain a.com --domain b.com --tag tam`, SDK `client.queries.create_exclusion_list(CreateExclusionListRequest(query_name="tam-round-1", domains=[...], tags=["tam"]))`. Pass that list's id as `exclusion_query_id` on the next pull so rounds never overlap. Save the search itself with `save-mcp-query` or `queries save-results` only when you want to rerun it later.
3. **Verify fit.** MCP `validate-icp-fit`. CLI `discolike validate-icp --icp "..." --domain a.com --domain b.com --wait --format json` (or `--file domains.csv`). SDK `job = client.validate_icp(ValidateIcpRequest(icp_text=..., domains=[...], web_search=True)); job.wait()`. Returns `Fit` yes/no, `Confidence` high/medium/low, and `Reasoning` per domain. Keep yes at high confidence, review yes at medium or low and no at low, drop no at high. A 60 to 70 percent yes rate on a first pull is normal, not a failed search. Uses the account's LLM provider key.
4. **Contacts.** MCP `search-contacts`. CLI `discolike contacts search --domain a.com --domain b.com --seniority executive --department Sales --has-email --format json`. SDK `client.contacts.search(ContactsSearchParams(domain=[...], seniority=["executive"], department=["Sales"], has_email=True, max_records=200))`. Billed per new contact record. `--icp-prompt` on contacts search derives persona filters from a sentence.
5. **ContaGen for the rest.** For domains where step 4 returned nobody, MCP `generate-contacts`. CLI `discolike contacts generate --icp-text "VP Sales or Head of Revenue" --domain a.com --domain b.com --wait --format json`. SDK `job = client.contacts.generate(ContactGenerateRequest(icp_text=..., domains=[...], max_contacts_per_domain=3)); job.wait()`. Runs live web search per company on the user's own LLM and search provider keys. No platform billing. Output is names, titles when visible, and LinkedIn URLs; `email` and `title` are `null` unless the address or role appeared verbatim in a search snippet, because the prompt never builds emails from patterns. Treat every row as a candidate.
6. **Emails for ContaGen names.** Turn those names into proven addresses with the email finder: MCP `find-emails` then `get-email-results`. CLI `discolike email find-batch --contacts-file names.csv --wait --format json`, where `names.csv` has the columns `first_name,last_name,domain` (up to 500 rows per batch). SDK `client.email.find_batch(FindEmailBatchRequest(...))`. Only addresses that come back `found` bill as records; `not_found`, catch-all, and pattern guesses are free. Email verification of an address the user already has is not on the API; it is the in-app Verify button only.
7. **Deliver.** CSV, or push to the CRM with MCP `push-to-crm` (HubSpot, Salesforce, Pipedrive).

### Flow 2: enrich a CRM export

The user has a CSV of accounts and wants DiscoLike fields on every row.

1. **Domains, not names.** If the file has websites, use that column, normalized: lowercase, scheme and `www.` stripped, path dropped. If it only has company names, run Flow 3 first. Parse and write CSV with a real CSV library; description fields contain commas.
2. **Append.** MCP `append-data`. CLI `discolike append accounts.csv --domain-column website --dataset bizdata --dataset vendors --dataset growth --output enriched.csv`. SDK `client.append(AppendParams(domain_column="website", dataset=["bizdata", "vendors", "growth"]), file=open("accounts.csv", "rb"))`. Datasets: `bizdata` (name, address, phones, industry, employees, revenue range, description), `domain_status`, `redirects`, `growth`, `vendors`. Up to 10,000 rows per request. Billed per new company record; rows seen in the last 90 days are free.
3. **Single domains** when it is a handful: MCP `business-profile`, `vendor-and-technology-data`, `growth-metrics`, `digital-footprint-score`. CLI `discolike company data stripe.com --format json`. SDK `client.companies.data(CompaniesDataParams(domain="stripe.com"))`, plus `.vendors`, `.growth`, `.score`, `.redirects`, `.subsidiaries`.
4. **Write back.** MCP `crm-enrich-contacts` and `crm-writeback-domains` update records in a connected CRM directly.

### Flow 3: match company names to domains

The user has names, maybe city or phone, and no websites.

1. **One at a time.** MCP `match-company-to-domain`. CLI `discolike match --name "Acme Robotics" --city Austin --state TX --country US --format json`. SDK `client.match.company(MatchCompanyParams(name="Acme Robotics", city="Austin", state="TX", country="US"))`. Returns ranked candidates with confidence; nothing below 50 is returned. Raise `min_match_confidence` to tighten. Name matching costs nothing.
2. **In bulk.** MCP `bulk-match-company-to-domain`. CLI `discolike match --file companies.csv --name-column company --city-column city --country-column country --wait --format json`. SDK `job = client.match.bulk(MatchBulkParams(name_column="company", city_column="city", country_column="country"), file=open("companies.csv", "rb")); job.wait()`. Rows the backend could not process carry `match_error: search_failed`, which is not the same as no match.
3. **Then enrich** with Flow 2, or suppress against the CRM with MCP `crm-match-companies`.

### Flow 4: segment a client list into ICPs

The user has their customers and wants to know what kinds of companies they actually sell to, then find more of each kind.

1. **Segment.** MCP `segment-domains`. CLI `discolike segment --file customers.csv --domain-column website --max-segments 6 --wait --format json`. SDK `job = client.segment_file(SegmentFileParams(domain_column="website", max_segments=6), file=open("customers.csv", "rb")); job.wait()`, or `client.segment(SegmentParams(domains="a.com,b.com,...", max_segments=6))` for an inline list. Output: clusters with an auto-written description and a probability per domain.
2. **Read the clusters.** Present each segment's description and size. Ask which segments matter; the biggest is not always the best.
3. **Lookalikes per segment.** For a chosen segment, run Flow 1 step 2 with that segment's top domains as `domain` seeds (up to 10) and its description as `icp_prompt`. Exclude the existing customers with an exclusion list built from the customer file (MCP `save-exclusion-list`, CLI `discolike queries create-exclusion-list`, SDK `client.queries.create_exclusion_list`) passed as `exclusion_query_id`; `exclude_domain` is for a handful of domains, capped at 100.
4. **Validate and hand off** with Flow 1 steps 3 to 7. Name each segment as a campaign lane and write the label to the CRM with MCP `crm-writeback-segments`, so every account carries exactly one lane and sequences stay separate.

### Flow 5: market map to N

The user wants the whole addressable market, thousands of accounts, not a sample.

1. **Anchor.** Count with the structural filters alone (country, size, category). That number is the ceiling; if it is far from the user's own estimate, the filters are wrong, fix them before spending.
2. **Calibrate on 50.** One inclusion-only pull, `max_records=50`, seeds plus `icp_prompt`, `variance="MEDIUM"`, no negations. Validate fit. Then change one lever per round: first exclude the high-similarity wrong-category anchors, then add two or three confirmed fits as seeds, and only then add a phrase. Never negate a phrase the real targets also use. Excluding a domain: MCP `discover-similar-companies` with `negate_domain` (shapes the ranking), CLI `--param negate_domain=a.com,b.com`, SDK `exclude_domain` (hard filter only). Re-run at 200 and read ranks 1 to 10, 90 to 100, and 190 to 200; quality decays with rank, and the tail tells you where to stop.
3. **Round.** Pull 500 to 1,000. Add every domain to the exclusion list. Validate. Record fit rate.
4. **Next round.** Same query, `exclusion_query_id` pointing at the exclusion list, two new seeds from the last round's best fits, `max_records` up to 1,000. Repeat. One list per market map, grown each round, is simpler than one list per round.
5. **Stop.** When a round's fit rate drops under about 30 percent, or net-new fits fall under 5 percent of the pull, the market is mapped. Push past that only with a different `icp_prompt` (an adjacent segment), not a bigger `max_records`.
6. **Deliver.** Union the rounds, dedupe on bare domain, keep the round number and similarity on each row.

A 70/20/10 split works for a portfolio: 70 percent of records from the proven prompt, 20 from an adjacent one, 10 from an experimental one, all sharing the one exclusion list.

### Flow 6: ICP from a website

New account, no ICP written down, or "set up my ICP".

1. **Read the source.** MCP `extract-website-text` on the user's own domain, or on their best customer's. CLI `discolike extract https://example.com --format json`. SDK `client.companies.extract(CompaniesExtractParams(domain="example.com"))`.
2. **Draft.** From the text write one `icp_prompt` sentence, two or three `phrase_match` candidates that a target's homepage would say, a `category`, and the filters that are truly hard (country, business model). Split hard filters from preferences: if the user would still contact a company without it, it is a preference, so leave it out of the filter and let ranking handle it.
3. **Count each phrase** on its own. A phrase that counts in the hundreds is a filter; one in the tens is a seed list; one in the hundreds of thousands is noise.
4. **Sample 25.** Show domains and one-line descriptions. Ask the user to mark fits and misses in place.
5. **Correct and save.** Adjust from the marks, re-sample once, then save the query with a name and tags. Every later flow starts from that id.

### Flow 7: signal-qualified list

"Find X that run Shopify", "that are hiring SDRs", "that publish case studies", "that have a pricing page".

1. **Base list.** Flow 1 steps 1 and 2, or an existing saved query.
2. **Deterministic signals first.** Technology in use: `tech_stack` on discover, or MCP `vendor-and-technology-data`, CLI `discolike company vendors example.com --format json`, SDK `client.companies.vendors(CompaniesVendorsParams(domain=..., match="client"))`. Growth and footprint: `growth-metrics`, `digital-footprint-score`. Homepage wording: `phrase_match`. Recently hired leadership: contacts search with `jobstart_date`. No model call for anything a filter answers.
3. **DiscoGen for the rest.** One call for the whole list, one question, structured answer: `{"answer": "yes|no|unknown", "evidence": "<quote from the page>", "confidence": 0-1}`. `web_search=true` only when the answer is not on the site (job posts, funding). Drop `unknown`; do not turn it into `no`.
4. **Route.** `yes` rows go to the campaign with the evidence quote carried as a merge field, so the first line of outreach cites the fact. Everything else goes to a separate list or waits for the next signal.
5. **Contacts** for the qualified set only, Flow 1 steps 4 to 6.

### Flow 8: technology and infrastructure targeting

"Companies running Shopify and Klaviyo", "who uses SendGrid", "who advertises on Meta", "what does acme.com run".

1. **Which direction.** Find companies that use a vendor: `tech_stack` on discover or count, CLI `--tech-stack shopify.com`, SDK `DiscoverParams(tech_stack=[...])`, MCP `discover-similar-companies`. Find what one company uses: MCP `vendor-and-technology-data` with `match=client`, CLI `discolike company vendors acme.com --format json`, SDK `client.companies.vendors(CompaniesVendorsParams(domain="acme.com", match="client"))`. `match=vendor` on the same call lists a vendor's clients.
2. **Vendors are domains.** `shopify.com`, `hubspot.com`, `klaviyo.com`, up to 20 per search. Count each vendor alone first; anything under about 1,000 companies worldwide is too thin to build a segment on.
3. **AND, not OR.** Multiple `tech_stack` values are OR by default. Prefix with `+` to require all: `+shopify.com +klaviyo.com +gorgias.com`. Same rule for `phrase_match`.
4. **Fragmented stacks.** Consolidation pitches want companies on point tools with no suite. AND the point tools, then `negate_tech_stack` the suites that would replace them (`salesforce.com`, `hubspot.com`).
5. **Advertisers.** Meta: `facebook.net` (pixel), `facebook.com`, `meta.com`, `instagram.com`. Google Ads, tight: `doubleclick.net`, `googlesyndication.com`, `googleadservices.com`. Google, broad: `googletagmanager.com` and analytics domains, which most advertisers have and many non-advertisers too. Pixel present is binary; spend or volume is a DiscoGen estimate, see below.
6. **Email sending stack.** Filter on the ESP or sequencer as `tech_stack` (`sendgrid.com`, `instantly.ai`, `smartlead.ai`, `mailgun.com`, `marketo.com`). The discover response carries `mx_provider` inline (`google.com`, `microsoft.com`, `no_mx` means the domain does not receive mail, a parked-domain filter). Sending-domain portfolio size: reverse redirects, MCP `domain-redirects` with `match=linked`, CLI `discolike company redirects acme.com --match linked`, SDK `client.companies.redirects(CompaniesRedirectsParams(domain=..., match="linked"))`, or bulk `append` with dataset `redirects` for `redirect_count`. Newest rotated domains can lag a crawl cycle.
7. **Detection limits.** Signals come from scripts, meta tags, tag-manager containers, and certificates on the public site. A tool with no web-facing footprint (a CRM used only internally) will not show; an empty result means no public signal, not no tool. Vendors that provision customers on subdomains (`client.vendor.com`) are not mapped automatically; pull the vendor's certificate set, extract the client names, and run them through Flow 3 bulk match. There is no Google Business Profile filter; that is a DiscoGen question.

### Flow 9: rank or filter a list the user already has

"Score these 3,000 accounts against our ICP", "which of our customers run HubSpot", "run research on this list".

1. **Load the list.** A saved domain list serves as inclusion scope as well as exclusion; the upload path is the same. MCP `save-exclusion-list`; CLI `discolike queries create-exclusion-list --name "crm-accounts" --domain a.com --domain b.com`; SDK `client.queries.create_exclusion_list(CreateExclusionListRequest(query_name="crm-accounts", domains=[...]))`. Minimum 20 domains. Names first? Flow 3.
2. **Rank it.** Discover with `inclusion_query_id` set to that list plus an `icp_prompt` or seed domains; the response is the user's own companies ordered by similarity, with firmographics. Available from Starter. CLI `--inclusion-query-id <id>`; SDK `DiscoverParams(inclusion_query_id=[...], icp_prompt=...)`.
3. **Bucket it.** Same call with `tech_stack` instead of a prompt returns only the companies on that vendor. Repeat per vendor to split the list.
4. **Research it.** Point DiscoGen, validate-icp, or ContaGen at the list directly, up to 10,000 domains per run. Rows the user pulled in the last 90 days are cached, so DiscoLike-side cost is the submit fee.
5. **Explain the gaps.** Domains that return no profile are not lost: `append` with dataset `domain_status` says why (non-business, parked, dead, redirect, no certificate).

### Flow 10: bulk pull to six figures

"Pull every company that matches and 100,000+ emails into one sheet." Same mechanics as Flow 5 without the per-round fit review; the user has already validated the search in the app and wants volume.

1. **Anchor.** `count` with the app's filters. That number is the ceiling on companies; everything below is arithmetic. Tell the user the ceiling before anything is billed.
2. **Companies, 10,000 per page.** 10,000 is a page size, not a total. Each page is the same `discover` call with `max_records=10000` and every earlier page excluded through `exclusion_query_id`. After each page, add its domains to one exclusion list (MCP `save-exclusion-list`, SDK `client.queries.create_exclusion_list(...)`) and rerun. Exclusion capacity is 250,000 domains per account, so one continuous run reaches about 260,000 companies; past that, split the search by state or employee band with a fresh list each. `max_records` has a floor of 20, so the last short page still asks for at least 20.
3. **Contacts, by domain slice, no ceiling.** Contacts search ignores `offset` when `results_by_company` is set, so page the contacts stage by slicing the domain list, not by offset: with `results_by_company=5`, send 2,000 domains per call (`max_records = domains x per_company`, capped at 10,000). Every domain lands in exactly one call, no overlap, no dropped companies. Persona text goes in `icp_text`, profile exclusions in `negate_summary`, and `has_email=True` keeps only rows with an address.
4. **Size before you pay.** `contacts count` per domain slice is free and tells the user how many people match before the paid pull. Expect the real yield to be well under the per-company cap: on a US marketing-agency list with a decision-maker persona and accountant exclusions, 5 per company returned about 2.5 emails per company (49 rows across 20 companies, 11 of them with anyone at all). Size the company pull from that ratio, not from the cap.
5. **Write as you go, resume from disk.** Append every page and every slice to the CSV as it lands, and record which slices finished. A rerun after a crash reads the CSV and skips what is there. Billing is net-new only with a 90-day cache, so a resume never charges twice for the same company or contact.
6. **Rate.** Discover and contacts are 10 calls a minute on Pro, so a slice of 2,000 domains at 5 per company is roughly 100,000 contacts an hour. Run one call at a time; parallel calls only trade rate-limit retries for speed.
7. **Gaps.** Companies with no directory contacts go through ContaGen and the email finder, Flow 1 steps 5 and 6, 10,000 domains per ContaGen call, 500 names per email batch.

Use the SDK for this flow. The CLI takes domains only as repeated `--domain` flags, so a 2,000-domain slice or a 10,000-domain exclusion list does not fit on a command line; write a short script with `DiscoverParams`, `ContactFilters`, and `CreateExclusionListRequest` and let the agent run it.

### Replicating a search from the app

Users paste screenshots of the Discover and Contacts forms and ask for "this exact search" over the API. Every field maps to a parameter; the names that differ from the label:

| App field                              | Parameter                                                                   |
| -------------------------------------- | --------------------------------------------------------------------------- |
| Lookalike Domains                      | `domain`                                                                    |
| Lookalike Text                         | `icp_text`                                                                  |
| Homepage Text chips (thumbs up / down) | `phrase_match` / `negate_phrase_match`; a starred chip is `+phrase`         |
| Industry Group                         | `category`, upper snake case (`ADVERTISING_AND_MARKETING`, `HEALTHCARE`)    |
| Employees, Revenue                     | `employee_range` `"11,200"`, `revenue_range` `"1000000,50000000"` (strings) |
| Digital Footprint slider               | `min_digital_footprint`, `max_digital_footprint`                            |
| Precision: Domain Consensus            | `consensus`                                                                 |
| Precision: Industry Variance           | `variance` (`LOW`, `MID_LOW`, `MEDIUM`, `MID_HIGH`, `HIGH`, `UNRESTRICTED`) |
| Precision: Minimum Similarity          | `min_similarity`                                                            |
| Skip Profiles with Redirects           | `redirect: false`                                                           |
| Include Lookalike Query Domains        | `include_search_domains: true`                                              |
| Exclude Lead Gen                       | `exclude_leadgen: true`                                                     |
| Contacts: Persona Lookalike Text       | `icp_text` on the contacts call                                             |
| Contacts: Profile Phrase Match (red)   | `negate_summary`, one string, chips joined with commas                      |
| Contacts: Results Per Company          | `results_by_company`                                                        |
| Contacts: Max Companies                | `max_companies` (not with `max_records`)                                    |
| Contacts: Source = Results Table       | pass the company run's domains as `domain`                                  |

CLI flags follow the parameter names (`--min-similarity 70`, `--no-redirect`, `--exclude-leadgen`); anything without a flag goes through `--param key=value`. Validate the assembled request locally with the SDK model (`DiscoverParams.model_validate(...)`) before the first billable call.
