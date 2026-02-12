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

cat > "$ROOT_DIR/.github/workflows/pr-guard.yml" <<'EOT'
name: PR Guard

on:
  pull_request:
    branches: [ "main" ]
    types: [opened, edited, synchronize, reopened]

jobs:
  guard:
    runs-on: ubuntu-latest
    steps:
      - name: Check PR title
        uses: actions/github-script@v7
        with:
          script: |
            const title = context.payload.pull_request?.title || "";
            if (title.trim().length < 8) {
              core.setFailed("PR title must be at least 8 characters.");
            }

      - name: Check source branch naming
        uses: actions/github-script@v7
        with:
          script: |
            const ref = context.payload.pull_request?.head?.ref || "";
            const ok = /^(feature|hotfix|chore|fix)\/.+$/.test(ref);
            if (!ok) {
              core.setFailed(`Invalid branch name: ${ref}. Use feature/*, hotfix/*, chore/*, or fix/*`);
            }
EOT

cat > "$ROOT_DIR/.github/PULL_REQUEST_TEMPLATE.md" <<'EOT'
## Summary
- 

## Why
- 

## Changes
- 

## Testing
- [ ] `./gradlew test`
- [ ] `./gradlew :composeApp:assembleDebug`
- [ ] `./gradlew :server:test` (if server changed)

## Scope
- [ ] Mobile (`shared`, `composeApp`, `iosApp`)
- [ ] Server (`server`)
- [ ] Docs/Policy (`docs/00-policy`)
EOT

echo "[OK] git workflows generated:"
echo " - $ROOT_DIR/.github/workflows/ci.yml"
echo " - $ROOT_DIR/.github/workflows/pr-guard.yml"
echo " - $ROOT_DIR/.github/PULL_REQUEST_TEMPLATE.md"
