# External Integrations & Configuration Management

**MolBhav API** — Centralized, production-ready registry of all third-party integrations, API keys, domains, URLs, and environment-specific settings.

**Last Updated:** October 5, 2026  
**Maintained By:** [Operations & DevOps Team]  
**Version:** 1.0

---

## 1. Quick Reference Table

| Integration Name | Service Type | Primary Use | Env Var Prefix | Status | Owner | Support |
|---|---|---|---|---|---|---|
| Stripe | Payment Gateway | Subscription & transaction processing | `STRIPE_` | active | Finance Ops | support@stripe.com |
| SendGrid | Email Service | Transactional & marketing emails | `SENDGRID_` | active | Marketing | support@sendgrid.com |
| Twilio | SMS & Voice | SMS notifications, OTP delivery | `TWILIO_` | active | Notifications Team | support.twilio.com |
| AWS S3 | Cloud Storage | File uploads, backups, CDN assets | `AWS_S3_` | active | Infrastructure | aws.amazon.com/support |
| Google Analytics | Analytics & Monitoring | User behavior tracking, funnel analysis | `GA_` | active | Product Team | support.google.com/analytics |
| Auth0 | Identity & Auth | SSO, OAuth2, SAML integration | `AUTH0_` | active | Security | support.auth0.com |
| Datadog | Monitoring & Logging | APM, logs, metrics, alerts | `DATADOG_` | active | SRE | support.datadoghq.com |
| Redis Cloud | Caching & Sessions | Session storage, cache layer | `REDIS_` | active | Infrastructure | support.redis.com |

---

## 2. Integration Sections

### 2.1 Stripe (Payment Gateway)

**Service Name & Purpose:** Stripe Payment Platform  
Process subscriptions, one-time payments, invoices, and payout reconciliation.

**Account Details:**
- **Provider:** Stripe, Inc.
- **Plan Tier:** Stripe Grow (volume-based pricing)
- **Subscription Renewal:** Auto-renews monthly
- **Account ID:** `acct_{{ STRIPE_ACCOUNT_ID }}`
- **Contact:** stripe-account-manager@molbhav.com

**Base URLs:**
- **Development:** `https://api.stripe.com/v1` (test mode)
- **Staging:** `https://api.stripe.com/v1` (test mode, isolated keys)
- **Production:** `https://api.stripe.com/v1` (live mode)

**Authentication:**
- **API Key Name:** `STRIPE_SECRET_KEY`
- **Publishable Key:** `STRIPE_PUBLISHABLE_KEY`
- **Webhook Secret:** `STRIPE_WEBHOOK_SECRET`
- **Rotation Schedule:** 180 days (or on key compromise)
- **Last Rotated:** September 2026
- **Key Management:** AWS Secrets Manager

**Configuration:**
- **API Version:** `2023-10-16`
- **Timeout:** 30 seconds
- **Retry Policy:** Exponential backoff, max 3 attempts
- **Webhook Endpoints:**
  - Dev: `https://dev-api.molbhav.com/webhooks/stripe`
  - Prod: `https://api.molbhav.com/webhooks/stripe`
- **Events Monitored:** `payment_intent.succeeded`, `payment_intent.payment_failed`, `invoice.paid`, `customer.subscription.deleted`

**Status & Support:**
- **Stripe Status Page:** https://status.stripe.com
- **Support Tier:** Enterprise
- **Escalation Contact:** stripe-account-manager@molbhav.com
- **SLA:** 99.99% uptime guarantee

---

### 2.2 SendGrid (Email Service)

**Service Name & Purpose:** SendGrid Transactional Email Platform  
Send password resets, order confirmations, promotional campaigns.

**Account Details:**
- **Provider:** Twilio SendGrid
- **Plan Tier:** Advanced Plan (500k emails/month)
- **Subscription Renewal:** Monthly on 1st
- **Sender Authentication:** Domain verified (sendgrid.molbhav.com)
- **Contact:** sendgrid-account@molbhav.com

**Base URLs:**
- **Development:** `https://api.sendgrid.com/v3` (sandbox)
- **Staging:** `https://api.sendgrid.com/v3` (production keys, filtered recipients)
- **Production:** `https://api.sendgrid.com/v3`

