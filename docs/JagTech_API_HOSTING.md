# JagTech API Hosting & Deployment

## 1. Purpose

Standard hosting and deployment architecture for JagTech APIs.

**Primary domain:** `https://jagtech.in`  
**API domain:** `https://api.jagtech.in`

### Target stack
- ASP.NET Core / .NET LTS
- PostgreSQL
- Linux VPS / Ubuntu LTS
- Docker + Docker Compose
- Nginx
- Cloudflare
- GitHub + GitHub Actions

The architecture prioritizes low cost, easy maintenance, centralized hosting, and gradual scaling.

## 2. Architecture

```text
Internet
   |
Cloudflare
   |
Nginx
   |
Linux VPS
   |
Docker
   |
+---------------------------+
| ASP.NET Core API          |
| PostgreSQL                |
| Other JagTech Services    |
+---------------------------+
```

Mobile application flow:

```text
Flutter Android App
        |
        | HTTPS
        v
https://api.jagtech.in
        |
        v
ASP.NET Core API
        |
        v
PostgreSQL
```

## 3. Domain Structure

| Purpose | Domain |
|---|---|
| Main website | `https://jagtech.in` |
| WWW | `https://www.jagtech.in` |
| API | `https://api.jagtech.in` |
| Web app | `https://app.jagtech.in` |
| Administration | `https://admin.jagtech.in` |
| Documentation | `https://docs.jagtech.in` |
| Status | `https://status.jagtech.in` |
| Development | `https://dev.jagtech.in` |
| Staging | `https://staging.jagtech.in` |

Create only the subdomains actually required.

## 4. Hosting

Preferred production environment:

- Ubuntu LTS
- Docker
- Docker Compose
- Nginx
- PostgreSQL
- Cloudflare
- GitHub Actions

**IIS/Windows hosting is not required.**

## 5. PostgreSQL

Keep PostgreSQL on a private Docker network whenever possible.

```text
API Container
     |
     | private Docker network
     v
PostgreSQL Container
```

Rules:
- Do not expose PostgreSQL publicly unless specifically required.
- Use strong credentials.
- Use separate databases where appropriate.
- Maintain backups.
- Test database restores.
- Apply migrations in a controlled deployment process.

## 6. Docker

Use multi-stage ASP.NET Core builds:

```text
SDK image
    |
    | build
    v
Published application
    |
    v
ASP.NET runtime image
```

Keep production images minimal.

Do not introduce Redis, Kafka, RabbitMQ, Elasticsearch, Kubernetes, or microservices unless a real requirement justifies them.

## 7. Nginx

Nginx is the public reverse proxy.

```text
Client
  |
HTTPS
  |
Nginx
  |
  +----> API container
  +----> Web application container
```

Typical routing:

```text
api.jagtech.in       -> API
app.jagtech.in       -> Web App
admin.jagtech.in     -> Admin App
docs.jagtech.in      -> Documentation
```

## 8. Cloudflare

Use Cloudflare for:
- DNS
- HTTPS
- Basic edge security
- WAF where appropriate
- DDoS protection

Do not expose infrastructure unnecessarily.

## 9. ASP.NET Core Configuration

Production secrets must not be committed to Git.

Use environment variables or secure deployment configuration, for example:

```text
ASPNETCORE_ENVIRONMENT=Production
ConnectionStrings__Default=...
Jwt__Key=...
Jwt__Issuer=...
Jwt__Audience=...
```

Maintain separate Development, Staging, and Production configuration.

## 10. CORS

Allow only required frontend origins, for example:

```text
https://jagtech.in
https://www.jagtech.in
https://app.jagtech.in
https://admin.jagtech.in
```

Avoid unrestricted production CORS for authenticated/sensitive APIs.

## 11. Authentication and Authorization

Production APIs must enforce authorization server-side.

Use appropriate:
- HTTPS
- JWT or equivalent authentication
- Refresh-token rotation where applicable
- Secure password hashing
- Role/permission authorization
- Input validation
- Rate limiting where appropriate
- Secure error handling

