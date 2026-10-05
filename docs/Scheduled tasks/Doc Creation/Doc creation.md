Generate a technical reference document: "External Integrations & Configuration Management"

Purpose: Centralized, production-ready registry of all third-party integrations, API keys, domains, URLs, and environment-specific settings for MolBhav API — eliminates scattered configs and enables quick production updates without code changes.

Structure:

1. **Quick Reference Table**
   - Integration name | Service type | Primary use | Env vars | Status (active/deprecated) | Owner
   - Sortable, searchable — one row per integration

2. **Integration Sections** (per integration: Payment, Email, SMS, Cloud Storage, Analytics, etc.)
   - Service name & purpose
   - Account/subscription details (SaaS provider, plan tier, renewal date)
   - Base URLs (dev/staging/prod)
   - Authentication (key name, rotation schedule, last rotated date)
   - Configuration (timeout, rate limits, webhook endpoints)
   - Status page / support link
   - Escalation contact

3. **Domain & SSL Configuration**
   - Primary domain, subdomains (api., admin., cdn., etc.)
   - SSL cert provider (cert authority, expiration, renewal process)
   - DNS records (A/CNAME/MX, where managed: Route53/Cloudflare/etc.)
   - Domain registrar details

4. **Environment-Specific Settings** (Dev/Staging/Prod table)
   - API endpoints
   - Database connection strings (host, port, pool size)
   - Cache servers (Redis)
   - Message queues
   - Log aggregation targets

5. **Secret Management**
   - How secrets are stored (Key Vault, HashiCorp Vault, appsettings.json for dev only)
   - Rotation policy per integration (90-day, 180-day, event-driven)
   - Last rotation log
   - Breakglass access procedure

6. **Update Checklist**
   - Step-by-step: update secret → test (dev) → stage → verify logs → deploy prod
   - Rollback triggers and procedure
   - Notification contacts (ops, security)

7. **Dependency Map**
   - Visual: which services depend on which integrations
   - Critical path (API won't start without these)

Format: Markdown table-heavy, copy-paste safe, version-controlled in repo.

No secrets hardcoded; use placeholders like {{ PAYMENT_GATEWAY_KEY }}.