**Authentication:**
- **API Key Name:** `SENDGRID_API_KEY`
- **Rotation Schedule:** 90 days
- **Last Rotated:** August 2026
- **Key Management:** HashiCorp Vault

**Configuration:**
- **Timeout:** 10 seconds
- **Default From Address:** `noreply@molbhav.com`
- **Reply-To:** `support@molbhav.com`
- **Rate Limit:** 100 requests/second
- **Bounce/Complaint Handling:** Automatic unsubscribe on hard bounce
- **Subuser:** `molbhav-api` (for multi-tenant isolation)

**Status & Support:**
- **SendGrid Status Page:** https://sendgrid.status.io
- **Support Tier:** Professional
- **Escalation Contact:** sendgrid-account@molbhav.com

---

### 2.3 Twilio (SMS & Voice)

**Service Name & Purpose:** Twilio Communication Platform  
Send SMS OTPs, SMS notifications, phone verification.

**Account Details:**
- **Provider:** Twilio, Inc.
- **Plan Tier:** Pay-as-you-go
- **Account SID:** `{{ TWILIO_ACCOUNT_SID }}`
- **Contact:** twilio-manager@molbhav.com

**Base URLs:**
- **Development:** `https://api.twilio.com`
- **Staging:** `https://api.twilio.com`
- **Production:** `https://api.twilio.com`

**Authentication:**
- **Account SID:** `{{ TWILIO_ACCOUNT_SID }}`
- **Auth Token:** `TWILIO_AUTH_TOKEN`
- **API Key:** `TWILIO_API_KEY` (optional, for enhanced security)
- **Rotation Schedule:** Event-driven (on suspected compromise)
- **Last Rotated:** July 2026
- **Key Management:** AWS Secrets Manager

**Configuration:**
- **Twilio Phone Number:** `{{ TWILIO_PHONE_NUMBER }}` (US-based)
- **Timeout:** 15 seconds
- **Retry Policy:** 2 attempts, 5-second delay
- **Rate Limit:** 50 SMS/second per number
- **Webhooks:** Status callbacks for delivery confirmation
- **Messaging Service SID:** `{{ TWILIO_MESSAGING_SERVICE_SID }}`

**Status & Support:**
- **Twilio Status Page:** https://status.twilio.com
- **Support Tier:** Professional
- **Escalation Contact:** twilio-manager@molbhav.com

---

### 2.4 AWS S3 (Cloud Storage)

**Service Name & Purpose:** Amazon S3 Object Storage  
Store user uploads, backups, static assets, CDN distribution.

**Account Details:**
- **Provider:** Amazon Web Services (AWS)
- **AWS Account ID:** `{{ AWS_ACCOUNT_ID }}`
- **Region:** `us-east-1` (primary), `us-west-2` (failover)
- **S3 Plan:** On-demand billing (no upfront commitment)
- **Contact:** aws-account-manager@molbhav.com

**Base URLs:**
- **Development:** `https://s3.us-east-1.amazonaws.com` (dev bucket)
- **Staging:** `https://s3.us-east-1.amazonaws.com` (staging bucket)
- **Production:** `https://s3.us-east-1.amazonaws.com` (prod bucket)
- **CDN:** `https://cdn.molbhav.com` (CloudFront distribution)

**Authentication:**
- **IAM User:** `molbhav-api-s3`
- **Access Key ID:** `AWSAKEYID{{ AWS_ACCESS_KEY_ID }}`
- **Secret Access Key:** `{{ AWS_SECRET_ACCESS_KEY }}`
- **Rotation Schedule:** 90 days
- **Last Rotated:** August 2026
- **Key Management:** AWS Secrets Manager, automatic rotation via Lambda

**Configuration:**
- **S3 Buckets:**
  - `molbhav-uploads` (user uploads)
  - `molbhav-backups` (database backups)
  - `molbhav-assets` (static CDN assets)