Never rely only on frontend authorization.

## 12. API Versioning

Prefer versioned routes for mobile/public APIs:

```text
https://api.jagtech.in/api/v1/auth
https://api.jagtech.in/api/v1/products
https://api.jagtech.in/api/v1/orders
```

Maintain backward compatibility because mobile users do not update simultaneously.

## 13. Health Checks

Every production API should expose a health endpoint:

```text
GET /health
```

Use it for deployment validation, monitoring, container health checks, and troubleshooting.

## 14. Logging

Use structured production logging.

Useful fields:
- Correlation ID
- Timestamp
- HTTP method
- Endpoint
- Status code
- Exception details where appropriate
- Application/service name

Never log passwords, OTPs, access tokens, refresh tokens, or sensitive personal information.

## 15. File Storage

Do not rely on local container storage for important persistent files.

Use a storage abstraction such as:

```text
IFileStorage
```

This permits future migration to object storage without rewriting business logic.

## 16. CI/CD

Recommended pipeline:

```text
Developer
    |
GitHub
    |
GitHub Actions
    |
    +--> Restore
    +--> Build
    +--> Test
    +--> Publish
    +--> Docker build
    +--> Deploy
    |
JagTech VPS
    |
Health Check
```

## 17. API Deployment

1. Push code to GitHub.
2. Restore/build/test.
3. Build the Docker image.
4. Deploy to the VPS.
5. Apply required database migrations in a controlled way.
6. Replace/restart the API container.
7. Verify `https://api.jagtech.in/health`.
8. Review logs.

## 18. Database Migrations

Preferred flow:

```text
Development
   |
Migration
   |
Testing
   |
Staging
   |
Production
```

Take a backup before high-risk production migrations.

## 19. Backups

Back up:
- PostgreSQL
- Important uploaded files
- Required configuration
- Other non-recreatable production data

Store backups separately from production. Test restoration periodically.

## 20. VPS Security

Recommended:
- SSH key authentication
- Restricted SSH access
- Firewall
- Security updates
- Strong credentials
- Non-root deployment where practical
- Minimal exposed ports

Typical public ports:

```text
80    HTTP
443   HTTPS
22    SSH
```

Do not normally expose PostgreSQL port `5432`.

## 21. Multi-Application Hosting

One JagTech VPS can host multiple applications:

```text
VPS
 |
 +-- JagTech API
 +-- Retail API
 +-- MolBhav API
 +-- Future APIs
 +-- Web applications
 +-- PostgreSQL databases
```

Nginx routes traffic by domain/subdomain and Docker isolates applications.

## 22. Scaling

Start simple:

```text
1 VPS
+ Docker
+ Nginx
+ PostgreSQL
```

Scale only when required. Future options include multiple API instances, load balancing, external/managed PostgreSQL, object storage, and additional servers.

Do not introduce Kubernetes or microservices merely for future-proofing.

## 23. Development vs Production

```text
Development -> localhost
Staging     -> https://staging.jagtech.in
Production  -> https://api.jagtech.in
```

Mobile applications must never use `localhost` as their production API endpoint.

## 24. Swagger / OpenAPI

Recommended:
- Development: enabled
- Staging: protected
- Production: protected or disabled

## 25. Claude / Copilot Rules

When modifying a JagTech API:

1. Inspect existing code before changing it.
2. Understand the current architecture.
3. Make a focused plan.
4. Modify only required files.
5. Do not perform unrelated refactoring.
6. Preserve existing API contracts unless a breaking change is explicitly required.
7. Do not introduce infrastructure without justification.
8. Validate compilation.
9. Run relevant tests.
10. Validate database/API changes.
11. Report exactly what changed.
12. Report validation results and remaining risks.

## 26. Core Principle

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

> **JagTech: Build once. Deploy cleanly. Host centrally. Scale when needed.**
