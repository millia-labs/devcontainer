#!/usr/bin/env bash
# Autorun test for the `flutter` feature.
set -euo pipefail

source dev-container-features-test-lib

check "flutter on PATH" bash -c "command -v flutter"
check "dart on PATH" bash -c "command -v dart"
check "flutter reports a version" bash -c "flutter --version | grep -Eio 'flutter [0-9]+\.[0-9]+'"
check "flutter version is the pinned default" bash -c "flutter --version | grep -q '3.41.4'"
check "dart reports a version" bash -c "dart --version 2>&1 | grep -Eio 'dart sdk version'"
check "java present (default installJdk)" bash -c "java -version 2>&1 | grep -Eio 'openjdk|version'"
check "sdk cache writable by runtime user" bash -c "test -w /opt/flutter/bin/cache"

reportResults
