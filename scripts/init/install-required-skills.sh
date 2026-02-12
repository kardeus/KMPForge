#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_LIST_FILE="$SCRIPT_DIR/required-skills.txt"

REPO_URL="https://github.com/kardeus/KMPForgeSkills.git"
BRANCH="main"
TARGET_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO_URL="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --root)
      TARGET_ROOT="$2"
      shift 2
      ;;
    --skills-file)
      SKILL_LIST_FILE="$2"
      shift 2
      ;;
    -h|--help)
      cat <<'EOT'
Usage:
  ./scripts/init/install-required-skills.sh [--repo <url>] [--branch <name>] [--root <dir>] [--skills-file <file>]

Defaults:
  --repo   https://github.com/kardeus/KMPForgeSkills.git
  --branch main
  --root   ${CODEX_HOME:-$HOME/.codex}/skills
EOT
      exit 0
      ;;
    *)
      echo "[ERROR] unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$SKILL_LIST_FILE" ]]; then
  echo "[ERROR] skills list file not found: $SKILL_LIST_FILE" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "[ERROR] git command not found" >&2
  exit 1
fi

mkdir -p "$TARGET_ROOT"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "[INFO] cloning skills repo: $REPO_URL (branch: $BRANCH)"
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$tmp_dir/repo" >/dev/null

installed=0
missing=0

while IFS= read -r skill || [[ -n "$skill" ]]; do
  [[ -z "$skill" ]] && continue
  [[ "$skill" =~ ^# ]] && continue

  src="$tmp_dir/repo/$skill"
  dst="$TARGET_ROOT/$skill"

  if [[ ! -d "$src" ]]; then
    echo "[MISS] skill not found in repo: $skill"
    missing=$((missing + 1))
    continue
  fi

  mkdir -p "$dst"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$src/" "$dst/"
  else
    find "$dst" -mindepth 1 -delete
    cp -R "$src/." "$dst/"
  fi

  echo "[INSTALLED] $skill -> $dst"
  installed=$((installed + 1))
done < "$SKILL_LIST_FILE"

echo "[SUMMARY] installed=$installed missing=$missing root=$TARGET_ROOT"

if (( missing > 0 )); then
  echo "[ERROR] some required skills are missing in $REPO_URL" >&2
  exit 2
fi

echo "[OK] required skills installed"
