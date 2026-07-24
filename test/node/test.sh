#!/usr/bin/env bash
# Autorun test for the `node` feature.
set -euo pipefail

source dev-container-features-test-lib

check "node on PATH" bash -c "command -v node"
check "npm on PATH" bash -c "command -v npm"
check "pnpm on PATH" bash -c "command -v pnpm"
check "node major is the pinned default (20)" bash -c "node --version | grep -Eq '^v20\.'"
check "pnpm major is the pinned default (8)" bash -c "pnpm --version | grep -Eq '^8\.'"

reportResults
