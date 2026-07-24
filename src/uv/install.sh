#!/usr/bin/env bash
# Installs uv (https://github.com/astral-sh/uv) system-wide plus a shared managed CPython.
set -euo pipefail

VERSION="${VERSION:-latest}"
PYTHONVERSION="${PYTHONVERSION:-3.13}"

INSTALL_DIR="/usr/local/bin"
# Shared, world-readable location for uv-managed interpreters so every user
# (root at build time, the remote user at runtime) resolves the same Python.
UV_PY_DIR="/opt/uv/python"

echo "[uv] installing (version=${VERSION}, python=${PYTHONVERSION})"

if [ "$(id -u)" -ne 0 ]; then
  echo "[uv] must run as root" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y
    apt-get install -y --no-install-recommends ca-certificates curl
    rm -rf /var/lib/apt/lists/*
  else
    echo "[uv] curl is required but apt-get is unavailable" >&2
    exit 1
  fi
fi

# The Astral standalone installer honours UV_INSTALL_DIR for a fixed location and
# a versioned URL path for pinning. INSTALLER_NO_MODIFY_PATH keeps it from editing
# shell rc files (we manage PATH ourselves — /usr/local/bin is already on PATH).
if [ "$VERSION" = "latest" ]; then
  INSTALL_URL="https://astral.sh/uv/install.sh"
else
  INSTALL_URL="https://astral.sh/uv/${VERSION#v}/install.sh"
fi

curl --fail --location --silent --show-error "$INSTALL_URL" \
  | env UV_INSTALL_DIR="$INSTALL_DIR" INSTALLER_NO_MODIFY_PATH=1 sh

echo "[uv] installed: $("$INSTALL_DIR/uv" --version)"

# Export the shared interpreter dir for all login shells and non-login tool runs.
mkdir -p "$UV_PY_DIR"
cat > /etc/profile.d/uv.sh <<EOF
export UV_PYTHON_INSTALL_DIR="$UV_PY_DIR"
EOF
chmod 0644 /etc/profile.d/uv.sh

if [ "$PYTHONVERSION" != "-" ]; then
  echo "[uv] installing managed CPython ${PYTHONVERSION} into ${UV_PY_DIR}"
  UV_PYTHON_INSTALL_DIR="$UV_PY_DIR" "$INSTALL_DIR/uv" python install "$PYTHONVERSION"
  # Make the interpreter tree readable/executable for every user.
  chmod -R a+rX "$UV_PY_DIR"
fi

echo "[uv] done"
