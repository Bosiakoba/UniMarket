# Auto-start on server boot

Run the API and Cloudflare tunnel as OS services so they survive reboots and restart on crash.

## One-time setup (both platforms)

1. **Publish** the API (recommended for production):

```bash
dotnet publish backend/UniMarket.Api -c Release -o /opt/unimarket/api   # Linux
# or
dotnet publish backend/UniMarket.Api -c Release -o C:\UniMarket\api       # Windows
```

2. Copy secrets into the publish folder (never commit these):

- `backend/UniMarket.Api/.env` → publish folder
- Firebase service account JSON (path in `GOOGLE_APPLICATION_CREDENTIALS`)

3. Verify locally:

```bash
curl http://127.0.0.1:5080/health
```

---

## Linux (systemd) — recommended for a home server

```bash
# On your server
sudo apt install dotnet-sdk-8.0   # or runtime only: aspnetcore-runtime-8.0

dotnet publish backend/UniMarket.Api -c Release -o /opt/unimarket/api
cp backend/UniMarket.Api/.env /opt/unimarket/api/

chmod +x backend/deploy/install-linux-service.sh
sudo ./backend/deploy/install-linux-service.sh /opt/unimarket/api YOUR_USER
```

**Useful commands:**

```bash
sudo systemctl status unimarket-api
sudo systemctl restart unimarket-api
sudo journalctl -u unimarket-api -f
```

### Cloudflare tunnel (Linux)

If `cloudflared` is already configured (`cloudflared tunnel list`):

```bash
sudo cp backend/deploy/cloudflared.service /etc/systemd/system/
# Edit YOUR_LINUX_USER and YOUR_TUNNEL_NAME
sudo nano /etc/systemd/system/cloudflared.service

sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

Or install as a service via Cloudflare:

```bash
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

---

## Windows (Task Scheduler)

Run **PowerShell as Administrator**:

```powershell
cd E:\Pro\UniMarket\unimarket\backend\deploy
.\install-windows-service.ps1 -ProjectDir "E:\Pro\UniMarket\unimarket\backend\UniMarket.Api" -PublishDir "C:\UniMarket\api"
```

**Useful commands:**

```powershell
Start-ScheduledTask -TaskName "UniMarket API"
Get-ScheduledTask -TaskName "UniMarket API"
curl http://127.0.0.1:5080/health
```

### Cloudflare tunnel (Windows)

Install as a Windows service (run once, as Admin):

```powershell
cloudflared service install
# or if you use a named tunnel:
cloudflared.exe service install --token YOUR_TUNNEL_TOKEN
```

Then in `services.msc`, set **Cloudflare Tunnel** / **cloudflared** to **Automatic**.

---

## Boot order

1. Server powers on  
2. **UniMarket API** starts → listens on `0.0.0.0:5080`  
3. **cloudflared** starts → exposes `https://unimarket-api.youngfuturetechnology.xyz`  
4. Flutter app can connect from any network  

If the API starts before the network is ready, `Restart=always` (Linux) or Task Scheduler restart (Windows) will retry.

---

## Disable sleep (important for a home PC server)

**Windows:** Settings → System → Power → Sleep → **Never** (when plugged in).

**Linux:**

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

Also disable automatic Windows updates reboot during demo hours if needed.