- **Versioning:** Enabled on all buckets
- **Encryption:** AES-256 (SSE-S3) by default; KMS optional
- **Lifecycle Policies:** 90-day archive to Glacier
- **CORS:** Configured for `molbhav.com`, `*.molbhav.com`
- **Timeout:** 30 seconds
- **Multipart Upload Threshold:** 100MB

**Status & Support:**
- **AWS Status Page:** https://status.aws.amazon.com
- **Support Tier:** Business
- **Escalation Contact:** aws-account-manager@molbhav.com

---

### 2.5 Google Analytics (Analytics & Monitoring)

**Service Name & Purpose:** Google Analytics 4 Platform  
Track user behavior, funnel analysis, conversion tracking.

**Account Details:**
- **Provider:** Google Cloud
- **Property ID:** `{{ GA4_PROPERTY_ID }}`
- **Data Stream ID:** `{{ GA4_STREAM_ID }}`
- **Measurement ID:** `{{ GA4_MEASUREMENT_ID }}`
- **Contact:** analytics-team@molbhav.com

**Base URLs:**
- **Tracking Endpoint:** `https://www.google-analytics.com/g/collect`
- **Reporting API:** `https://analyticsreporting.googleapis.com/v4`

**Authentication:**
- **API Key:** `{{ GA4_API_KEY }}`
- **Service Account Email:** `molbhav-analytics@molbhav.iam.gserviceaccount.com`
- **Rotation Schedule:** 180 days (or on key compromise)
- **Key Management:** Google Cloud Secret Manager

**Configuration:**
- **Tracking Type:** Page view, event, e-commerce
- **Session Timeout:** 30 minutes
- **Event Parameters:** Custom dimensions (user_id, plan_tier, region)
- **Data Retention:** 14 months
- **Timeout:** 5 seconds (fire-and-forget)

**Status & Support:**
- **Google Cloud Status Page:** https://status.cloud.google.com
- **Support Tier:** Standard
- **Escalation Contact:** analytics-team@molbhav.com

---

### 2.6 Auth0 (Identity & Authentication)

**Service Name & Purpose:** Auth0 Identity Platform  
SSO, OAuth2, SAML, multi-factor authentication (MFA).

**Account Details:**
- **Provider:** Auth0 (Okta subsidiary)
- **Tenant Domain:** `molbhav.auth0.com`
- **Tenant ID:** `{{ AUTH0_TENANT_ID }}`
- **Plan Tier:** Professional
- **Contact:** auth0-admin@molbhav.com

**Base URLs:**
- **Development:** `https://molbhav-dev.auth0.com`
- **Staging:** `https://molbhav-staging.auth0.com`
- **Production:** `https://molbhav.auth0.com`

**Authentication:**
- **Management API Client ID:** `{{ AUTH0_CLIENT_ID }}`
- **Management API Client Secret:** `{{ AUTH0_CLIENT_SECRET }}`
- **API Audience:** `https://molbhav.auth0.com/api/v2/`
- **Rotation Schedule:** 90 days
- **Last Rotated:** August 2026
- **Key Management:** AWS Secrets Manager

**Configuration:**
- **OAuth2 Grant Types:** Authorization Code (web), Implicit (SPA), Client Credentials (M2M)
- **MFA:** Enforced for admin users; optional for regular users
- **Connections:** Username/Password, Google OAuth, GitHub OAuth
- **Token Expiry:** Access token 1 hour, Refresh token 7 days
- **CORS:** Configured for all molbhav.com subdomains
- **Redirect URLs:**
  - Dev: `http://localhost:3000/callback`
  - Staging: `https://staging.molbhav.com/callback`
  - Prod: `https://app.molbhav.com/callback`

**Status & Support:**
- **Auth0 Status Page:** https://status.auth0.com
- **Support Tier:** Professional
- **Escalation Contact:** auth0-admin@molbhav.com

---

### 2.7 Datadog (Monitoring & Observability)

**Service Name & Purpose:** Datadog Monitoring & Logging Platform  
Application Performance Monitoring (APM), logs, metrics, alerts, dashboards.

**Account Details:**
- **Provider:** Datadog, Inc.
- **Organization ID:** `{{ DATADOG_ORG_ID }}`
- **Site:** US (us5.datadoghq.com)
- **Plan Tier:** Pro
- **Contact:** datadog-admin@molbhav.com

