# MolBhav API

Backend for **MolBhav — Market & Procurement Intelligence** (Flutter app, Android/iOS).
.NET 10 · Clean Architecture modular monolith · PostgreSQL · CQRS (MediatR) · EF Core (writes) + Dapper (reads).

## Solution layout

```
MolBhav.sln
├── Directory.Build.props        net10.0, nullable, analyzers, XML docs
├── Directory.Packages.props     Central Package Management (all versions here)
├── docker-compose.yml           local PostgreSQL 17
└── src/
    ├── MolBhav.Domain           entities, value objects, domain events, Result/Error — no dependencies
    │   ├── Common/              Entity, AggregateRoot, ValueObject, DomainEvent, IAuditableEntity, ISoftDeletable, Result
    │   └── SharedKernel/        Money, PhoneNumber (+91 E.164), LanguageCode
    ├── MolBhav.Application      use cases — depends on Domain only
    │   ├── Abstractions/        ICommand/IQuery + handlers, IUnitOfWork, IRepository, ICurrentUser,
    │   │                        IJwtTokenService, ILanguageContext, IDomainEventHandler
    │   ├── Common/              pipeline behaviours, application exceptions, paging models
    │   └── Features/<Module>/<UseCase>/   one folder per command/query (request, handler, validator, DTO)
    ├── MolBhav.Infrastructure   EF Core, Dapper, JWT, outbox — implements Application interfaces
    │   ├── Persistence/         MolBhavDbContext (IUnitOfWork), Schemas, snake_case convention,
    │   │                        interceptors (soft delete → audit → outbox), Repository base, Dapper connection factory
    │   ├── Messaging/           transactional outbox + processor + dispatcher
    │   └── Authentication/      JwtOptions, JwtTokenService (HS256 access + hashed opaque refresh)
    └── MolBhav.Api              HTTP only — thin controllers
        ├── Controllers/V{n}/    versioned controllers on ApiControllerBase
        ├── Contracts/           ApiResponse<T> envelope
        ├── ErrorHandling/       GlobalExceptionHandler → RFC 7807
        ├── Setup/               versioning, authz, rate limiting, CORS, localization, proxy, OpenAPI
        └── Middleware/          security headers
```

Dependency flow is strictly inward: `Api → Application → Domain`, `Infrastructure → Application → Domain`; `Api` references `Infrastructure` only for composition in `Program.cs`.

## Modules (PostgreSQL schemas)

One database, one schema per module. Modules never write into another module's schema.

| Schema | Owns (BRD §19) |
|---|---|
| `identity` | Users, UserProfiles, OTP challenges, RefreshTokens |
| `billing` | Plans, Subscriptions, Entitlements |
| `catalog` | ProcurementCategories, SubCategories, Products, ProductVariants, UnitsOfMeasure |
| `market` | Locations, Markets, Mandis, Suppliers, Hubs |
| `pricing` | PriceSources, PriceRecords, PriceHistory |
| `ingestion` | DataIngestionJobs, DataIngestionErrors |
| `watchlist` | Watchlists, WatchlistItems |
| `alerting` | AlertRules, Alerts |
| `procurement` | ProcurementRequirements, ProcurementOpportunities, CostComponents |
| `notification` | Notifications (push / WhatsApp) + delivery status |
| `reporting` | Reports, exports |
| `localization` | LocalizedTexts |
| `messaging` | Outbox |
| `platform` | default schema, EF migrations history |

## Request pipeline

```
HTTP → ForwardedHeaders → ExceptionHandler → HSTS/HTTPS → SecurityHeaders → Serilog → RequestLocalization
     → CORS → Authentication → RateLimiter → Authorization → Controller
     → MediatR: Logging → Validation (FluentValidation) → UnitOfWork (commands only: one DB transaction, commit on Result success)
     → Handler → Result<T> → ApiResponse<T> (2xx) | ProblemDetails (4xx/5xx)
```

## Conventions

- **Responses** — success: `{ "success": true, "data": …, "message": …, "pagination": … }`. Errors: `application/problem+json` with `errorCode` (stable, e.g. `PhoneNumber.Invalid`) and `traceId`. `Result` errors map: Validation 400 · Unauthorized 401 · Forbidden 403 · NotFound 404 · Conflict 409 · BusinessRule 422.
- **Routes** — `api/v{version}/{resource}`; declare `[ApiVersion("1.0")]` + explicit `[Route]` per controller.
- **Auth** — every endpoint requires a JWT unless marked `[AllowAnonymous]` (fallback policy). Policies: `admin`, `pro-subscriber`. Apply `[EnableRateLimiting(RateLimitPolicies.Otp)]` to OTP endpoints.
- **Language** — `Accept-Language` (en, hi, mr, gu, ta, te, kn — configurable). Read via `ILanguageContext`.
- **IDs** — UUIDv7 (`Guid.CreateVersion7()`) generated in domain factories; the database never generates keys.
- **Database naming** — snake_case everywhere, applied by convention. In configurations use `.InSchema(Schemas.X)` (not `ToTable(name, schema)`), then `.ConfigureAggregateRoot()`, `.ConfigureAuditing()`, `.ConfigureSoftDelete()` as applicable. Concurrency uses PostgreSQL `xmin`.
- **Writes vs reads** — commands load aggregates through repositories (EF Core); screen/report queries use Dapper read services in Infrastructure behind interfaces declared by the feature.
- **Domain events** — raised on aggregates, saved to the outbox in the same transaction, dispatched by `OutboxProcessor` (at-least-once → handlers must be idempotent).

## Running locally

```bash
cp .env.example .env                       # set POSTGRES_PASSWORD
docker compose up -d

cd src/MolBhav.Api
dotnet user-secrets set "ConnectionStrings:MolBhav" "Host=localhost;Port=5432;Database=molbhav;Username=molbhav;Password=<POSTGRES_PASSWORD>"
dotnet user-secrets set "Jwt:SigningKey" "<at least 32 random bytes, e.g. openssl rand -base64 48>"

cd ../..
dotnet tool install --global dotnet-ef       # once
dotnet ef migrations add InitialPlatform -p src/MolBhav.Infrastructure -s src/MolBhav.Api -o Persistence/Migrations
dotnet ef database update -p src/MolBhav.Infrastructure -s src/MolBhav.Api

dotnet run --project src/MolBhav.Api --launch-profile https
```

Check: `GET https://localhost:7040/api/v1/system/status` (see `MolBhav.Api.http`). OpenAPI (Development only): `/openapi/v1.json` — import into Postman. Health: `/health/live`, `/health/ready`.

Secrets (`ConnectionStrings:MolBhav`, `Jwt:SigningKey`) are never stored in appsettings; in production supply them as environment variables (`ConnectionStrings__MolBhav`, `Jwt__SigningKey`) or Key Vault. The app refuses to start if they are missing or the signing key is shorter than 32 bytes.

## Adding a feature (template)

1. Domain: aggregate + value objects + domain events in `MolBhav.Domain/<Module>/`.
2. Infrastructure: `IEntityTypeConfiguration` in `Persistence/Configurations/<Module>/`, repository in `Persistence/Repositories/`, Dapper read service if needed; one migration per logical change.
3. Application: `Features/<Module>/<UseCase>/` → request, handler, validator, response DTO.
4. API: action on a versioned controller returning `OkEnvelope` / `CreatedEnvelope` / `NoContentOrProblem`.

## Package notes

- **MediatR is pinned to 12.5.0**, the last Apache-2.0 release. 13.x+ requires a commercial licence key (free community tier for small companies) — upgrade deliberately.
- Asp.Versioning 8.1.0 targets .NET 8 and runs on .NET 10.
