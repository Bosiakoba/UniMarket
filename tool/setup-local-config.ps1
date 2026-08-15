# Run after cloning to create local Firebase files from templates (if missing).
# Then run: flutterfire configure

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Ensure-Copy($source, $dest) {
    if (-not (Test-Path $dest)) {
        Copy-Item (Join-Path $root $source) (Join-Path $root $dest)
        Write-Host "Created $dest from template."
    }
}

Ensure-Copy "lib/firebase_options.example.dart" "lib/firebase_options.dart"
Ensure-Copy "android/app/google-services.json.example" "android/app/google-services.json"
Ensure-Copy "firebase.json.example" "firebase.json"
Ensure-Copy ".env.example" ".env"
Ensure-Copy "backend/UniMarket.Api/.env.example" "backend/UniMarket.Api/.env"

Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. flutterfire configure   # overwrites lib/firebase_options.dart + google-services.json"
Write-Host "  2. Edit backend/UniMarket.Api/.env with Cloudflare + Firebase keys"
Write-Host "  3. Copy .env.example to .env for Flutter dart-defines (optional)"
