#!/usr/bin/env bash
# Autorun test for the `act` feature. Executed by `devcontainer features test`
# inside a container that already has the feature installed.
set -euo pipefail

source dev-container-features-test-lib

check "act on PATH" bash -c "command -v act"
check "act reports a version" bash -c "act --version | grep -Eio 'act version [0-9]+\.[0-9]+'"
check "actrc seeded with default image" bash -c "grep -q 'ubuntu-latest=' \"\$HOME/.actrc\""

reportResults
