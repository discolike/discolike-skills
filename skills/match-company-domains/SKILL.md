---
name: match-company-domains
description: Use when the user asks to "match these company names to websites", "find the domain for Acme Robotics in Austin", or fill in missing company domains in bulk. Follow the discolike skill's access and spend rules.
allowed-tools: Read, Grep
---

# Match company names to domains

Follow the `discolike` skill's How to work rules first.

The user has names, maybe city or phone, and no websites.

1. **One at a time.** MCP `match-company-to-domain`. CLI `discolike match --name "Acme Robotics" --city Austin --state TX --country US --format json`. SDK `client.match.company(MatchCompanyParams(name="Acme Robotics", city="Austin", state="TX", country="US"))`. Returns ranked candidates with confidence; nothing below 50 is returned. Raise `min_match_confidence` to tighten.
2. **In bulk.** MCP `bulk-match-company-to-domain`. CLI `discolike match --file companies.csv --name-column company --city-column city --country-column country --wait --format json`. SDK `job = client.match.bulk(MatchBulkParams(name_column="company", city_column="city", country_column="country"), file=open("companies.csv", "rb")); job.wait()`. Rows the backend could not process carry `match_error: search_failed`, which is not the same as no match.
3. **Then enrich** with the `enrich-crm` skill, or match domainless connected CRM companies with MCP `crm-match-companies`.
