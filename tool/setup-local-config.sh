#!/usr/bin/env bash
# Run after cloning to create local Firebase files from templates (if missing).
# Then run: flutterfire configure

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

copy_if_missing() {
  local src="$ROOT/$1"
  local dest="$ROOT/$2"
  if [[ ! -f "$dest" ]]; then
    cp "$src" "$dest"
    echo "Created $2 from template."
  fi
}

copy_if_missing "lib/firebase_options.example.dart" "lib/firebase_options.dart"
copy_if_missing "android/app/google-services.json.example" "android/app/google-services.json"
copy_if_missing "firebase.json.example" "firebase.json"
copy_if_missing ".env.example" ".env"
copy_if_missing "backend/UniMarket.Api/.env.example" "backend/UniMarket.Api/.env"

echo ""
echo "Next steps:"
echo "  1. flutterfire configure   # overwrites lib/firebase_options.dart + google-services.json"
echo "  2. Edit backend/UniMarket.Api/.env with Cloudflare + Firebase keys"
echo "  3. Copy .env.example to .env for Flutter dart-defines (optional)"
