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
| `billing` | ✅ `plans`, `subscriptions` |
| `catalog` | ✅ `procurement_categories`, `sub_categories`, `products`, `product_variants`, `units_of_measure` + a `*_translations` table each |
| `market` | ✅ `states`, `districts`, `mandis`, `suppliers` |
| `pricing` | ✅ `price_sources`, `price_records` (unified record-as-history — see Pricing module) |
| `ingestion` | ✅ `ingestion_jobs`, `ingestion_errors` |
| `watchlist` | ✅ `watchlist_items` (no separate "Watchlist" aggregate) |
| `alerting` | ✅ `alert_rules`, `alerts` |
| `procurement` | ✅ `procurement_requirements`, `procurement_opportunities`, `cost_components` |
| `notification` | ✅ `notifications` |
| `reporting` | ✅ `reports`, `report_files` |
| `localization` | ✅ `localized_text_entries`, `localized_text_values` |
| `support` | ✅ `support_tickets`, `support_ticket_messages` |
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
| `AddMarketModule` | `market` schema: `states`, `districts` (owned by state), `mandis`, `suppliers` (both reference a district) |
| `AddPricingWatchlistModules` | `pricing` schema: `price_sources`, `price_records` (check constraint enforcing the mandi-xor-supplier location); `watchlist` schema: `watchlist_items` |
| `AddAlertingProcurementNotificationReportingBillingModules` | `alerting` (`alert_rules`, `alerts`), `procurement` (`procurement_requirements`, `procurement_opportunities`, `cost_components`), `notification` (`notifications`), `reporting` (`reports`), `billing` (`plans`, `subscriptions`) |
| `AddIngestionModule` | `ingestion` schema: `ingestion_jobs`, `ingestion_errors` |
| `AddLocalizationModule` | `localization` schema: `localized_text_entries`, `localized_text_values` |
| `SeedMarketDistrictData` | 784 districts across all states/UTs |
| `AddPriceRecordLocationDateIndexes` | replaces `price_records` `mandi_id`/`supplier_id` indexes with partial `(mandi_id, record_date DESC)` / `(supplier_id, record_date DESC)` `WHERE NOT is_voided` for browse-by-mandi |
| `AddUserDisplayName` | nullable `identity.users.display_name varchar(60)` — the name entered in onboarding / edit profile |
| `AddReportFiles` | `reporting.report_files` (report_id PK/FK cascade, file_name, content_type, size_bytes, content `bytea`) |
| `AddAlertRulePriceThreshold` | `alerting.alert_rules.threshold_price numeric(14,2)`, `threshold_percent` made nullable, check constraint `ck_alert_rules_threshold` (percent types carry a percent, price types a price — never both) |
| `AddReportLastDownloadedAt` | nullable `reporting.reports.last_downloaded_at_utc` — stamped on each successful owner download |
| `AddSupportModule` | `support` schema: `support_tickets`, `support_ticket_messages` (cascade from the ticket); `(user_id, last_activity_at_utc DESC)` and `(status, last_activity_at_utc DESC)` indexes |
| `SeedSupportFaq` | 10 FAQ Q&A pairs under `support.faq.{n}.q`/`.a` plus `support.reply.title`/`.body` in `localization` (en/hi/mr), fixed ids, one sentinel `created_by` so `Down` is exact |

New change: `dotnet ef migrations add <DescriptiveName> -p src/MolBhav.Infrastructure -s src/MolBhav.Api -o Persistence/Migrations` (with `ASPNETCORE_ENVIRONMENT=Development`). One migration per logical change.

## Identity module (login + onboarding screens)

