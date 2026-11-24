# Hosting prerequisites (API)

Target (from `JagTech_API_HOSTING.md`): one Linux VPS, Docker, Nginx on the host, PostgreSQL in a private Docker
network, Cloudflare for DNS and HTTPS, GitHub Actions for builds.

## Ready in the repo (nothing to buy or send anywhere)

| What | Where |
|---|---|
| API Docker image (multi-stage, non-root, port 8080) | `api/src/MolBhav.Api/Dockerfile` |
| Production stack: API + private Postgres, API on 127.0.0.1 only | `api/deploy/docker-compose.prod.yml` |
| Every setting the server needs, names only | `api/deploy/.env.production.example` |
| Nginx site: HTTP→HTTPS, forwarded headers, 12 MB uploads | `api/deploy/nginx/molbhav-api.conf` |
| Build + test + image check on every push (no deploy) | `.github/workflows/api-ci.yml` |
| Health checks for monitoring | `GET /health/live`, `GET /health/ready` |
| Safety already in the API | proxy headers, HSTS, HTTPS redirect, strict CORS, mock feeds refused outside Development |

## Decisions only you can make

1. **Public API address: decided, `https://molbhav-api.jagtech.in`.** Already set in the Nginx file and in
   `Jwt__Issuer` of the env template. The app's production build uses
   `--dart-define=API_BASE_URL=https://molbhav-api.jagtech.in/api/v1`. The name is one level under `jagtech.in`,
   so Cloudflare's free certificate covers it.
2. **Where the server runs** (VPS provider and size). A small 2 GB machine is enough to start.
3. **Admin: Flutter or Angular.** The Flutter admin now covers everything; if the Angular admin goes, no web origin
   needs CORS and `Cors__AllowedOrigins` can stay empty.

## To arrange (needs your accounts)

- [ ] VPS with Ubuntu LTS, a non-root sudo user, SSH keys only, firewall open on 22, 80 and 443 only.
- [ ] Docker + Docker Compose and Nginx installed on it.
- [ ] Domain in Cloudflare; an `A` record `molbhav-api` (→ `molbhav-api.jagtech.in`) pointing at the VPS (proxied).
- [ ] Cloudflare SSL mode **Full (strict)** and an origin certificate saved on the server.
- [ ] Production secrets filled into `.env` on the server (copy of `.env.production.example`):
  - [ ] new `Jwt__SigningKey` (random, 32+ bytes) and a new database password
  - [ ] **rotated** keys, not the ones used in development: Agmarknet, Razorpay (live keys), WhatsApp, Firebase JSON
  - [ ] Msg91 DLT template id, only when SMS codes are switched on
- [ ] Razorpay webhook pointed at `https://<api address>/api/v1/billing/webhook`, and the WhatsApp webhook at
  `/api/v1/webhooks/whatsapp` (Meta verify token and app secret set).
- [ ] A backup job for the Postgres volume (nightly dump, copied off the server) and one **tested restore**.
- [ ] Database migrations run before the first start and on each release (see `JagTech_API_HOSTING.md` §18).
- [ ] Uptime monitor on `/health/ready`.

## Needed for the phone app release (separate from the server)

Release keystore and `android/key.properties` (`docs/release-signing.md`), the final app id (now
`com.molbhav.mol_bhav`), `google-services.json`, AdMob ids, and a build with `API_BASE_URL` set to the production
address.

## First deployment, in order

1. Server ready, DNS and certificate in place, `.env` filled in.
2. Build the image (CI) and load it on the server, or build it there from `api/`.
3. `docker compose -f docker-compose.prod.yml --env-file .env up -d`, then apply migrations.
4. `curl https://<api address>/health/ready` answers 200.
5. Create the first admin account and grant the admin role in the database (same out-of-band step as development).
6. Point a test build of the app at the production address and log in.
