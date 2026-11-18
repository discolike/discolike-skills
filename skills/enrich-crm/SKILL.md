---
name: enrich-crm
description: Use when the user asks to "enrich this CRM export", "append firmographics or tech stack to this CSV", or enrich existing records in a connected CRM. Follow the discolike skill's access and spend rules.
allowed-tools: Read, Grep
---

# Enrich a CRM export

Follow the `discolike` skill's How to work rules first.

The user has a CSV of accounts and wants DiscoLike fields on every row.

1. **Domains, not names.** If the file has websites, use that column, normalized: lowercase, scheme and `www.` stripped, path dropped. If it only has company names, load the `match-company-domains` skill first. Parse and write CSV with a real CSV library; description fields contain commas.
2. **Append.** MCP `append-data`. CLI `discolike append accounts.csv --domain-column website --dataset bizdata --dataset vendors --dataset growth --output enriched.csv`. SDK `client.append(AppendParams(domain_column="website", dataset=["bizdata", "vendors", "growth"]), file=open("accounts.csv", "rb"))`. Datasets: `bizdata` (name, address, phones, industry, employees, revenue range, description), `domain_status`, `redirects`, `growth`, `vendors`. Up to 10,000 rows per request. Rows seen in the last 24 hours on the free plan or 30 days on subscriptions are not billed again.
3. **Single domains** when it is a handful: MCP `business-profile`, `vendor-and-technology-data`, `growth-metrics`, `digital-footprint-score`. CLI `discolike company data stripe.com --format json`. SDK `client.companies.data(CompaniesDataParams(domain="stripe.com"))`, plus `.vendors`, `.growth`, `.score`, `.redirects`, `.subsidiaries`.
4. **Connected CRM contacts.** MCP `crm-import-companies` with `provider` queues an import; its domain lists appear through `list-saved-queries`. Use the imported domains in `find-contacts`, poll `get-contacts-run`, then `push-to-crm` with the contacts `run_id`, `provider` and `mode="enrich"` to update existing records. For missing company domains, `crm-match-companies` produces a saved match query; `crm-writeback-domains` takes that `query_id` and `provider`.
