#!/usr/bin/env bash
# Scenario test: act + uv installed side by side (the millia-codespace layout).
set -euo pipefail

source dev-container-features-test-lib

check "act present" bash -c "act --version"
check "uv present" bash -c "uv --version"
check "uv python 3.13 usable" bash -c "source /etc/profile.d/uv.sh && uv run --python 3.13 python -c 'import sys; assert sys.version_info[:2]==(3,13)'"
check "actrc default image set" bash -c "grep -q 'catthehacker/ubuntu:act-22.04' \"\$HOME/.actrc\""

reportResults