**Base URLs:**
- **API Endpoint:** `https://api.us5.datadoghq.com`
- **Application:** `https://app.us5.datadoghq.com`

**Authentication:**
- **API Key:** `{{ DATADOG_API_KEY }}`
- **Application Key:** `{{ DATADOG_APP_KEY }}`
- **Rotation Schedule:** 180 days
- **Last Rotated:** July 2026
- **Key Management:** HashiCorp Vault

**Configuration:**
- **Log Retention:** 30 days (hot), 90 days (index)
- **APM Sample Rate:** 100% for errors, 10% for success
- **Metrics Retention:** 15 months
- **Alert Notification Channels:** Slack, PagerDuty, email
- **Custom Dashboards:** API health, error rates, latency percentiles
- **Service Dependencies:** Auto-detected from APM

**Status & Support:**
- **Datadog Status Page:** https://status.datadoghq.com
- **Support Tier:** Enterprise
- **Escalation Contact:** datadog-admin@molbhav.com

---

### 2.8 Redis Cloud (Caching & Sessions)

**Service Name & Purpose:** Redis Cloud Managed Cache  
Session storage, distributed locks, cache layer.

**Account Details:**
- **Provider:** Redis Labs (Now part of Redis)
- **Subscription ID:** `{{ REDIS_SUBSCRIPTION_ID }}`
- **Plan Tier:** Pay-as-you-go (1GB base)
- **Contact:** redis-admin@molbhav.com

**Base URLs:**
- **Development:** `redis://dev-redis.molbhav.redislabs.com:{{ REDIS_DEV_PORT }}`
- **Staging:** `redis://staging-redis.molbhav.redislabs.com:{{ REDIS_STAGING_PORT }}`
- **Production:** `redis://prod-redis.molbhav.redislabs.com:{{ REDIS_PROD_PORT }}`

**Authentication:**
- **Default User Password:** `{{ REDIS_PASSWORD }}`
- **ACL User (if enabled):** `molbhav-app`
- **Rotation Schedule:** 90 days
- **Last Rotated:** August 2026
- **Key Management:** AWS Secrets Manager

**Configuration:**
- **Memory Limit (Prod):** 5GB
- **Eviction Policy:** `allkeys-lru` (least recently used)
- **Persistence:** RDB snapshots every 6 hours
- **Replication:** 1 replica for HA
- **Timeout:** 5 seconds (default)
- **Key Prefix:** `molbhav:` (for multi-tenancy safety)

**Status & Support:**
- **Redis Cloud Status Page:** https://status.redis.io
- **Support Tier:** Professional
- **Escalation Contact:** redis-admin@molbhav.com

---

## 3. Domain & SSL Configuration

### 3.1 Primary Domain

| Property | Value |
|---|---|
| **Domain Name** | `molbhav.com` |
| **Registrar** | GoDaddy, Inc. |
| **Registrar Contact** | domain-admin@molbhav.com |
| **Renewal Date** | March 15, 2025 |
| **DNS Provider** | Route 53 (AWS) |
| **Status** | Active |

### 3.2 Subdomains

| Subdomain | Purpose | DNS Target | SSL Cert |
|---|---|---|---|
| `api.molbhav.com` | API gateway | ALB (us-east-1) | ACM (auto-renew) |
| `admin.molbhav.com` | Admin dashboard | CloudFront | ACM (auto-renew) |
| `app.molbhav.com` | Web application | CloudFront | ACM (auto-renew) |
| `cdn.molbhav.com` | Static assets CDN | CloudFront | ACM (auto-renew) |
| `docs.molbhav.com` | API documentation | S3 + CloudFront | ACM (auto-renew) |
| `mail.molbhav.com` | Mail server | MX record | Self-signed or Let's Encrypt |

### 3.3 SSL Certificate Management

**Certificate Authority:** AWS Certificate Manager (ACM)

| Cert Name | Domain(s) | Expiration | Renewal | Status |
|---|---|---|---|---|
| `molbhav-wildcard` | `*.molbhav.com` | 2025-03-10 | Automatic (ACM) | Active |
| `molbhav-root` | `molbhav.com` | 2025-03-10 | Automatic (ACM) | Active |

