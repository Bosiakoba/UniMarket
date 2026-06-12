# UniMarket Admin Worker

Cloudflare Worker dashboard for reviewing **seller applications** and **verified badge** requests. It proxies the UniMarket API admin queue and runs **Workers AI** vision review on student ID photos in the background when someone applies.

## Automated seller review

When a user submits a seller application, the API enqueues a background AI review that:

1. Fetches the student ID image through `GET /api/admin/verification-requests/{id}/id-document` (works for local `/media/...` uploads — no public URL required).
2. Runs **LLaVA** vision on the ID to read the name and university on the card.
3. Compares profile **university** and **email domain** to the ID and campus email rules.
4. **Auto-approves** when recommendation is `approve`; otherwise leaves the request **Pending** with an AI summary for manual review on this dashboard.

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
