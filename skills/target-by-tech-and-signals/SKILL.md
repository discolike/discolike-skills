---
name: target-by-tech-and-signals
description: Use when the user asks to "find X that run Shopify", "find companies hiring SDRs", "find companies that publish case studies", "who advertises on Meta", "who uses SendGrid", or "what does acme.com run". Follow the discolike skill's access and spend rules.
allowed-tools: Read, Grep
---

# Qualify companies by signals and technology

Follow the `discolike` skill's How to work rules first.

## Signal-qualified list

"Find X that run Shopify", "that are hiring SDRs", "that publish case studies", "that have a pricing page".

1. **Base list.** Follow the `discover-lookalike-companies` skill, or an existing saved query.
2. **Deterministic signals first.** Technology in use: `tech_stack` on discover, or MCP `vendor-and-technology-data`, CLI `discolike company vendors example.com --format json`, SDK `client.companies.vendors(CompaniesVendorsParams(domain=..., match="client"))`. Growth and footprint: `growth-metrics`, `digital-footprint-score`. Homepage wording: `phrase_match`. No model call for anything a filter answers.
3. **Research for the rest.** A question no filter or signal answers ("do they publish hospital case studies?") is a research job, which the MCP tools do not run; DiscoLike's web app and REST API do.
4. **Route.** `yes` rows go to the campaign with the evidence quote carried as a merge field, so the first line of outreach cites the fact. Everything else goes to a separate list or waits for the next signal.
5. **Contacts** for the qualified set only, using the `find-validated-contacts` skill starting at Start contacts.

## Technology and infrastructure targeting

"Companies running Shopify and Klaviyo", "who uses SendGrid", "who advertises on Meta", "what does acme.com run".

1. **Which direction.** Find companies that use a vendor: `tech_stack` on discover or count, CLI `--tech-stack shopify.com`, SDK `DiscoverParams(tech_stack=[...])`, MCP `discover-similar-companies`. Find what one company uses: MCP `vendor-and-technology-data` with `match=client`, CLI `discolike company vendors acme.com --format json`, SDK `client.companies.vendors(CompaniesVendorsParams(domain="acme.com", match="client"))`. `match=vendor` on the same call lists a vendor's clients.
2. **Vendors are domains.** `shopify.com`, `hubspot.com`, `klaviyo.com`, up to 20 per search. Count each vendor alone first; anything under about 1,000 companies worldwide is too thin to build a segment on.
3. **AND, not OR.** Multiple `tech_stack` values are OR by default. Prefix with `+` to require all: `+shopify.com +klaviyo.com +gorgias.com`. Same rule for `phrase_match`.
4. **Fragmented stacks.** Consolidation pitches want companies on point tools with no suite. AND the point tools, then `negate_tech_stack` the suites that would replace them (`salesforce.com`, `hubspot.com`).
5. **Advertisers.** Meta: `facebook.net` (pixel), `facebook.com`, `meta.com`, `instagram.com`. Google Ads, tight: `doubleclick.net`, `googlesyndication.com`, `googleadservices.com`. Google, broad: `googletagmanager.com` and analytics domains, which most advertisers have and many non-advertisers too. Pixel present is binary; spend or volume is a research question (see Research for the rest above).
6. **Email sending stack.** Filter on the ESP or sequencer as `tech_stack` (`sendgrid.com`, `instantly.ai`, `smartlead.ai`, `mailgun.com`, `marketo.com`). The discover response carries `mx_provider` inline (`google.com`, `microsoft.com`, `no_mx` means the domain does not receive mail, a parked-domain filter). Sending-domain portfolio size: reverse redirects, MCP `domain-redirects` with `match=linked`, CLI `discolike company redirects acme.com --match linked`, SDK `client.companies.redirects(CompaniesRedirectsParams(domain=..., match="linked"))`, or bulk `append` with dataset `redirects` for `redirect_count`. Newest rotated domains can lag a crawl cycle.
7. **Detection limits.** Signals come from scripts, meta tags, tag-manager containers, and certificates on the public site. A tool with no web-facing footprint (a CRM used only internally) will not show; an empty result means no public signal, not no tool. Vendors that provision customers on subdomains (`client.vendor.com`) are not mapped automatically; pull the vendor's certificate set, extract the client names, and run them through the bulk match step in the `match-company-domains` skill. There is no Google Business Profile filter; that is a research question (see Research for the rest above).
