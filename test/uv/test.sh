#!/usr/bin/env bash
# Autorun test for the `uv` feature.
set -euo pipefail

source dev-container-features-test-lib

check "uv on PATH" bash -c "command -v uv"
check "uvx on PATH" bash -c "command -v uvx"
check "uv reports a version" bash -c "uv --version | grep -Eio 'uv [0-9]+\.[0-9]+'"
check "shared python dir exported" bash -c "test -f /etc/profile.d/uv.sh && grep -q UV_PYTHON_INSTALL_DIR /etc/profile.d/uv.sh"
check "managed cpython 3.13 present" bash -c "source /etc/profile.d/uv.sh && uv python list --only-installed | grep -q '3.13'"
check "uv can run python 3.13" bash -c "source /etc/profile.d/uv.sh && uv run --python 3.13 python -c 'import sys; print(sys.version); assert sys.version_info[:2]==(3,13)'"

reportResults
