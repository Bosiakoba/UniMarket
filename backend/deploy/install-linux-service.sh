#!/usr/bin/env bash
# Install UniMarket API as a systemd service (Linux).
# Run on the server after publishing the app.
#
# Usage:
#   sudo ./install-linux-service.sh /opt/unimarket/api YOUR_LINUX_USER
#
# Before running:
#   1. dotnet publish backend/UniMarket.Api -c Release -o /opt/unimarket/api
#   2. Copy .env and Firebase JSON into /opt/unimarket/api/
#   3. chown -R YOUR_LINUX_USER:YOUR_LINUX_USER /opt/unimarket/api

set -euo pipefail

INSTALL_DIR="${1:-/opt/unimarket/api}"
RUN_AS_USER="${2:-$USER}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$INSTALL_DIR/UniMarket.Api.dll" ]]; then
  echo "Missing $INSTALL_DIR/UniMarket.Api.dll — publish first:"
  echo "  dotnet publish backend/UniMarket.Api -c Release -o $INSTALL_DIR"
  exit 1
fi

TMP="$(mktemp)"
sed "s|/opt/unimarket/api|$INSTALL_DIR|g; s|YOUR_LINUX_USER|$RUN_AS_USER|g" \
  "$SCRIPT_DIR/unimarket-api.service" > "$TMP"

sudo cp "$TMP" /etc/systemd/system/unimarket-api.service
rm "$TMP"

sudo systemctl daemon-reload
sudo systemctl enable unimarket-api
sudo systemctl restart unimarket-api

echo ""
echo "Installed. Check status:"
echo "  sudo systemctl status unimarket-api"
echo "  curl http://127.0.0.1:5080/health"
