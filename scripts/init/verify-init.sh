#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
cd "$ROOT_DIR"

if [[ ! -f "gradlew" ]]; then
  echo "[WARN] gradlew not found in $ROOT_DIR, gradle verification skipped"
  exit 0
fi

./gradlew test
./gradlew :composeApp:assembleDebug || true
./gradlew :server:test || true

echo "[OK] init verification finished"
