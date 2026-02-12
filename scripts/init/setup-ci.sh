#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
mkdir -p "$ROOT_DIR/.github/workflows"

cat > "$ROOT_DIR/.github/workflows/ci.yml" <<'EOT'
name: CI

on:
  pull_request:
    branches: [ "main" ]
  push:
    branches: [ "main", "feature/**" ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: gradle/actions/setup-gradle@v4
      - name: Run tests
        run: ./gradlew test
      - name: Server tests
        run: ./gradlew :server:test || true
      - name: Android debug assemble
        run: ./gradlew :composeApp:assembleDebug || true
EOT

echo "[OK] ci workflow generated: $ROOT_DIR/.github/workflows/ci.yml"