| Screen | Endpoint | Auth | Rate limit |
|---|---|---|---|
| Login — send code | `POST /api/v1/auth/otp/request` `{ phoneNumber }` | anonymous | `otp` 5 / 10 min / IP + 60 s per-number cooldown |
| Login — enter code | `POST /api/v1/auth/otp/verify` `{ phoneNumber, code }` → `{ session, isNewUser, isOnboarded }` | anonymous | `otp-verify` 15 / 10 min / IP + 5 attempts per code |
| (silent) | `POST /api/v1/auth/token/refresh` `{ refreshToken }` → `session` | anonymous | global |
| Settings — log out | `POST /api/v1/auth/logout` `{ refreshToken }` → 204 | bearer | global |
| Profile | `GET /api/v1/profile` — `displayName` (null until set), stored values plus `businessTypeCode`, `stateId`/`stateCode`/`stateName`, `districtId`/`districtName` (matched against the market master) and `categoryDetails` (names in `Accept-Language`) | bearer | global |
| Onboarding / edit profile | `PUT /api/v1/profile` `{ displayName, businessType, state, district, preferredLanguage, categories[] }` | bearer | global |

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

## Market module (location/mandi/supplier pickers, admin)

| Who | Endpoint |
|---|---|
| App | `GET /api/v1/market/states` — active states |
| App | `GET /api/v1/market/states/{stateId}/districts` — active districts of a state |
| App | `GET /api/v1/market/mandis?districtId&search&page&pageSize` — agriculture pricing locations (BRD §11) |
| App | `GET /api/v1/market/suppliers?districtId&search&page&pageSize` — construction regional suppliers/hubs (BRD §12) |
| Admin | `GET/POST /api/v1/admin/market/states`, `PUT …/states/{id}`, `POST …/states/{id}/districts`, `PUT …/states/{id}/districts/{districtId}` |
| Admin | `GET/POST /api/v1/admin/market/mandis`, `PUT …/mandis/{id}` |
| Admin | `GET/POST /api/v1/admin/market/suppliers`, `PUT …/suppliers/{id}` |

