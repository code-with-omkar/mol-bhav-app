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
| `identity` | ✅ `users` (+ profile columns), `user_categories`, `otp_challenges`, `refresh_tokens` |
| `billing` | Plans, Subscriptions, Entitlements |
| `catalog` | ✅ `procurement_categories`, `sub_categories`, `products`, `product_variants`, `units_of_measure` + a `*_translations` table each |
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
# user-secrets load only in Development; dotnet-ef defaults to Production without this
export ASPNETCORE_ENVIRONMENT=Development    # PowerShell: $env:ASPNETCORE_ENVIRONMENT = "Development"
dotnet ef database update -p src/MolBhav.Infrastructure -s src/MolBhav.Api      # applies all pending migrations

dotnet run --project src/MolBhav.Api --launch-profile https
```

Check: `GET https://localhost:7040/api/v1/system/status` (see `MolBhav.Api.http` — it scripts the whole login → onboarding → refresh flow). OpenAPI (Development only): `/openapi/v1.json` — import into Postman. Health: `/health/live`, `/health/ready`.

Secrets (`ConnectionStrings:MolBhav`, `Jwt:SigningKey`) are never stored in appsettings; in production supply them as environment variables (`ConnectionStrings__MolBhav`, `Jwt__SigningKey`) or Key Vault. The app refuses to start if they are missing or the signing key is shorter than 32 bytes.

## Migrations

| Migration | Adds |
|---|---|
| `InitialPlatform` | `platform` history table, `messaging.outbox_messages` |
| `AddIdentityModule` | `identity` schema: `users`, `user_categories`, `otp_challenges`, `refresh_tokens` |
| `AddUserRole` | `identity.users.role` (existing users backfilled to `User`) |
| `AddCatalogModule` | `catalog` schema (10 tables), `pg_trgm` extension, trigram index for product search |
| `SeedCatalogReferenceData` | 13 units, 2 categories, 7 sub-categories, 21 products, 7 variants — names in en/hi/mr, deterministic ids |
| `LinkUserCategoriesToCatalog` | FK `identity.user_categories.category_code` → `catalog.procurement_categories.code` (drops selections matching no category first) |

New change: `dotnet ef migrations add <DescriptiveName> -p src/MolBhav.Infrastructure -s src/MolBhav.Api -o Persistence/Migrations` (with `ASPNETCORE_ENVIRONMENT=Development`). One migration per logical change.

## Identity module (login + onboarding screens)

| Screen | Endpoint | Auth | Rate limit |
|---|---|---|---|
| Login — send code | `POST /api/v1/auth/otp/request` `{ phoneNumber }` | anonymous | `otp` 5 / 10 min / IP + 60 s per-number cooldown |
| Login — enter code | `POST /api/v1/auth/otp/verify` `{ phoneNumber, code }` → `{ session, isNewUser, isOnboarded }` | anonymous | `otp-verify` 15 / 10 min / IP + 5 attempts per code |
| (silent) | `POST /api/v1/auth/token/refresh` `{ refreshToken }` → `session` | anonymous | global |
| Settings — log out | `POST /api/v1/auth/logout` `{ refreshToken }` → 204 | bearer | global |
| Profile | `GET /api/v1/profile` | bearer | global |
| Onboarding / edit profile | `PUT /api/v1/profile` `{ businessType, state, district, preferredLanguage, categories[] }` | bearer | global |

**Mobile client contract**
- After verify: `isOnboarded = false` → onboarding screen; otherwise home. (`isNewUser` alone is not enough — a user can register and quit before onboarding.)
- Store both tokens in `flutter_secure_storage`. The refresh token is **single-use**: always replace the stored one.
- On `401` from any API call → refresh once, retry. Refresh `401` → clear tokens, go to login. Refresh `409 RefreshToken.Superseded` → a parallel refresh already rotated it; retry with the stored token. Serialise refreshes in Dio (`QueuedInterceptor`) to avoid this entirely.
- OTP endpoints never return `401` (it would trigger the refresh interceptor): wrong code `400 Otp.Incorrect`; expired/used/locked `422` → offer "resend".
- A changed `preferredLanguage` reaches the JWT `lang` claim on the next refresh.

