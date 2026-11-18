---
name: map-corporate-family
description: Use when the user asks "find all subsidiaries of X", "who is the parent company of X", "is this company public or what are its ticker or SEC links", or "which domains redirect to acme.com". Follow the `discolike` skill's access and spend rules.
allowed-tools: Read, Grep
---

# Map a corporate family

Follow the `discolike` skill's How to work rules first.

1. **Resolve the target.** Start with a confirmed company domain, or use the `match-company-domains` skill if you have a name only. Check the account's `subsidiaries_data`, `linkage`, and `domain_redirects` features for the lookups you need. Each tool takes one domain in `filters.domain`, optional `fields`, and `format` (`rows` by default or `columnar`).
2. **Look up parent and child domains.** MCP `subsidiaries-and-parent-companies` takes `filters.match`. Use `parent` (default) for children of the input domain, `child` for its parent, and `recursive` to expand the known family around the input. The `source` and `linked` modes match those respective roles in the underlying linkage records. Read `count` and `subsidiaries`, which includes `parent_domain`, `child_domain`, `source_domain`, `linked_domain`, their FQDNs and certificate-history scores, and `record_date`. Treat these as domain relationships inferred from certificate data. The lookup is capped at 10,000 rows.
   - CLI `discolike company subsidiaries example.com --match recursive --format json`.
   - SDK `client.companies.subsidiaries(CompaniesSubsidiariesParams(domain="example.com", match="recursive"))`.
3. **Check domains with shared contact details.** MCP `public-company-links` takes `filters.source` of `email`, `social`, or `phone`. Read `count` and `links` with `domain`, `linked_domain`, `link_values`, and `record_date`. These are links based on shared public contact information. For public listing status, tickers, or SEC links, explain that this tool has no fields for those facts.
   - CLI `discolike company public-links example.com --source social --format json`.
   - SDK `client.companies.public_links(CompaniesPublicLinksParams(domain="example.com", source="social"))`.
4. **Resolve redirect direction.** MCP `domain-redirects` takes `filters.match` of `source` (default, redirects from the domain) or `linked` (redirects to it). Read `count` and `redirects` with `source_domain`, `source_fqdn`, `linked_domain`, `linked_fqdn`, and `record_date`.
   - CLI `discolike company redirects example.com --match linked --format json`.
   - SDK `client.companies.redirects(CompaniesRedirectsParams(domain="example.com", match="linked"))`.
5. **Expand the account before finding contacts.** Present the parent and children and flag shared-contact and redirect evidence as such. Review the candidate domains with the user, deduplicate the approved list, and pass it to the `find-validated-contacts` skill.