**Renewal Process:**
1. ACM auto-renews 30 days before expiration
2. No manual intervention required (DNS validation via Route 53)
3. Existing connections gracefully updated

**Fallback/Manual Renewal:**
- **Certificate Provider:** Let's Encrypt (backup)
- **ACME Client:** Certbot
- **Renewal Command:** `certbot renew --dns-route53`
- **Schedule:** Monthly (via cron: `0 3 1 * *`)

### 3.4 DNS Records

**Zone ID:** `{{ ROUTE_53_ZONE_ID }}`

| Record Type | Name | Value | TTL | Status |
|---|---|---|---|---|
| A | `molbhav.com` | `{{ CLOUDFRONT_IP }}` | 300 | Active |
| CNAME | `www.molbhav.com` | `molbhav.com` | 300 | Active |
| A | `api.molbhav.com` | `{{ ALB_IP }}` | 60 | Active |
| CNAME | `cdn.molbhav.com` | `d{{ CLOUDFRONT_ID }}.cloudfront.net` | 300 | Active |
| MX | `molbhav.com` | `10 mail.molbhav.com` | 300 | Active |
| TXT | `molbhav.com` | `v=spf1 include:sendgrid.net ~all` | 300 | Active |
| TXT | `_dmarc.molbhav.com` | `v=DMARC1; p=quarantine; ...` | 300 | Active |
| TXT | `_acme-challenge.molbhav.com` | `{{ ACME_CHALLENGE_TOKEN }}` | 300 | Auto-managed |

---

## 4. Environment-Specific Settings

### 4.1 API Endpoints

| Environment | Base URL | Region | Load Balancer | Status |
|---|---|---|---|---|
| **Development** | `http://localhost:3000` | Local | None | Active |
| **Staging** | `https://staging-api.molbhav.com` | us-east-1 (AWS) | ALB (staging) | Active |
| **Production** | `https://api.molbhav.com` | us-east-1 + us-west-2 | ALB (prod) + Route 53 failover | Active |

### 4.2 Database Connections

| Environment | Host | Port | Database | Connection Pool | Status |
|---|---|---|---|---|---|
| **Development** | `localhost` | 5432 | `molbhav_dev` | 5 | Active |
| **Staging** | `staging-db.molbhav.com` | 5432 | `molbhav_staging` | 20 | Active |
| **Production** | `prod-db-primary.molbhav.com` | 5432 | `molbhav_prod` | 50 | Active |
| **Production (Read Replica)** | `prod-db-replica.molbhav.com` | 5432 | `molbhav_prod` | 50 | Active |

**Connection String Format:**
```
postgresql://{{ DB_USER }}:{{ DB_PASSWORD }}@{{ DB_HOST }}:{{ DB_PORT }}/{{ DB_NAME }}?sslmode=require&pool_size={{ POOL_SIZE }}
```

**SSL:** Required for all production connections

### 4.3 Cache Servers (Redis)

| Environment | Host | Port | Password | Memory | Status |
|---|---|---|---|---|---|
| **Development** | `localhost` | 6379 | None (optional) | 512MB | Active |
| **Staging** | `staging-redis.molbhav.redislabs.com` | {{ REDIS_PORT }} | `{{ REDIS_PASSWORD }}` | 2GB | Active |
| **Production** | `prod-redis.molbhav.redislabs.com` | {{ REDIS_PORT }} | `{{ REDIS_PASSWORD }}` | 5GB | Active |

### 4.4 Message Queues

| Environment | Service | Host | Port | Purpose | Status |
|---|---|---|---|---|---|
| **Development** | RabbitMQ | `localhost` | 5672 | Job queue | Active |
| **Staging** | AWS SQS | Regional | HTTPS | Async tasks | Active |
| **Production** | AWS SQS | Regional | HTTPS | Async tasks, background jobs | Active |

**Queue Names:**
- `molbhav-emails-queue`: Email dispatch
- `molbhav-notifications-queue`: Push/SMS notifications
- `molbhav-analytics-queue`: Event tracking
- `molbhav-backups-queue`: Scheduled backups
- `molbhav-reports-queue`: Report generation