**Design decisions**
- **Wrong OTP / reused refresh token are committed `Result.Success` with an `Outcome`**, and the controller maps the outcome to 4xx. `UnitOfWorkBehavior` commits only on success, and these "failures" must persist state (attempt counter; family revocation) or the protection is void. Verified end-to-end.
- **Refresh-token rotation with reuse detection** (OWASP ASVS 3.3): a rotated-away token presented again revokes the whole family — except within a 30 s grace window (parallel refresh from the same app → `409`, nothing revoked).
- **OTP delivery is synchronous, not via the outbox**: the outbox persists payloads, and this one would contain the plaintext code. `OtpDelivery:Provider = Log` prints codes to the console and is refused at startup outside Development — **production will not start until a real SMS/WhatsApp provider is added** (fail-closed by design).
- Plaintext OTPs and refresh tokens are never stored — SHA-256 only (OTP salted with the phone number).
- Single-value value objects (`PhoneNumber`, `LanguageCode`) map via value converters (indexable, `u.PhoneNumber == phone` translates); multi-value ones (`Money`) stay EF complex types.
- Identity tables have pinned plural names: `user` is reserved in PostgreSQL.
- User categories are FK-bound to the catalog (see Catalog module); state/district stay free text until the Market module's location master exists.

## Catalog module (Select Category screen, product pickers, admin)

| Who | Endpoint |
|---|---|
| App | `GET /api/v1/catalog/categories` — categories + sub-categories (Select Category screen) |
| App | `GET /api/v1/catalog/categories/{code}/products?subCategoryId&search&page&pageSize` — paged; search matches any language |
| App | `GET /api/v1/catalog/products/{id}` — name, category, default unit, variants |
| App | `GET /api/v1/catalog/units` — units with conversion factors |
| Admin | `GET/POST /api/v1/admin/catalog/categories`, `PUT …/categories/{id}`, `POST …/categories/{id}/sub-categories`, `PUT …/sub-categories/{subId}` |
| Admin | `GET/POST /api/v1/admin/catalog/units`, `PUT …/units/{id}` |
| Admin | `GET/POST /api/v1/admin/catalog/products`, `GET/PUT …/products/{id}`, `POST …/products/{id}/variants`, `PUT …/variants/{variantId}` |

- **Names are data, per language**: every item has its own translation table (owner id + language as key, FK-bound). Reads resolve `Accept-Language` → configured default → English; English is mandatory on every item. Admin input is limited to the enabled languages (`Localization:SupportedLanguages`).
- **Nothing is deleted** — items are deactivated (`isActive: false`); inactive items vanish from the app (a product also vanishes when its sub-category or category is inactive) but stay visible to admins. Prices and user selections keep referencing them.
- **Immutable after creation**: all codes (other modules and ingestion reference them), and a unit's dimension and conversion factor (recorded prices depend on them — a correction is a new unit).
- **Units** carry a factor to their dimension's base (mass → kg, volume → m³, count → piece, length → m, area → m²): quintal = 100, 50 kg bag = 50, brass = 2.831685 m³. `UnitOfMeasure.ConversionFactorTo` converts within a dimension; the pricing module will normalise to each product's default unit.
- **Onboarding is now catalog-validated**: `PUT /profile` rejects unknown or inactive categories (`ProcurementCategory.NotFound`), and the database FK enforces the same.
- **Seed translations** (hi/mr) were written for this seed — have a native speaker review them in the admin portal; gu/ta/te/kn fall back to English until added.
- **Admin PUTs are full replacements**; `isActive` (and a unit's `dimension`/`toBaseFactor` on create) are required rather than defaulted, so a client that omits them cannot deactivate an item by accident.

### Granting admin

There is deliberately no API to become admin. Grant it in the database, then log in again (the role is read into the token at login/refresh):

```sql
UPDATE identity.users SET role = 'Admin' WHERE phone_number = '+919876543210';
```

## Adding a feature (template)

1. Domain: aggregate + value objects + domain events in `MolBhav.Domain/<Module>/`.
2. Infrastructure: `IEntityTypeConfiguration` in `Persistence/Configurations/<Module>/`, repository in `Persistence/Repositories/`, Dapper read service if needed; one migration per logical change.
3. Application: `Features/<Module>/<UseCase>/` → request, handler, validator, response DTO.
4. API: action on a versioned controller returning `OkEnvelope` / `CreatedEnvelope` / `NoContentOrProblem`.

## Package notes

- **MediatR is pinned to 12.5.0**, the last Apache-2.0 release. 13.x+ requires a commercial licence key (free community tier for small companies) — upgrade deliberately.
- Asp.Versioning 8.1.0 targets .NET 8 and runs on .NET 10.
