#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${REPO_ROOT}"

echo "Checking required commands..."
for cmd in git gh; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "필수 명령이 없습니다: $cmd" >&2
    exit 1
  fi
done

echo "Checking gh auth status..."
if ! gh auth status >/dev/null 2>&1; then
  echo "gh 인증 상태가 아닙니다. 먼저 'gh auth login'을 수행하세요." >&2
  exit 1
fi

echo "Checking git working tree..."
if [[ -n "$(git status --porcelain)" ]]; then
  echo "작업 트리가 깨끗하지 않습니다. 커밋/정리 후 PR을 생성하세요." >&2
  git status --short >&2
  exit 1
fi

current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
  echo "main/master 브랜치에서 직접 PR 생성은 금지합니다. feature/* 브랜치를 사용하세요." >&2
  exit 1
fi

echo "Pre-PR checks passed."