### 4.5 Log Aggregation

| Environment | Service | Host | Port | Index Retention | Status |
|---|---|---|---|---|---|
| **Development** | Local file | `/var/log/molbhav/` | N/A | 7 days | Active |
| **Staging** | Datadog | `{{ DATADOG_HOST }}` | HTTPS | 30 days | Active |
| **Production** | Datadog | `{{ DATADOG_HOST }}` | HTTPS | 30 days (hot) + 90 days (cold) | Active |

**Log Format:** JSON (Structured logging)

---

## 5. Secret Management

### 5.1 Secret Storage

| Component | Storage | Provider | Rotation | Access |
|---|---|---|---|---|
| **API Keys** | AWS Secrets Manager | AWS KMS | 90 days | Lambda, EC2 IAM role |
| **Database Credentials** | AWS Secrets Manager | AWS KMS | 90 days | RDS proxy, EC2 IAM role |
| **TLS/SSL Certificates** | AWS Certificate Manager | AWS KMS | Auto (30 days before expiry) | CloudFront, ALB |
| **Encryption Keys** | HashiCorp Vault | Stored encrypted at-rest | Manual rotation | Authorized services only |

### 5.2 Rotation Policies

| Secret Type | Rotation Frequency | Trigger | Owner | Process |
|---|---|---|---|---|
| **API Keys (3rd party)** | 90 days | Scheduled | DevOps | Automated AWS Lambda → Vault → Services |
| **Database Passwords** | 180 days | Quarterly + event-driven | DBA | Manual (coordinated maintenance window) |
| **TLS Certificates** | Auto-renew 30 days before | Expiration | AWS ACM | Fully automated |
| **SSH Keys (admin access)** | 6 months | Event-driven (on departure) | Security | Manual key revocation in IAM |
| **Webhook Secrets** | 90 days | Scheduled | Integration Owner | Automated via Lambda |

### 5.3 Rotation Audit Log

| Date | Secret | Environment | Status | Notes |
|---|---|---|---|---|
| 2026-09-15 | STRIPE_SECRET_KEY | Production | Success | Annual rotation, tested in staging first |
| 2026-08-22 | AWS_ACCESS_KEY_ID | Production | Success | Routine 90-day rotation |
| 2026-08-20 | SENDGRID_API_KEY | All | Success | Routine 90-day rotation |
| 2026-08-18 | REDIS_PASSWORD | Staging & Prod | Success | Routine 90-day rotation |
| 2026-07-10 | DATADOG_API_KEY | All | Success | Routine 180-day rotation |
| 2026-07-05 | AUTH0_CLIENT_SECRET | All | Success | Routine 90-day rotation |

### 5.4 Breakglass Access Procedure

**Use Case:** Emergency access when rotation is compromised or normal channels are unavailable.

1. **Escalation:** Contact on-call security engineer + platform lead
2. **Approval:** Requires 2 authorized signatories (CTO + Security Lead)
3. **Access Method:**
   - SSH to bastion host using emergency SSH key (stored in vault)
   - Use `aws-vault` to assume `molbhav-breakglass` IAM role
   - Retrieve secret from AWS Secrets Manager with full audit logging
4. **Time Limit:** 1 hour (auto-expiry of assume-role session)
5. **Audit:** All accesses logged to CloudTrail + Datadog
6. **Revocation:** Emergency key revoked within 24 hours of use

**Emergency Contacts:**
- **On-Call Security:** `{{ SECURITY_ON_CALL_PHONE }}`
- **CTO:** `cto@molbhav.com`
- **Platform Lead:** `platform-lead@molbhav.com`

---

## 6. Update Checklist

### 6.1 Secret Rotation Runbook

Follow this step-by-step checklist when rotating an API key or credential.

