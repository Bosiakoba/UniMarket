# UniMarket API (ASP.NET Core)

Main backend for the Flutter app. Matches `md/deep-research-report.md` and prototype stores in `lib/core/data/stores/`.

**Firebase Auth** and **Cloudflare D1/R2** are stubbed for now — swap implementations without changing controller contracts.

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

### Dev auth (until Firebase)

Send header on protected routes:

```http
X-Dev-User-Id: alex-demo
```

Or call `POST /api/auth/session` with body `{ "devUserId": "alex-demo" }` to bootstrap a user.

**Never commit real Firebase service accounts or Cloudflare keys.** Use environment variables (see `.env.example`).

## Railway (later)

Set `ASPNETCORE_URLS=http://0.0.0.0:8080` and Railway secrets for Firebase / D1 / R2 when ready.
