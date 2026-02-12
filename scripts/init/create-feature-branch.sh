#!/usr/bin/env bash
set -euo pipefail

BRANCH_SUFFIX="${1:-}"
if [[ -z "$BRANCH_SUFFIX" ]]; then
  echo "usage: $0 <ticket-or-topic>"
  exit 1
fi

BRANCH_NAME="feature/$BRANCH_SUFFIX"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "[ERROR] git repository가 아닙니다."
  exit 1
}

git checkout -b "$BRANCH_NAME"
echo "[OK] created branch: $BRANCH_NAME"
