---
name: discolike-replicate-app-search
description: Use when the user shares a screenshot or settings from the DiscoLike Discover or Contacts form and asks to run "this exact search" through the MCP server, API, or CLI. Follow the discolike skill's access and spend rules.
allowed-tools: Read, Grep
---

# Replicate a search from the app

Follow the `discolike` skill's How to work rules first.

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
| Contacts: Companies                    | `run.companies`, using a prompt, domain list or lookalike selection from the `discolike-contacts` skill                                        |
| Contacts: Who                          | `run.people.fit`, default "Senior executives and decision makers"                                                                              |
| Contacts: Max Companies                | `run.max_companies`, companies delivering at least one validated contact                                                                       |
| Contacts: Max Per Company              | `run.per_company`, integer from 1 to 50                                                                                                        |
| Contacts: Spend Cap                    | `run.email_cap`, USD delivery limit on MCP `find-contacts`                                                                                     |

For company search, CLI flags follow the parameter names (`--min-similarity 70`, `--no-redirect`, `--exclude-leadgen`); anything without a flag goes through `--param key=value`, and a whole form goes in as `--params-file form.json` (a JSON object keyed by these parameter names, for company `discover` and `count`). The CLI validates the assembled request against the SDK model before the first billable call; in a script, `DiscoverParams.model_validate(...)` does the same.
