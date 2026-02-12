#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

mkdir -p "$TARGET_DIR/scripts/ci"

copy_file() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  chmod +x "$dst"
  echo "[COPY] $dst"
}

copy_file "$FORGE_ROOT/scripts/apply_kotlin_signature_header.sh" "$TARGET_DIR/scripts/apply_kotlin_signature_header.sh"
copy_file "$FORGE_ROOT/scripts/deploy-server.sh" "$TARGET_DIR/scripts/deploy-server.sh"
copy_file "$FORGE_ROOT/scripts/ci/build_health_check.sh" "$TARGET_DIR/scripts/ci/build_health_check.sh"
copy_file "$FORGE_ROOT/scripts/ci/pre_pr.sh" "$TARGET_DIR/scripts/ci/pre_pr.sh"
copy_file "$FORGE_ROOT/scripts/ci/pr_create.sh" "$TARGET_DIR/scripts/ci/pr_create.sh"

echo "[OK] project scripts installed: $TARGET_DIR/scripts"
