#!/usr/bin/env bash
# Installs nektos/act (https://github.com/nektos/act) — run GitHub Actions locally.
set -euo pipefail

VERSION="${VERSION:-latest}"
DEFAULTIMAGE="${DEFAULTIMAGE:-catthehacker/ubuntu:act-22.04}"

# _REMOTE_USER / _REMOTE_USER_HOME are injected by the dev container CLI.
REMOTE_USER="${_REMOTE_USER:-root}"
REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/root}"

echo "[act] installing (version=${VERSION})"

if [ "$(id -u)" -ne 0 ]; then
  echo "[act] must run as root" >&2
  exit 1
fi

# curl/tar are needed to fetch the release tarball; install only if missing.
if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y
    apt-get install -y --no-install-recommends ca-certificates curl tar
    rm -rf /var/lib/apt/lists/*
  else
    echo "[act] curl and tar are required but apt-get is unavailable" >&2
    exit 1
  fi
fi

# nektos/act publishes assets named act_Linux_x86_64.tar.gz / act_Linux_arm64.tar.gz
case "$(uname -m)" in
  x86_64 | amd64) ACT_ARCH="x86_64" ;;
  aarch64 | arm64) ACT_ARCH="arm64" ;;
  armv7l) ACT_ARCH="armv7" ;;
  *) echo "[act] unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

if [ "$VERSION" = "latest" ]; then
  URL="https://github.com/nektos/act/releases/latest/download/act_Linux_${ACT_ARCH}.tar.gz"
else
  # Accept both '0.2.82' and 'v0.2.82'
  TAG="${VERSION#v}"
  URL="https://github.com/nektos/act/releases/download/v${TAG}/act_Linux_${ACT_ARCH}.tar.gz"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "[act] downloading ${URL}"
curl --fail --location --silent --show-error "$URL" -o "$TMP/act.tar.gz"
tar -xzf "$TMP/act.tar.gz" -C "$TMP" act
install -m 0755 "$TMP/act" /usr/local/bin/act

echo "[act] installed: $(/usr/local/bin/act --version)"

# Pre-seed ~/.actrc so `act` never blocks on the first-run image-size prompt.
if [ "$DEFAULTIMAGE" != "-" ]; then
  ACTRC="${REMOTE_USER_HOME}/.actrc"
  if [ ! -f "$ACTRC" ]; then
    printf -- '-P ubuntu-latest=%s\n-P ubuntu-22.04=%s\n' "$DEFAULTIMAGE" "$DEFAULTIMAGE" > "$ACTRC"
    if [ "$REMOTE_USER" != "root" ] && id "$REMOTE_USER" >/dev/null 2>&1; then
      chown "$REMOTE_USER":"$(id -gn "$REMOTE_USER")" "$ACTRC"
    fi
    echo "[act] wrote default runner image to ${ACTRC}"
  else
    echo "[act] ${ACTRC} already exists, leaving it untouched"
  fi
fi

echo "[act] done"
