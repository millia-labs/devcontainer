#!/usr/bin/env bash
# Installs the Flutter SDK (https://flutter.dev) from the official release archive.
set -euo pipefail

VERSION="${VERSION:-3.41.4}"
CHANNEL="${CHANNEL:-stable}"
INSTALLJDK="${INSTALLJDK:-true}"
JDKVERSION="${JDKVERSION:-17}"
PRECACHE="${PRECACHE:-true}"

FLUTTER_HOME="/opt/flutter"

# _REMOTE_USER is injected by the dev container CLI. Flutter writes bin/cache/engine.stamp
# on first run, so /opt/flutter must be owned by whoever runs the container at runtime.
REMOTE_USER="${_REMOTE_USER:-root}"

echo "[flutter] installing (version=${VERSION}, channel=${CHANNEL})"

if [ "$(id -u)" -ne 0 ]; then
  echo "[flutter] must run as root" >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "[flutter] this feature requires a Debian/Ubuntu base (apt-get)" >&2
  exit 1
fi

# --- System deps: fetch/extract tools + Flutter's runtime libs (+ optional JDK) ---
PACKAGES="git curl ca-certificates unzip zip xz-utils libglu1-mesa"
if [ "$INSTALLJDK" = "true" ]; then
  PACKAGES="${PACKAGES} openjdk-${JDKVERSION}-jdk-headless"
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
# shellcheck disable=SC2086
apt-get install -y --no-install-recommends ${PACKAGES}
rm -rf /var/lib/apt/lists/*

# --- Resolve 'latest' to a concrete version via the official releases manifest ---
if [ "$VERSION" = "latest" ]; then
  echo "[flutter] resolving latest ${CHANNEL} release"
  META="$(curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json")"
  # current_release.<channel> holds the hash; find that release's version in the array.
  HASH="$(printf '%s' "$META" \
    | grep -o "\"${CHANNEL}\"[[:space:]]*:[[:space:]]*\"[0-9a-f]*\"" | head -n1 \
    | grep -o '"[0-9a-f]*"$' | tr -d '"')"
  if [ -z "$HASH" ]; then
    echo "[flutter] could not resolve latest ${CHANNEL} release; pass an explicit version" >&2
    exit 1
  fi
  VERSION="$(printf '%s' "$META" \
    | tr '{' '\n' | grep "\"hash\"[[:space:]]*:[[:space:]]*\"${HASH}\"" | head -n1 \
    | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | grep -o '"[^"]*"$' | tr -d '"')"
  if [ -z "$VERSION" ]; then
    echo "[flutter] could not resolve version for hash ${HASH}; pass an explicit version" >&2
    exit 1
  fi
  echo "[flutter] latest ${CHANNEL} = ${VERSION}"
fi

# --- Download + extract the SDK ---
ARCHIVE="flutter_linux_${VERSION}-${CHANNEL}.tar.xz"
URL="https://storage.googleapis.com/flutter_infra_release/releases/${CHANNEL}/linux/${ARCHIVE}"

echo "[flutter] downloading ${URL}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl --fail --location --silent --show-error "$URL" -o "$TMP/flutter.tar.xz"
rm -rf "$FLUTTER_HOME"
tar -xf "$TMP/flutter.tar.xz" -C /opt

# git needs /opt/flutter marked safe (owned by remote user, git may run as anyone).
git config --system --add safe.directory "$FLUTTER_HOME"

if [ "$REMOTE_USER" != "root" ] && id "$REMOTE_USER" >/dev/null 2>&1; then
  chown -R "$REMOTE_USER":"$(id -gn "$REMOTE_USER")" "$FLUTTER_HOME"
fi

export PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter setup as the remote user so cache files are written with the right owner.
run_as_user() {
  if [ "$REMOTE_USER" != "root" ] && id "$REMOTE_USER" >/dev/null 2>&1; then
    su - "$REMOTE_USER" -c "export PATH=\"${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:\$PATH\"; $1"
  else
    bash -lc "export PATH=\"${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:\$PATH\"; $1"
  fi
}

run_as_user "flutter config --no-analytics"
if [ "$PRECACHE" = "true" ]; then
  run_as_user "flutter precache"
fi
run_as_user "flutter --version"

# Flutter rewrites bin/cache/engine.stamp (and other cache files) on first run. The
# container's runtime user is often NOT the user this feature installed as — e.g. the
# feature-test harness installs with _REMOTE_USER=root, but the container runs as
# `vscode`. Chowning above only helps when we know the user; make the SDK writable by
# any user so the runtime engine.stamp write can't hit 'Permission denied'.
chmod -R a+rwX "$FLUTTER_HOME"

echo "[flutter] done"
