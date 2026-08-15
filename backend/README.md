# UniMarket API (ASP.NET Core)

Main backend for the Flutter app. Matches `md/deep-research-report.md` and prototype stores in `lib/core/data/stores/`.

**Firebase Auth** (login only), **Cloudflare D1** (all app records), and **Cloudflare R2** (uploads) are the production data layer. The C# API is **stateless logic** — it can run on your dev machine or Railway without storing data locally.

When `Cloudflare__D1Enabled=true` and D1 credentials are set, every read/write goes to **D1** (the API uses a short-lived in-memory cache and syncs back to D1 after each save). When D1 is off, local `data/unimarket.db` is used for offline dev only.

## Home server (demo day)

1. Install [.NET 8 SDK](https://dotnet.microsoft.com/download) on your PC.
2. From this folder:

```bash
cd backend/UniMarket.Api
dotnet restore
dotnet run
```

3. API listens on **http://0.0.0.0:5080** (LAN-accessible from your phone on the same Wi‑Fi).
4. Swagger UI: **http://localhost:5080/swagger**
5. Point Flutter at `http://<your-pc-lan-ip>:5080` when wiring `ApiClient`.

### Dev auth (Firebase disabled)

When `Firebase__Enabled=false`, send header on protected routes:

```http
X-Dev-User-Id: alex-demo
```

Or call `POST /api/auth/session` with body `{ "devUserId": "alex-demo" }`.

### Firebase auth (production / testing)

When `Firebase__Enabled=true`:

1. Enable **Email/Password** in Firebase Console → Authentication → Sign-in method.
2. Create test users (or sign up in the app):
   - `alex.morgan@university.edu` — links to seeded seller **alex-demo**
   - `jordan@university.edu` — links to seeded buyer **seller-jordan**
3. App signs in with Firebase, then `POST /api/auth/session` with `{ "firebaseIdToken": "..." }`.
4. All API calls use `Authorization: Bearer <token>`.

## Environment variables (Firebase + Cloudflare)

**Never commit real keys.** Local secrets live in `backend/UniMarket.Api/.env` (gitignored).

1. Copy the template:

```bash
cp backend/UniMarket.Api/.env.example backend/UniMarket.Api/.env
```

2. Fill in your values. ASP.NET maps double-underscore env vars to config sections:

| `.env` key | Purpose |
|------------|---------|
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to Firebase service account JSON (gitignored) |
| `Firebase__ProjectId` | Firebase project ID |
| `Firebase__Enabled` | `true` when ready to verify ID tokens |
| `Cloudflare__AccountId` | Cloudflare account ID |
| `Cloudflare__D1DatabaseId` | D1 database UUID |
| `Cloudflare__D1ApiToken` | API token with D1 read/write |
| `Cloudflare__D1Enabled` | `true` when D1 is wired |
| `Cloudflare__R2AccessKeyId` | R2 access key |
| `Cloudflare__R2SecretAccessKey` | R2 secret |
| `Cloudflare__R2BucketName` | R2 bucket (default `unimarket-assets`) |
| `Cloudflare__R2Endpoint` | `https://<account_id>.r2.cloudflarestorage.com` |
| `Cloudflare__R2Enabled` | `true` when R2 is wired |
| `Cloudflare__R2PublicBaseUrl` | Public R2 bucket URL (e.g. `https://pub-xxx.r2.dev`) |
| `Cloudflare__AllowLocalUploadFallback` | `true` saves uploads to `data/uploads/` when R2 is off |
| `ConnectionStrings__Default` | SQLite file path (default `Data Source=data/unimarket.db`) |
| `Api__PublicBaseUrl` | LAN URL for local upload links (e.g. `http://192.168.0.165:5080`) |

3. Start the API — `.env` is loaded automatically from the project folder.

**Database (production):** Set `Cloudflare__D1Enabled=true` with Account ID, Database ID, and API token. All users, listings, chats, seller applications, etc. live in **D1** — view them in the Cloudflare dashboard → D1 → `unimarket-db` → Studio.

**Uploads (production):** Set `Cloudflare__R2Enabled=true` and disable local fallback (`Cloudflare__AllowLocalUploadFallback=false`). Student ID photos and listing images are stored in **R2**, not on the API server.

**Local dev (optional):** Leave D1/R2 disabled to use `data/unimarket.db` and `data/uploads/` on your machine only.

4. Check readiness (no secrets returned):

```http
GET /health
```

Response includes `integrations.firebase.configured` and `integrations.cloudflare.d1|r2.configured`.

## Admin verification queue (Cloudflare Worker)

**Dashboard:** https://unimarket-admin.unimarket93.workers.dev

Set on the API server (must match worker `ADMIN_API_KEY` secret):

```env
Admin__ApiKey=<same-key-as-worker-secret>
Cloudflare__AiReviewUrl=https://unimarket-admin.unimarket93.workers.dev/api/ai-review

Check `GET /health` on the API — `integrations.cloudflare.aiReview.configured` must be `true`.
The worker also runs a cron every 2 minutes to review any pending seller apps still missing AI output.

Seller applications require a **verified campus email** (4-digit OTP via Resend) before submit, then are AI-reviewed in the background.

```env
Resend__ApiKey=re_...
Resend__FromAddress=UniMarket <noreply@your-verified-domain.com>
Resend__Enabled=true
```

Seller applications are AI-reviewed in the background after submit. The worker fetches the ID image via the admin API (including local `/media/...` files), compares profile university and email to the ID, and auto-approves when checks pass; otherwise the request stays pending for the admin dashboard.
```

The worker calls `UNIMARKET_API_URL` (`https://unimarket-api.youngfuturetechnology.xyz` in `wrangler.toml`). Your API must be publicly reachable at that URL for approve/reject and AI review to work.

## Admin verification queue

Seller applications and verified badge requests share one queue (`VerificationRequest`).

| `.env` key | Purpose |
|------------|---------|
| `Admin__ApiKey` | Secret for `X-Admin-Key` on `/api/admin/*` routes |

Flutter submits:

- `POST /api/users/seller-application` → pending until admin approves (`IsSeller`)
- `POST /api/users/verify-badge` → pending until admin approves (`IsVerified`)

Admin dashboard: see `cloudflare/admin-worker/README.md`.

## Railway (later)

Set `ASPNETCORE_URLS=http://0.0.0.0:8080` and Railway secrets using the same `Firebase__*` / `Cloudflare__*` keys from `.env.example`.