#### Pre-Flight Checks
- [ ] Identify the secret to rotate (API key, password, token)
- [ ] Identify all services dependent on this secret
- [ ] Notify team in Slack (#ops-alerts)
- [ ] Schedule maintenance window (low-traffic period, Tuesday–Thursday 2–4 PM UTC preferred)
- [ ] Create runbook ticket in Jira (with rollback plan)

#### Dev Environment (Test Rotation First)
- [ ] Retrieve new secret from provider (e.g., Stripe dashboard)
- [ ] Update secret in local `.env` file (dev machine only)
- [ ] Restart dev server and run integration tests:
  ```bash
  npm test -- --testPathPattern=integration
  ```
- [ ] Verify no auth errors in logs
- [ ] Revert to old key and confirm services restart cleanly

#### Staging Environment (Validate in Staging)
- [ ] Update secret in AWS Secrets Manager for staging
- [ ] Deploy updated config to staging (no code changes needed)
- [ ] Monitor logs for 30 minutes: `datadog logs query 'env:staging error'`
- [ ] Run smoke tests: `./scripts/smoke-tests.sh staging`
- [ ] Confirm staging dashboards show no errors
- [ ] Alert team that staging is ready for manual testing

#### Production Environment (Main Rotation)
- [ ] Scale down background job workers to reduce concurrent errors:
  ```bash
  aws ecs update-service --cluster prod --service job-workers --desired-count 1
  ```
- [ ] Update secret in AWS Secrets Manager for production
- [ ] Deploy updated config via blue-green deployment (no downtime):
  ```bash
  ./scripts/deploy-secret.sh prod {{ SECRET_NAME }}
  ```
- [ ] Monitor metrics for 5 minutes:
  - API error rate (should remain < 0.1%)
  - 3rd-party integration latency
  - Failed requests in Datadog
- [ ] If healthy, scale job workers back up:
  ```bash
  aws ecs update-service --cluster prod --service job-workers --desired-count 5
  ```
- [ ] Verify all services are consuming new secret:
  ```bash
  grep -r "{{ SECRET_NAME }}" /etc/molbhav/config/ | grep -v "expired"
  ```

#### Verification
- [ ] Create a real transaction (if applicable) to test end-to-end:
  - Stripe: Process a test charge and verify webhook received
  - SendGrid: Send a test email and confirm delivery
  - Twilio: Send a test SMS and confirm delivery
- [ ] Check production logs for 5 minutes: `datadog logs query 'env:prod error'`
- [ ] Verify no retry storms in message queues
- [ ] Confirm old key is still active on provider (don't delete yet)

#### Cleanup & Documentation
- [ ] Archive old secret in AWS Secrets Manager (set `ExpirationDate`)
- [ ] Update rotation log in this document (Section 5.3)
- [ ] Notify team: `@ops-team Rotation of {{ SECRET_NAME }} complete ✅`
- [ ] Close Jira ticket
- [ ] Document any issues in Slack thread for future reference

#### Rollback Procedure (If Needed)
- [ ] **Trigger:** API errors exceed 1% or integration is unreachable for > 5 min
- [ ] **Action:** Immediately revert to old secret in AWS Secrets Manager:
  ```bash
  aws secretsmanager restore-secret --secret-id {{ SECRET_NAME }}
  ```
- [ ] **Deploy:** Re-trigger deployment with old secret
- [ ] **Verify:** Confirm error rate drops within 2 minutes
- [ ] **Notify:** Alert security team and provider (e.g., Stripe support)
- [ ] **Investigate:** Post-mortem within 24 hours

---

## 7. Dependency Map

### 7.1 Service Dependencies (Critical Path)

```
┌─────────────────────────────────────────────────────────┐
│                  API Gateway (ALB)                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
├──► PostgreSQL (required to start)                       │
│    └── Redis (optional, degrades gracefully)            │
│                                                         │
├──► Auth0 (required for login)                           │
│                                                         │
├──► Stripe (required for billing endpoints)              │
│    └── SQS (async payment processing)                   │
│        └── SendGrid (payment confirmations)             │
│                                                         │
├──► AWS S3 (required for file uploads)                   │
│    └── CloudFront CDN (required for asset delivery)     │
│                                                         │
├──► Datadog (optional, logs errors if missing)           │
│                                                         │
└──► SendGrid (optional, graceful degradation if down)    │
     └── Twilio (optional, graceful degradation if down)  │
```

### 7.2 Startup Sequence (Critical First → Optional Last)

1. **Database (PostgreSQL)** — Required to start
   - Retry: 30 attempts, 2-second intervals
   - Timeout: 60 seconds total
   - Failure: Service exits with error code 1

2. **Cache (Redis)** — Recommended, optional
   - Retry: 5 attempts, 1-second intervals
   - Timeout: 10 seconds total
   - Failure: Service starts with in-memory cache (degraded)

3. **Auth0** — Required for authentication
   - Retry: 10 attempts, 3-second intervals
   - Timeout: 30 seconds total
   - Failure: Service exits with error code 2

4. **Stripe** — Required for billing
   - Retry: 10 attempts, 3-second intervals
   - Timeout: 30 seconds total
   - Failure: Service exits with error code 3

5. **AWS S3** — Required for file uploads
   - Retry: 5 attempts, 2-second intervals
   - Timeout: 15 seconds total
   - Failure: Service exits with error code 4

6. **Datadog** — Optional, fire-and-forget
   - Retry: None (fire-and-forget)
   - Timeout: 5 seconds
   - Failure: Log warning, continue startup

7. **SendGrid & Twilio** — Optional
   - Retry: None (graceful degradation)
   - Timeout: 10 seconds
   - Failure: Log warning, use fallback (e.g., in-app notifications)

### 7.3 Health Check Endpoints

| Service | Health Endpoint | Expected Response | Timeout |
|---|---|---|---|
| PostgreSQL | N/A (driver check) | Connection successful | 5s |
| Redis | `PING` command | `PONG` | 5s |
| Auth0 | `GET /.well-known/openid-configuration` | 200 OK | 10s |
| Stripe | `GET /v1/account` | 200 OK | 10s |
| AWS S3 | `HEAD /test-file.txt` | 200 OK | 10s |
| Datadog | `POST /api/v1/validate` | 200 OK | 5s |
| SendGrid | `GET /v3/api_keys` | 200 OK | 10s |
| Twilio | `GET /2010-04-01/Accounts` | 200 OK | 10s |

### 7.4 Fallback & Degradation Strategy

| Service | Failure Mode | Fallback | Behavior |
|---|---|---|---|
| PostgreSQL | Connection timeout | N/A | Service crashes, alerts fired |
| Redis | Unreachable | In-memory cache | Slower response, high memory usage |
| Auth0 | Login endpoint down | Cached JWT validation | New users cannot login |
| Stripe | Payment API down | Queue to SQS, retry hourly | Payments delayed, not lost |
| S3 | Upload failure | Local temp storage | Async S3 sync when available |
| Datadog | Logs unavailable | Console/file logging | Monitoring blind until restored |
| SendGrid | Email down | In-app notification | Users notified in dashboard |
| Twilio | SMS down | Email notification | SMS replaced with email alert |

---

## 8. Notes & Best Practices

### 8.1 Environment Variable Naming Convention

- **Prefix by service:** `{{ SERVICE }}_{{ COMPONENT }}_{{ PROPERTY }}`
- **Examples:**
  - `STRIPE_SECRET_KEY` (payment gateway)
  - `SENDGRID_API_KEY` (email service)
  - `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD` (cache server)
  - `AWS_S3_BUCKET_NAME` (cloud storage)
  - `AUTH0_CLIENT_ID` (identity provider)

### 8.2 Placeholder Convention

All sensitive values use placeholders: `{{ SERVICE_KEY_TYPE }}`  
**Never commit real secrets to version control.**

### 8.3 Updating This Document

- **Owner:** DevOps & Infrastructure Team
- **Review Frequency:** Quarterly (or after any major integration change)
- **Change Process:**
  1. Create a branch: `feature/update-integrations-{{ DATE }}`
  2. Edit this file with new integration details
  3. Submit PR with changes
  4. At least 1 approval from team lead required
  5. Merge and redeploy documentation site
- **Notification:** Slack announcement in #ops-team after updates

---

**Last Updated:** October 5, 2026  
**Version:** 1.0  
**Status:** Production-Ready

---
