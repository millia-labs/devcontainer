#!/usr/bin/env bash
# Installs Node.js (NodeSource) + pnpm (system-wide npm global).
set -euo pipefail

NODEMAJOR="${NODEMAJOR:-20}"
PNPMVERSION="${PNPMVERSION:-8}"

echo "[node] installing (node=${NODEMAJOR}, pnpm=${PNPMVERSION})"

if [ "$(id -u)" -ne 0 ]; then
  echo "[node] must run as root" >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "[node] this feature requires a Debian/Ubuntu base (apt-get)" >&2
  exit 1
fi

# curl/ca-certificates are needed to fetch the NodeSource setup script.
if ! command -v curl >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y --no-install-recommends ca-certificates curl
fi

export DEBIAN_FRONTEND=noninteractive
curl -fsSL "https://deb.nodesource.com/setup_${NODEMAJOR}.x" | bash -
apt-get install -y --no-install-recommends nodejs
rm -rf /var/lib/apt/lists/*

if [ "$PNPMVERSION" != "-" ]; then
  npm install -g "pnpm@${PNPMVERSION}"
fi

echo "[node] installed: node $(node --version) / npm $(npm --version)$([ "$PNPMVERSION" != "-" ] && echo " / pnpm $(pnpm --version)")"
echo "[node] done"
