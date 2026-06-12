# UniMarket Admin Worker

Cloudflare Worker dashboard for reviewing **seller applications** and **verified badge** requests. It proxies the UniMarket API admin queue and runs **Workers AI** vision review on student ID photos in the background when someone applies.

## URLs

| URL | Purpose |
|-----|---------|
| `https://unimarket-admin.unimarket93.workers.dev/` | **Admin dashboard** (open this in a browser) |
| `POST /api/process-request` | API triggers background AI for one application (`{ requestId }`) |
| `POST /api/ai-review` | Low-level AI only (returns summary JSON) |
| `GET /api/ai-review` | Help message — not a page |

Do **not** open `/api/ai-review` in the browser expecting a UI. Use `/` for the dashboard.

## Automated seller review

When a user submits a seller application, the API **immediately** queues `POST /api/process-request` in a background task (not tied to the HTTP connection, so reverse proxies cannot cancel it). A cron sweep every minute catches anything missed.

1. Fetches the uploaded image through `GET /api/admin/verification-requests/{id}/id-document` (works for R2 and local `/media/...` uploads).
2. Runs **Llama 3.2 Vision** (LLaVA fallback) with strict checks — must describe the image and show name/school on card.
3. Compares profile **university** and **email domain** to the ID and campus email rules.
4. **Auto-rejects** when confidence is high (e.g. clear non-ID upload like an ad). **Auto-approves** only on high-confidence ID + email + name + university match. Otherwise leaves the request **Pending** for manual review.

## Prerequisites

1. UniMarket API running with `Admin__ApiKey` set in `.env` (same value the worker uses).
2. API reachable from Cloudflare — use a public URL or [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) to your home server (`192.168.0.165:5080` is fine for local `wrangler dev` only).

## Setup

```bash
cd cloudflare/admin-worker
npm install
wrangler secret put ADMIN_API_KEY
```

Paste the same key as `Admin__ApiKey` on the API server.

Update `wrangler.toml` `UNIMARKET_API_URL` to your public API base (no trailing slash).

## Local dev

```bash
npm run dev
```

Open the URL Wrangler prints (usually `http://localhost:8787`).

## Deploy

```bash
npm run deploy
wrangler secret put ADMIN_API_KEY
```

**Live deployment:** https://unimarket-admin.unimarket93.workers.dev

### Llama 3.2 Vision (one-time per account)

```bash
curl "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/ai/run/@cf/meta/llama-3.2-11b-vision-instruct" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -d '{ "prompt": "agree" }'
```

On the API server, set (same admin key as the worker secret):

```env
Admin__ApiKey=<your-admin-key>
Cloudflare__AiReviewUrl=https://unimarket-admin.unimarket93.workers.dev/api/ai-review
```

## Admin API (used by the worker)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/admin/verification-requests?status=Pending` | Queue list |
| GET | `/api/admin/verification-requests/{id}` | Request detail |
| POST | `/api/admin/verification-requests/{id}/approve` | Approve |
| POST | `/api/admin/verification-requests/{id}/reject` | Reject |
| POST | `/api/admin/verification-requests/{id}/ai-review` | Save AI summary |

All admin routes require header `X-Admin-Key`.

## Request types

- `seller_application` — student ID + store name → sets `User.IsSeller = true` when approved
- `verified_badge` — performance criteria met → sets `User.IsVerified = true` when approved

Both use the same admin queue and dashboard.
