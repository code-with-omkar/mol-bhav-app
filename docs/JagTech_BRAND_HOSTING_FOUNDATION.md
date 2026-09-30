# JagTech Brand & Hosting Foundation

## Brand

**JagTech**

**Domain:** `jagtech.in`

## Brand Meaning

JagTech can be positioned as:

> **JagTech = Jagat + Tech**

Where:

- **Jag / Jagat (जग / जगत)** = World
- **Tech** = Technology

Core idea:

> **Technology for the World**

JagTech is intended to be an umbrella technology brand rather than a single-purpose application.

## What JagTech Can Cover

- Mobile applications
- Flutter applications
- ASP.NET Core APIs
- Angular web applications
- SaaS products
- AI applications
- Automation
- Developer tools
- Cloud services
- Hosting
- APIs
- Business applications
- Future technology products

The brand should not be limited to one current product.

## Primary Domain

```text
https://jagtech.in
```

Recommended structure:

```text
jagtech.in
│
├── www.jagtech.in
├── app.jagtech.in
├── admin.jagtech.in
├── api.jagtech.in
├── docs.jagtech.in
├── status.jagtech.in
├── dev.jagtech.in
└── staging.jagtech.in
```

Create only required subdomains.

## Hosting Vision

JagTech should provide a central technology platform where multiple products can run using a common infrastructure foundation.

```text
                    jagtech.in
                        |
                    Cloudflare
                        |
                     Nginx
                        |
                    Linux VPS
                        |
                     Docker
          +-------------+-------------+
          |             |             |
        API 1         API 2        Web Apps
          |             |             |
       PostgreSQL   PostgreSQL     Frontend
```

## Standard Technology Stack

### Backend
- ASP.NET Core
- .NET LTS
- REST APIs
- Entity Framework Core where appropriate

### Database
- PostgreSQL

### Web
- Angular
- HTML/CSS/TypeScript

### Mobile
- Flutter
- Android
- Google Play

### Infrastructure
- Ubuntu LTS
- Docker
- Docker Compose
- Nginx
- Cloudflare

### Source Control / CI
- Git
- GitHub
- GitHub Actions

## Infrastructure Principle

Start with:

```text
Linux VPS
+
Docker
+
Nginx
+
PostgreSQL
+
Cloudflare
```

Add infrastructure only when real requirements justify it.

Do not introduce microservices, Kubernetes, Kafka, RabbitMQ, Redis, Elasticsearch, or similar infrastructure merely for future-proofing.

## Application Isolation

Each application should have:
- Its own deployment boundary
- Its own Docker image
- Its own configuration
- Its own database/schema strategy
- Its own logs
- Its own deployment process

Shared infrastructure must not mean shared business logic.

## Domain Convention

```text
api.jagtech.in
```
For APIs.

```text
admin.jagtech.in
```
For administration.

```text
app.jagtech.in
```
For general web applications.

```text
docs.jagtech.in
```
For documentation.

```text
status.jagtech.in
```
For service status.

## Environment Convention

```text
Development
    |
localhost

Staging
    |
staging.jagtech.in
staging-api.jagtech.in

Production
    |
jagtech.in
api.jagtech.in
```

Never use production credentials in development.

## Security Foundation

Every production application should consider:
- HTTPS
- Strong authentication
- Authorization
- Secure secret management
- Database access restrictions
- Firewall
- Backups
- Logging
- Monitoring
- Input validation
- Rate limiting where appropriate
- Security/dependency updates

## Deployment Philosophy

### API

```text
CODE -> BUILD -> TEST -> DOCKER -> DEPLOY -> HEALTH CHECK
```

### Android

```text
CODE -> BUILD -> TEST -> SIGN -> AAB -> GOOGLE PLAY
```

### Web

```text
CODE -> BUILD -> TEST -> DEPLOY -> NGINX -> CLOUDFLARE
```

## Future Scaling

### Stage 1

```text
One VPS
One PostgreSQL
Docker
Nginx
Cloudflare
```

### Stage 2

```text
More CPU/RAM
Better monitoring
Separate databases where required
External backups
```

### Stage 3

```text
Multiple application servers
Load balancing
Managed/external database
Object storage
```

### Stage 4

Introduce specialized infrastructure only when actual scale or business requirements justify it.

## Development Rules

For every JagTech project:

1. Inspect before changing.
2. Plan before implementing.
3. Make the smallest coherent change.
4. Avoid unrelated refactoring.
5. Preserve existing behavior.
6. Reuse existing architecture.
7. Add dependencies only when justified.
8. Validate the build.
9. Run relevant tests.
10. Validate the affected feature.
11. Review security implications.
12. Report changes and validation results.

## Brand Principle

> **JagTech — Technology for the World.**

The brand remains broad enough to support current applications and future technology products without requiring a company/domain rebrand.
