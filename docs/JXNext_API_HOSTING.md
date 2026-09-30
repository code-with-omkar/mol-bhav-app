# JXNext API Hosting & Deployment

## Purpose

This document defines how JXNext ASP.NET Core APIs are built, hosted, deployed, secured, and maintained.

Primary domain:

```text
https://jxnext.in
```

Default API:

```text
https://api.jxnext.in
```

Target infrastructure:

- Linux VPS / Ubuntu LTS
- Docker
- Docker Compose
- Nginx
- PostgreSQL
- Cloudflare
- GitHub
- GitHub Actions
- ASP.NET Core / .NET LTS

Do not use IIS or Windows-specific hosting dependencies.

---

## 1. Production Architecture

```text
Internet
   |
Cloudflare
   |
HTTPS
   |
Nginx
   |
ASP.NET Core API container
   |
Private Docker network
   |
PostgreSQL container
```

The API and PostgreSQL are hosted on the JXNext VPS.

PostgreSQL should normally NOT be publicly accessible.

---

## 2. Domain

Default:

```text
https://api.jxnext.in
```

API versioning:

```text
https://api.jxnext.in/api/v1/...
```

Examples:

```text
/api/v1/auth/otp/request
/api/v1/auth/otp/verify
/api/v1/products
/api/v1/orders
```

Never use localhost or a VPS IP address in production application configuration.

---

## 3. PostgreSQL

Use:

- PostgreSQL
- Npgsql
- Entity Framework Core where appropriate
- EF Core migrations

Preferred topology:

```text
ASP.NET Core
      |
Private Docker network
      |
PostgreSQL
```

Never commit production credentials.

Use environment variables/secrets such as:

```text
ConnectionStrings__DefaultConnection
```

Do not expose port 5432 publicly unless explicitly required.

---

## 4. Docker

Use multi-stage Docker builds.

```text
.NET SDK
   |
restore
   |
build
   |
test
   |
publish
   |
.NET Runtime image
```

Requirements:

- official Microsoft images
- small production image
- no secrets in image
- Linux compatible
- graceful shutdown
- non-root runtime where practical

Example services:

```text
docker-compose.yml

services:
  api:
    ...
  postgres:
    ...
```

Keep PostgreSQL on an internal Docker network.

---

## 5. Nginx

Nginx is the public reverse proxy.

```text
api.jxnext.in
      |
    Nginx
      |
ASP.NET Core container
```

Nginx can handle:

- HTTPS
- reverse proxy
- request limits
- security headers
- WebSockets when required
- compression
- routing

Do not expose internal API container ports unnecessarily.

---

## 6. Cloudflare

Use Cloudflare for:

- DNS
- SSL/TLS
- DDoS protection
- WAF/security controls where appropriate

Cloudflare does NOT replace API authentication/authorization.

---

## 7. ASP.NET Core Configuration

Support:

```text
Development
Staging
Production
```

Use:

```text
appsettings.json
appsettings.Development.json
appsettings.Staging.json
appsettings.Production.json
```

Production secrets must come from environment variables/secrets.

Configure forwarded headers correctly when behind Nginx/Cloudflare.

Do not store secrets in Git.

---

## 8. CORS

Configure explicit production origins.

Example:

```text
https://jxnext.in
https://www.jxnext.in
https://app.jxnext.in
https://admin.jxnext.in
```

Do not blindly use:

```text
AllowAnyOrigin
```

for authenticated production APIs.

Mobile applications do not use browser CORS in the same way as web applications, but the API must still have correct policies for web clients.

---

## 9. Authentication and Authorization

Security must be enforced by the API.

Use appropriate:

- authentication
- authorization
- access tokens
- refresh tokens
- token revocation
- role/permission checks
- request validation

Never rely on UI visibility as security.

Never log:

- passwords
- access tokens
- refresh tokens
- OTP values
- API keys
- database passwords

---

## 10. Health Checks

Every API should expose:

```text
GET /health
```

Optional:

```text
GET /health/live
GET /health/ready
```

Use health checks for deployment verification.

Do not expose sensitive diagnostic details.

---

## 11. Logging

Use structured logging.

Capture enough information to diagnose:

- application errors
- database failures
- authentication failures
- external service failures
- deployment issues

Never log sensitive credentials or tokens.

---

## 12. File Storage

Do not depend on container-local permanent storage.

For uploaded files, create an abstraction such as:

```text
IFileStorage
```

Possible implementations:

```text
Local storage
Object storage
Cloud storage
```

The business layer must not depend on physical server paths.

---

## 13. CI/CD

Recommended API pipeline:

```text
Developer
   |
GitHub
   |
GitHub Actions
   |
Restore
   |
Build
   |
Test
   |
Docker build
   |
Deploy to VPS
   |
Docker Compose
   |
Health check
```

Deployment should fail if required build/tests fail.

---

## 14. API Deployment

Typical deployment flow:

```text
git push
   |
GitHub Actions
   |
Build/test
   |
Build Docker image
   |
Deploy image to VPS
   |
Start/update container
   |
Health check
   |
API LIVE
```

Prefer deployment methods that minimize interruption.

Do not add Kubernetes or complex blue-green infrastructure unless traffic/availability requirements justify it.

---

## 15. Database Migrations

Before production migration:

1. Review migration.
2. Verify compatibility.
3. Back up database.
4. Apply migration.
5. Run health checks.
6. Verify important API flows.

Never automatically delete production data as part of a normal deployment.

Destructive migrations require explicit approval.

---

## 16. Backups

Production PostgreSQL requires:

- scheduled backups
- retention policy
- restore testing
- documented recovery procedure

A backup is not considered reliable until restoration has been tested.

---

## 17. VPS Security

Recommended:

- SSH key authentication
- firewall
- restricted SSH
- non-root deployment user
- security updates
- Docker updates
- monitoring
- backups
- fail2ban or equivalent where appropriate

Typical public ports:

```text
80
443
```

PostgreSQL should remain private.

---

## 18. Multiple JXNext Applications

The VPS may host multiple applications.

Example:

```text
JXNext VPS
|
+-- Nginx
|
+-- App 1 API
+-- App 2 API
+-- App 3 API
|
+-- PostgreSQL
```

Applications must be isolated through Docker services/networks/configuration.

Avoid creating a separate VPS for every small application unless required.

---

## 19. Development vs Production

Development:

```text
http://localhost:xxxx
local PostgreSQL
```

Production:

```text
https://api.jxnext.in
Cloudflare
Nginx
Docker
PostgreSQL
```

Never make production dependent on a developer machine.

---

## 20. Claude/Copilot Rules

Before changing API/infrastructure code:

1. Inspect existing architecture.
2. Inspect Docker/deployment configuration.
3. Inspect database impact.
4. Inspect environment configuration.
5. Create a short plan.
6. Avoid unrelated refactoring.

During implementation:

- keep Linux compatible
- keep PostgreSQL compatible
- keep Docker compatible
- avoid IIS/Windows dependencies
- do not hardcode secrets
- do not introduce unnecessary infrastructure

After implementation:

Validate:

```text
Build
Tests
Docker build
Configuration
Database migration impact
Health endpoint
Deployment impact
```

Report:

```text
Changed
Validated
Potential Risks
Deployment Notes
```

---

## 21. Core API Principle

```text
BUILD
  ↓
TEST
  ↓
CONTAINERIZE
  ↓
DEPLOY
  ↓
HEALTH CHECK
  ↓
SERVE
```

JXNext API hosting should remain simple, secure, repeatable, and ready for future scaling.