- **No per-language translations yet** (unlike Catalog): state/district/mandi/supplier names are plain strings. Add a translation table later, following `CatalogTranslationMapping.OwnsTranslations`, if the app needs localized market names.
- **District is owned by State** (same shape as Catalog's `SubCategory`/`ProcurementCategory`); mandis and suppliers are their own aggregates referencing a district by id, following `Product`/`SubCategory`.
- **Nothing is deleted** — deactivated only; mandis/suppliers will carry price history once the Pricing module exists.
- **Codes are immutable** (`states.code`, `mandis.code`, `suppliers.code`) — ingestion adapters map source location names onto them.

## Pricing module (comparison/trend screens, manual price entry, admin)

| Who | Endpoint |
|---|---|
| App | `GET /api/v1/pricing/latest?productId&locationKind&districtId&page&pageSize` — comparison matrix: latest non-voided price per mandi/supplier (BRD §10) |
| App | `GET /api/v1/pricing/latest-by-location?locationKind&locationId&page&pageSize` — browse by mandi: latest non-voided price per product/variant at one mandi/supplier, last 30 days, names in `Accept-Language` |
| App | `GET /api/v1/pricing/history?productId&locationKind&locationId&fromDate&toDate` — trend sparkline for one location (BRD §11/§12) |
| Admin | `GET/POST /api/v1/admin/pricing/sources`, `PUT …/sources/{id}` |
| Admin | `GET /api/v1/admin/pricing/records?productId&locationKind&locationId&fromDate&toDate&isVoided&page&pageSize` |
| Admin | `POST /api/v1/admin/pricing/records` — manual price entry (the path the future Ingestion module will also call) |
| Admin | `POST /api/v1/admin/pricing/records/{id}/void` — marks voided, never deleted |

- **PriceRecords *is* PriceHistory** (BRD §19 collapsed to one table): a price record already is a point of history, so there is no separate history table to keep in sync — recording a new price is the only write, and nothing is ever updated in place.
- **Location is two nullable FKs + a `LocationKind` discriminator** (`MandiId`/`SupplierId`), not one polymorphic FK — Postgres/EF can't express a conditional FK to one of two different tables. A DB check constraint (`ck_price_records_location`) enforces exactly one is set, matching the kind.
- **Duplicate prevention is an application-layer pre-check only** (`IPriceRecordRepository.DuplicateExistsAsync`) — nullable variant/mandi/supplier columns mean a plain Postgres unique index would treat NULLs as always-distinct and miss real duplicates. A proper idempotency key per source is deferred to the Ingestion module.
- **Records are voided, never deleted** — `IsVoided` flag; voided records disappear from mobile comparison/trend reads but stay in the admin list and in history.
- **Price sources have plain string codes** (like `market.states`), not a formal value object — ingestion adapters key off them; the code is immutable after creation.

## Watchlist module (smart commodity watchlist)

| Who | Endpoint |
|---|---|
| App | `GET /api/v1/watchlist` — the signed-in user's watched products/variants, localized like the catalog product list |
| App | `POST /api/v1/watchlist` `{ productId, variantId? }` → 201 |
| App | `DELETE /api/v1/watchlist/{id}` → 204 |

- **No separate "Watchlist" aggregate** — a user's watched items are simply their `WatchlistItem` rows, one per product/variant, spanning every enabled procurement category (BRD §7).
- **Hard-deleted, unlike every other module so far** — a watchlist entry carries no history worth keeping, so `RemoveFromWatchlist` actually deletes the row rather than deactivating it.
- Adding validates the variant belongs to the product (same check `RecordPrice` does), and a friendly pre-check returns `409 WatchlistItem.AlreadyWatched` before the DB round-trip.

## Alerting module (price threshold alerts)

| Who | Endpoint |
|---|---|
| App | `GET /api/v1/alert-rules` — the signed-in user's alert rules |
| App | `POST /api/v1/alert-rules` `{ productId, variantId?, locationKind?, mandiId?, supplierId?, thresholdType, thresholdPercent? \| thresholdPrice? }` → 201 |
| App | `PUT /api/v1/alert-rules/{id}` `{ thresholdPercent? \| thresholdPrice?, isActive }`, `DELETE /api/v1/alert-rules/{id}` |
| App | `GET /api/v1/alerts?isRead&page&pageSize` — triggered alerts, newest first |
| App | `POST /api/v1/alerts/{id}/read` — marks read |

- **Driven entirely by the outbox**: every `PriceRecordedDomainEvent` (raised when `PriceRecord.Create` runs) is picked up by `EvaluateAlertRulesHandler`, which loads active rules for that product, compares the new modal price with the previous record for the same location, and creates an `Alert` for each rule whose threshold is crossed. No polling job.
- **Two families of threshold**, split by `AlertThresholdType` and enforced in `AlertRule.ValidateThreshold` plus the `ck_alert_rules_threshold` check constraint — a rule carries exactly one of the two:
  - `PriceDrop` / `PriceSpike` use `thresholdPercent` (0, 100]: the percent move against the previous price at that location.
  - `PriceBelow` / `PriceAbove` use `thresholdPrice` (rupees) and fire **on the crossing only** — `PriceBelow` needs the new modal ≤ the level *and* the previous modal above it, `PriceAbove` mirrors it. A price that lingers past the level alerts once, not every day.
- **`Alert` raises `AlertTriggeredDomainEvent`**, consumed by the Notification module (see below) — this is the first cross-module event chain (Pricing → Alerting → Notification), confirmed live.
- **Rules are hard-deleted** (like `WatchlistItem`) — no history worth keeping. **Alerts are never deleted** — they're the user's history of what fired.
- FKs to `Product`/`ProductVariant`/`Mandi`/`Supplier` are `Restrict` (reference data outlives a rule); `Alert → AlertRule` is `Restrict` too (an alert survives its rule being deleted).

## Procurement module (buy-side cost/opportunity engine)

| Who | Endpoint |
|---|---|
| App | `GET /api/v1/procurement/requirements` — the signed-in user's requirements |
| App | `POST /api/v1/procurement/requirements` `{ productId, unitId, quantity, targetPrice? }` → 201 |
| App | `DELETE /api/v1/procurement/requirements/{id}` |
| App | `POST /api/v1/procurement/requirements/{id}/opportunities` — (re)computes and persists opportunities against current price data |
| App | `GET /api/v1/procurement/requirements/{id}/opportunities` — the persisted snapshot (cheapest first) |
| Admin | `GET/POST /api/v1/admin/procurement/cost-components`, `PUT …/cost-components/{id}` |

- **`ProcurementOpportunity` is a denormalized snapshot**, not a live view — `LocationKind`/`LocationId`/`LocationName`/`UnitPrice`/`PriceRecordDate` are copied at compute time with no FK back to the mandi/supplier/price record, so "what we saw then" survives the underlying price changing later. Recomputing overwrites the snapshot for that requirement.
- **`ComputeOpportunitiesCommandHandler` reuses `IPricingReadService.GetLatestPricesAsync`** (same query the comparison screen uses) rather than duplicating it, then layers active `CostComponent`s (freight, loading, admin fee — percentage or fixed, admin-configurable) on top of the raw price to get `EstimatedCost`, and keeps the top 10 cheapest.
- **`ProcurementRequirement.UnitId` must exactly equal the product's default unit** — cross-unit conversion via `IUnitOfMeasure.ConversionFactorTo` is deliberately deferred (BRD §25 future landed-cost/logistics modelling); the handler rejects a mismatched unit rather than silently converting.
- **Requirements are hard-deleted** (no history worth keeping); **opportunities cascade** when their requirement is deleted.

## Notification module (data model + admin CRUD; send logic stubbed)

| Who | Endpoint |
|---|---|
| App | `GET /api/v1/notifications?page&pageSize` — the signed-in user's notifications, newest first |
| Admin | `GET /api/v1/admin/notifications?userId&channel&status&page&pageSize` |

- **`NotificationMessage`** (named to avoid colliding with the `MolBhav.Domain.Notification` namespace) denormalizes its content at creation — no FK back to the triggering alert/report/etc., so it reads correctly even if the source is later changed or removed.
- **Two domain-event handlers create notifications today**: `WelcomeNotificationHandler` (on `UserRegisteredDomainEvent`) and `AlertNotificationHandler` (on `AlertTriggeredDomainEvent`, from the Alerting module above).
- **`INotificationSender` is stubbed** (`LoggingNotificationSender` — logs and always reports success). Wire up a real push/WhatsApp provider behind this interface to go live; no other code needs to change.

## Reporting module (data model + admin CRUD; generation stubbed)

| Who | Endpoint |
|---|---|
| App | `POST /api/v1/reports` `{ reportType, format, parameters? }` → 201. `WeeklySummary`+`Pdf` (`fromDate`, `toDate`, `language`) or `PriceHistory`+`Csv` (Pro; `productId`, optional `mandiId`, `fromDate`, `toDate`, `language`). Dates `yyyy-MM-dd`, default last 7 days; language defaults to `Accept-Language` |
| App | `GET /api/v1/reports/{id}` — status (`Pending` → `Ready` / `Failed`) |
| App | `GET /api/v1/reports/{id}/download` — the file (`Content-Disposition: attachment`); 409 `Report.NotReady` while pending/failed |
| App | `GET /api/v1/reports?page&pageSize` |
| Admin | `GET /api/v1/admin/reports?userId&status&page&pageSize` |

- **`Report.Create` raises `ReportRequestedDomainEvent`**; `GenerateReportHandler` (an outbox-dispatched handler, calling `IUnitOfWork.SaveChangesAsync()` itself) calls `IReportGenerator` and marks the report `Ready` or `Failed` from the outcome.
- **Reports render for real** (`ReportGenerator`): `WeeklySummary` as PDF (QuestPDF, Community licence; embedded Noto Sans + Devanagari/Gujarati/Tamil/Telugu/Kannada, labels in the requested language) and `PriceHistory` as CSV (UTF-8 BOM, Pro only). Files live in `reporting.report_files` (`bytea`); `GET /reports/{id}/download` streams them to the owner. Other type/format pairs are rejected with `Report.Unsupported`.
- **Download is a command, not a query** (`DownloadReportCommand`) — serving the file also stamps `LastDownloadedAtUtc` on the report in the same transaction, so the app can show the user when they last pulled it. `requestedAtUtc` / `completedAtUtc` / `lastDownloadedAtUtc` all come back on `ReportResponse`.

## Billing module (data model + admin CRUD; payment stubbed)

| Who | Endpoint |
|---|---|
| App | `GET /api/v1/billing/plans` — active plans |
| App | `POST /api/v1/billing/subscribe` `{ planId }` → 201; charges via `IPaymentGateway`, creates the `Subscription`, flips `User.SubscriptionTier` to `Pro` — all one transaction |
| App | `GET /api/v1/billing/subscription` — the signed-in user's subscription (`404 Subscription.NotFound` if none) |
| App | `POST /api/v1/billing/subscription/cancel` |
| Admin | `GET/POST /api/v1/admin/billing/plans`, `PUT …/plans/{id}` |
| Admin | `GET /api/v1/admin/billing/subscriptions?userId&status&page&pageSize` |
| Admin | `POST /api/v1/admin/billing/subscriptions/{id}/expire` |

- **`IPaymentGateway` is stubbed** (`StubPaymentGateway`) and, unlike the Notification/Reporting stubs, **always succeeds** with a synthetic `STUB-{guid}` transaction reference — by design, so the subscribe flow is fully exercisable end-to-end before a real gateway (Razorpay/Stripe) is wired up behind the same interface. Confirmed live: subscribing flips `identity.users.subscription_tier` to `Pro` in the database.
- **`Plan.Price`/`Currency` are plain `decimal`/`string`**, not the `Money` value object — `Money` has no established EF mapping convention in this codebase yet.
- Plans are deactivated, never deleted (reference data); subscriptions are never deleted (billing history) — cancel/expire only change `Status`.

## Ingestion module (automated price-data pull; Agmarknet live, construction stubbed)

| Who | Endpoint |
|---|---|
| Admin | `POST /api/v1/admin/ingestion/sources/{sourceId}/run` — manually trigger one ingestion run for a price source |
| Admin | `GET /api/v1/admin/ingestion/jobs?priceSourceId&status&page&pageSize` — job history, newest first |
| Admin | `GET /api/v1/admin/ingestion/jobs/{jobId}` — one job's outcome |
| Admin | `GET /api/v1/admin/ingestion/jobs/{jobId}/errors?page&pageSize` — per-record failures for a job |

- **Same normalized model as manual entry** (BRD §9: "category-specific adapters must map into a common normalized price model") — `RunIngestionJobCommandHandler` resolves each fetched row's product/variant/location code to internal ids and calls the exact same `PriceRecord.Create` path `RecordPriceCommandHandler` uses for the admin manual-entry screen, so a `PriceRecordedDomainEvent` reaches Alerting identically either way.
- **One bad row never aborts the run**: a record that fails to resolve (unknown product/variant/mandi/supplier code) or fails `PriceRecord` validation becomes a `DataIngestionError` (raw payload + reason kept verbatim) instead of failing the whole job — `DataIngestionJob.Status` ends up `Succeeded`, `PartiallySucceeded`, or `Failed` depending on the mix.
- **Adapters are keyed by `PriceSource.Code`** (`IngestionAdapterDispatcher`): `agmarknet` → `AgmarknetIngestionSourceAdapter` (live); any other code → `StubIngestionSourceAdapter` (honest failure, never fabricated data). Construction stays manual-entry until a daily feed exists.
- **Agmarknet adapter**: data.gov.in resource `9ef84268-d588-465a-a308-a864a43d0070`, filtered by `arrival_date` (DD/MM/YYYY), paginated (`Agmarknet:PageSize`, throttled `Agmarknet:ThrottleDelayMs`). Mapping: `commodity` → product code, `variety` → variant code (`FAQ`/`Other`/`Unclassified` → none), `market` → mandi code, prices in ₹/quintal. Codes are slugified (`"Red Onion (Large)"` → `red-onion-large`) — **create products/mandis with those exact codes** or rows land in `ingestion_errors` (the errors list is the mapping to-do list).
- **Setup**: register at https://data.gov.in → `dotnet user-secrets set "Agmarknet:ApiKey" "<key>"` (or env `Agmarknet__ApiKey`) → create price source with code `agmarknet` → `POST /admin/ingestion/sources/{id}/run`. Missing key = job `Failed` with a clear reason.
- **Mock mode (Development only)**: `appsettings.Development.json` sets `Agmarknet:UseMockData=true` → serves `SampleData/agmarknet-sample.json` (data.gov.in response shape) through the same mapping/persistence path, re-dated to the run date. Startup fails if enabled outside Development. Set it to `false` once a real key is in user-secrets.
- **Name → code overrides** (`appsettings.json`): `Agmarknet:MarketCodeMap` (slugged market → mandi code, e.g. `"pune": "apmc-pune"`) and `Agmarknet:CommodityCodeMap` (slugged commodity → product code, e.g. `"arhar-tur-red-gram-whole": "tur"`). Unmapped names pass through as their slug. Add an entry for each code reported in `ingestion_errors`.
- **`IngestionSchedulerBackgroundService`** fulfils BRD §9/§18's "Background Services / scheduled workers": on a configurable interval (`IngestionScheduler:IntervalHours`, default 24h) it runs one ingestion job per active `PriceSource`, each in its own DI scope (mirrors `OutboxProcessor`) so one source's failure never blocks another's. The admin manual-trigger endpoint runs the identical `RunIngestionJobCommand` with `TriggerType.Manual` instead of `Scheduled`.
- **Ingestion always records at the product's default unit** — cross-unit source feeds are out of scope, the same simplification `ProcurementRequirement` makes (see its doc comment).
- Jobs and errors are never deleted (ingestion audit trail); a duplicate row for the same product/location/source/date is recorded as a `DataIngestionError`, not silently skipped, so a re-run's outcome is always visible.

## Localization module (data-driven terminology; keys used across modules)

| Who | Endpoint |
|---|---|
| App | `GET /api/v1/localization/texts?keyPrefix` — every key (or one namespace, e.g. `alerts.`) resolved to text for `Accept-Language`, falling back to English (BRD §18: "database/config-driven localized metadata") |
| Admin | `GET /api/v1/admin/localization/texts?keyPrefix&page&pageSize`, `GET …/texts/{id}` — every translation, for editing |
| Admin | `POST /api/v1/admin/localization/texts`, `PUT …/texts/{id}` — create/edit a key's translations and admin-facing description |

- **Same owned-translation shape as Catalog's `CatalogTranslation`** (`LocalizedTextValue`, owner id + language as the key, English required, `LocalizedTextValues.Sync` diffs in place) but standalone — a `LocalizedTextEntry` is its own aggregate keyed by a dot-namespaced `LocalizationKey` (e.g. `alerts.price_drop.title`), not owned by a catalog item, because this table backs terminology used *across* modules (alert titles, WhatsApp/report text, trend labels — BRD §8) rather than one entity's display name.
- **Keys are immutable and never deleted** — other modules will look strings up by key (a plain string, not an FK), so removing a key could silently break a caller; only its translations and admin description are ever edited. This is the same "immutable identifier, nothing deleted" rule Catalog codes and Pricing source codes follow.
- **Resolution is COALESCE, not app-layer branching**: `GetTextsAsync` LEFT JOINs the requested language and English in one query (`COALESCE(req.text, en.text)`), matching the two-step language→English fallback `ILanguageContext`/`CatalogReadService` already use for names. Confirmed live for a language with a translation (`mr`), one without (falls back to `en`), and a namespace filter (`keyPrefix=alerts.`).
- **Support is the first module to read copy back out of the store**: `SupportReplyNotificationHandler` resolves `support.reply.title`/`.body` in the user's own preferred language (a background handler has no request language), and the app's FAQ accordion is nothing but `?keyPrefix=support.faq.`. Alerting/Reporting output still builds strings inline; they can move the same way when their copy is ready.

## Support module (help & support: FAQ, contact, tickets)

| Who | Endpoint |
|---|---|
| App | `GET /api/v1/support/contact` → `{ whatsAppNumber, phone, email }` from the `Support` config section |
| App | `POST /api/v1/support/tickets` `{ category, subject, message }` → 201 |
| App | `GET /api/v1/support/tickets?page&pageSize` — the caller's own tickets, last activity first |
| App | `GET /api/v1/support/tickets/{id}` — the ticket with its full message thread, owner only |
| App | `POST /api/v1/support/tickets/{id}/messages` `{ message }` |
| Admin | `GET /api/v1/admin/support/tickets?status&category&search&page&pageSize` — the queue; `search` matches the subject |
| Admin | `GET /api/v1/admin/support/tickets/{id}`, `POST …/{id}/messages`, `PUT …/{id}/status` |

- **A ticket never exists without its opening message**: `SupportTicket.Create` writes the ticket and the first `SupportTicketMessage` in one step, so there is no window in which an empty ticket is visible.
- **Messages belong to the ticket aggregate** — `SupportTicketRepository` loads them with it, they cascade on delete, and they are immutable once written (no audit or concurrency columns): a thread is a record of what was actually said.
- **Status transitions the aggregate owns** follow from the conversation rather than from an admin action: support answering an `Open` ticket moves it to `InProgress`, and the user replying to a `Resolved` one reopens it. Everything else is the admin's `PUT …/status`, and `Closed` is terminal — no further message and no further status change, so a closed ticket is a settled record.
- **`LastActivityAtUtc` is maintained by the aggregate**, not read off `UpdatedAtUtc`: adding a message modifies no ticket column, so the audit stamp would not move, and both list screens sort on last activity. Both indexes lead with their filter column and carry `last_activity_at_utc DESC`.
- **An admin reply raises `SupportTicketRepliedDomainEvent`** → outbox (same transaction) → `SupportReplyNotificationHandler` → `INotificationSender`, exactly the chain `AlertTriggeredDomainEvent` uses. Copy comes from the LocalizedTexts store with an English fallback, so a missing key never drops the notification.
- **Contact details are configuration, not data** (`Support:WhatsAppNumber`, `Support:Phone`, `Support:Email`), validated with `ValidateOnStart` — a build that shipped without them would give users a dead-end help screen, so it fails at startup instead.

## Adding a feature (template)

1. Domain: aggregate + value objects + domain events in `MolBhav.Domain/<Module>/`.
2. Infrastructure: `IEntityTypeConfiguration` in `Persistence/Configurations/<Module>/`, repository in `Persistence/Repositories/`, Dapper read service if needed; one migration per logical change.
3. Application: `Features/<Module>/<UseCase>/` → request, handler, validator, response DTO.
4. API: action on a versioned controller returning `OkEnvelope` / `CreatedEnvelope` / `NoContentOrProblem`.

## Package notes

- **MediatR is pinned to 12.5.0**, the last Apache-2.0 release. 13.x+ requires a commercial licence key (free community tier for small companies) — upgrade deliberately.
- Asp.Versioning 8.1.0 targets .NET 8 and runs on .NET 10.
