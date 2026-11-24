# Alternative and complementary sources for daily Indian mandi prices (fallback for data.gov.in Agmarknet resource)

Research date: 2026-11-24. Many official pages (data.gov.in, india.gov.in) returned HTTP 403 to automated fetch, so some facts rest on search-result snippets and are flagged. Nothing here was tested against live endpoints.

## What official alternatives exist (agmarknet.gov.in, data.gov.in bulk, e-NAM, state portals, DMI/UPAg)?

### Takeaway
Every official daily mandi price feed I found traces back to Agmarknet; no independent official machine-readable e-NAM or state feed was found. Agmarknet 2.0 (relaunched Nov 2025) and UPAg are human-facing dashboards with no documented API, so official "alternatives" are the same data through different front ends.

### Cited Findings
- The data.gov.in daily mandi dataset is generated through the AGMARKNET portal and gives state, district, market, commodity, variety, grade, arrival_date, min/max/modal price — [data.gov.in resource](https://data.gov.in/resource/current-daily-price-various-commodities-various-markets-mandi) (via search snippet; page returned 403 to fetch).
- The same data.gov.in resource page reportedly says "API for this resource does not exist" with a "Request API" button (snippet only; verify, since the user's resource 9ef84268-... evidently works) — [data.gov.in resource](https://data.gov.in/resource/current-daily-price-various-commodities-various-markets-mandi). A second listing exists: [variety wise daily market prices data](https://www.data.gov.in/resource/variety-wise-daily-market-prices-data-commodity) (details not verified).
- Agmarknet was upgraded to "Agmarknet Portal 2.0" in November 2025 to improve speed, usability and data reliability; 4,367 mandis are linked to it and 1,522 are on e-NAM; a mobile app lets users enter mandi data on the spot. The article mentions no download or API features — [AgriTimes, 20 Dec 2025](https://agritimes.co.in/agmarknet-2-0-e-nam-boost-real-time-mandi-price-transparency).
- Ministry guidance points users to the Agmarknet 2.0 Dashboard or the UPAg portal for daily price/arrival reports — [india.gov.in](https://www.india.gov.in/category/agriculture-rural-environment/subcategory/agricultural-produce/details/prices-arrival-reports-agmarknet) (snippet).
- UPAg (upag.gov.in) standardises/vets Agmarknet and other data; a third-party listing says it has no documented public API and its data covers crop estimates/MSP rather than mandi prices (third-party claim) — [Vikaspedia UPAg](https://en.vikaspedia.in/viewcontent/agriculture/agri-directory/unified-portal-for-agricultural-statistics?lgn=en); [parse.bot listing](https://parse.bot/marketplace/07fa78ed-8d38-4eeb-a4dd-9f3482166be4/upag-gov-in-api).
- e-NAM: no official public price API found. A 2026 PIB document mentions a public live price dashboard; researchers have pulled daily e-NAM min/modal/max/quantity from the portal, method undocumented; Agmarknet covers e-NAM and non-e-NAM markets — [PIB doc (Apr 2026)](https://static.pib.gov.in/WriteReadData/specificdocs/documents/2026/apr/doc2026413845801.pdf); [enam.gov.in](https://enam.gov.in/web/); [Venkatesh paper](https://ageconsearch.umn.edu/record/320462/files/08-P%20Venkatesh.pdf).
- Maharashtra: MSAMB (msamb.com) hosts APMC daily arrival/price data uploaded by APMCs under the MARKNET project; no API or developer docs found — [MSAMB MARKNET](https://www.msamb.com/Projects/MarketNetwork); [msamb.com/CIAMI](https://msamb.com/CIAMI). Source pages are old; current layout unverified.
- Madhya Pradesh: NIC's MP APMC digital ecosystem covers permits, fees and payments (transaction management), not a documented public price feed — [NIC InFocus Jul 2025](https://informatics.nic.in/files/websites/july-2025/nic-mp-apmc-digital-ecosystem.php). No official MP daily-price API found.
- State mandi systems increasingly push to Agmarknet 2.0 by API (e.g. UP e-Mandi), meaning state portals are upstream of, not independent from, Agmarknet — [Hans India](https://www.thehansindia.com/news/national/yogi-government-connects-all-251-up-mandis-to-national-network-1127009) (snippet).
- A 2017 developer note says the old Agmarknet site could not export more than one day's data at once; dated, current behaviour unverified — via search summary of [iancovert/Agmarknet](https://github.com/iancovert/Agmarknet) and [amitkaps/onions-dataset](https://awesome.ecosyste.ms/projects/github.com%2Famitkaps%2Fonions-dataset).
- Desagri (DES) publishes "Agricultural Prices in India" as a dataset on a release calendar (monthly/annual aggregates, not daily) — [DES release calendar](https://desagri.gov.in/wp-content/uploads/2026/06/Annual-Release-Calendar-for-the-Dataset-AGRICULTURAL-PRICES-IN-INDIA.pdf).

### Inferences
- A 503 on data.gov.in is likely a gateway/API-layer problem, not necessarily an Agmarknet outage; a direct Agmarknet 2.0 route could in principle work when data.gov.in fails, but only via scraping (see Q3), which has no documented permission.
- State portals (MSAMB, MP Mandi Board) are useful only as spot-checks or for state-specific gaps, not as bulk feeds.

### Gaps
- Could not read the data.gov.in resource page (403): exact license field, API key limits, per-call record cap, and update cadence are unconfirmed.
- No confirmation whether Agmarknet 2.0 offers official CSV/Excel report export, or its terms/robots.txt.
- No confirmed e-NAM or MSAMB API; need direct inspection of those sites.

## Commercial / community mirrors and aggregators

### Takeaway
The one credible, documented mirror is CEDA (Ashoka University): API available, but non-commercial only and monthly-updated, so it is a historical backfill, not a live fallback. Others (RapidAPI wrappers, Apify, Kaggle copies, price sites) are mostly re-wrappers of the same data.gov.in feed and share its failure mode.

### Cited Findings
- CEDA Agri Market Data: 300+ commodities, 2,700+ mandis, 2000 to present, updated monthly, cleaned to unique date/market/commodity/variety/grade, mapped to Census 2011 districts; API access via registered key — [CEDA Agmarknet portal](https://agmarknet.ceda.ashoka.edu.in/home/download); [CEDA data portal](https://ceda.ashoka.edu.in/data-portal/); [CEDA API](https://api.ceda.ashoka.edu.in/) (snippets).
- CEDA terms: free for non-commercial use only; must credit Centre for Economic Data & Analysis, Ashoka University, with CEDA logo and text credit, and cite "CEDA Agri Market Data (CEDA-AMD)"; no endorsement claims; no warranty; violators may lose API access; rate limits not stated — [CEDA API terms](https://ceda.ashoka.edu.in/api-terms-conditions/). Commercial licence terms not described.
- CEDA README at agmarknet.ceda.ashoka.edu.in/README.html returned 404 on fetch (broken or moved link; it appeared in search results) — [README](https://agmarknet.ceda.ashoka.edu.in/README.html).
- CEDA Daily Food Prices is a different, narrower dataset (22 commodities, 100+ centres since 2009) — [dca.ceda.ashoka.edu.in](https://dca.ceda.ashoka.edu.in).
- A RapidAPI-listed "real-time mandi price API" is built on data.gov.in (endpoints by state/crop/district; free plan; no terms or rate limits described; blog says it updates daily) — [DEV Community post](https://dev.to/shariqmirza/i-built-a-real-time-indian-mandi-price-api-heres-how-50k9). Depends on data.gov.in, so not independent.
- A paid Apify actor pulls data.gov.in dataset IDs (up to 100k rows) — [Apify](https://apify.com/themineworks/india-data-gov-scraper). Same upstream.
- Kaggle "Current Daily Prices of Commodities from Mandi" snapshot indexed by Baselight; licence and freshness unverified — [Baselight](https://baselight.app/u/kaggle/dataset/brpuneet898_current_daily_prices_of_commodities_from_mandi). GitHub: [iancovert/Agmarknet](https://github.com/iancovert/Agmarknet) (historical download scripts), [amitkaps/onions-dataset](https://awesome.ecosyste.ms/projects/github.com%2Famitkaps%2Fonions-dataset); a Mendeley deposit exists: [Mendeley ds9jmxp9zy](https://data.mendeley.com/datasets/ds9jmxp9zy). All are static snapshots.
- An open-source Agmarknet MCP server falls back to offline mock data when the API key is invalid — warning against silent mock fallback — [Glama listing](https://glama.ai/mcp/servers/Krishna-Baldwa/agmarket-mcp/schema).
- Consumer sites (KisanDeals, NaPanta, piplanapane) publish state mandi rates; sourcing undisclosed, unofficial, scraping them is not endorsed — [KisanDeals](https://www.kisandeals.com), [NaPanta](https://www.napanta.com), [piplanapane](https://piplanapane.in/en/blog/daily-apmc-price-in-maharashtra-todays-market-rates-by-crop-district).
- Farmonaut "2026 Guide" on Agmarknet API access is marketing content; page returned 403 and was not verified — [Farmonaut](https://farmonaut.com/api-development/agmarknet-api-access-crop-prices-market-data-india).
- NCDEX/MCX spot references: not researched in depth; they are exchange benchmark prices for a limited commodity set, not APMC min/max/modal by variety and market (no source gathered).

### Inferences
- For a commercial app, CEDA's non-commercial clause rules it out as a production source unless Ashoka grants a commercial licence (would need to ask). Using it for internal analysis/back-testing is the safer fit.
- Third-party wrappers add a failure point and unclear legal terms; avoid as the fallback.

### Gaps
- No Kaggle licence, no verified RapidAPI terms, no NCDEX/MCX feed details, no CEDA rate limits or commercial licence terms.

## Licensing, terms, and legality (GODL-India, scraping)

### Takeaway
Data published on data.gov.in is generally under GODL-India, which allows commercial reuse with attribution; the data.gov.in API route is therefore the cleanest legal path. Scraping agmarknet.gov.in/Agmarknet 2.0 is unverified: I found no terms or robots.txt, so do not recommend it without checking.

### Cited Findings
- GODL-India (Gazette, Feb 2017) permits lawful commercial and non-commercial use incl. derivatives; requires acknowledging the data provider; forbids implying endorsement; not all government datasets fall under it — [Wikimedia GODL template](https://www.wikipedia.org/wiki/Template:GODL-India-text); [OSM legal-talk](https://lists.openstreetmap.org/pipermail/legal-talk/2018-August/008675.html); [OSM wiki](https://wiki.openstreetmap.org/wiki/Open_Geospatial_Data_from_Government_of_India). Secondary sources; the gazette text was not retrieved.
- Agmarknet terms of use and robots.txt were not found; india.gov.in Agmarknet pages show only a "captcha loading" artifact — [india.gov.in](https://www.india.gov.in/category/agriculture-rural-environment/subcategory/research-marketing/details/website-of-agmarknet). The legal blog notes scraping is not automatically illegal in India, but site terms may forbid it — [LegalKart](https://www.legalkart.com/en/legal-blog/web-scraping-legal-in-india).

### Inferences
- Agmarknet's report forms use captcha/multi-step forms (per India.gov.in listing and the onions-dataset note), so automated scraping likely conflicts with bot-detection; do not bypass captchas.

### Gaps
- Exact licence text on the user's resource page and data.gov.in's API usage policy.

## Best secondary source and whether to switch primary

### Takeaway
Keep data.gov.in as primary; no discovered alternative is both official, documented, commercially usable and fresh. Build resilience instead: retry with backoff, store last good data in your own DB (you already persist daily prices), serve stale-with-flag, and optionally poll a second data.gov.in resource (the "variety wise daily market prices" listing) as a cheap hedge.

### Cited Findings
- Second data.gov.in listing of Agmarknet-derived data exists — [data.gov.in variety-wise resource](https://www.data.gov.in/resource/variety-wise-daily-market-prices-data-commodity); same upstream/gateway so it only hedges a resource-specific issue.
- Agmarknet 2.0 relaunch (Nov 2025) with 4,367 mandis is the authoritative source — [AgriTimes](https://agritimes.co.in/agmarknet-2-0-e-nam-boost-real-time-mandi-price-transparency).
- CEDA is monthly and non-commercial — [CEDA terms](https://ceda.ashoka.edu.in/api-terms-conditions/).

### Inferences
- Ranking as fallback: (1) own stored last-good data plus retry/backoff; (2) alternate data.gov.in resource ID or the data.gov.in downloadable file if the portal offers it (to verify); (3) written request to the Agmarknet/DMI or NIC data.gov.in team for an official feed or higher quota (the "Request API" channel); (4) CEDA only for historical backfill, and only if licensing is cleared; (5) state portals (MSAMB) for manual spot-checks.
- Switching the primary is not justified on current evidence.

### Gaps
- Whether data.gov.in offers bulk CSV downloads for this resource, and whether the 503s are quota-related, could not be determined; checking the resource page while logged in is the next step.
