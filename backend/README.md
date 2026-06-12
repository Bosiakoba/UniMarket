# UniMarket API (ASP.NET Core)

Main backend for the Flutter app. Matches `md/deep-research-report.md` and prototype stores in `lib/core/data/stores/`.

**Firebase Auth**, **SQLite persistence** (D1-compatible schema), and **Cloudflare R2/D1** integrations are wired. Data survives API restarts in `data/unimarket.db`.

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

**Database:** User profiles (`ProfileComplete`, interests, seller status) are stored in SQLite and persist across restarts. Enable `Cloudflare__D1Enabled=true` to auto-apply `cloudflare/d1/schema.sql` to your remote D1 (for Workers/admin); the home server continues to use the SQLite file as its primary store.

**Uploads:** With R2 disabled, seller ID photos save to `data/uploads/` and are served at `/media/...` when `Cloudflare__AllowLocalUploadFallback=true`.

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
