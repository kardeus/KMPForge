#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_LIST_FILE="$SCRIPT_DIR/required-skills.txt"
TARGET_SKILLS_DIR="$TARGET_DIR/skills"

if [[ ! -f "$SKILL_LIST_FILE" ]]; then
  echo "[ERROR] required skills list not found: $SKILL_LIST_FILE"
  exit 1
fi

mkdir -p "$TARGET_SKILLS_DIR"

CANDIDATE_ROOTS=()
if [[ -n "${CODEX_HOME:-}" ]]; then
  CANDIDATE_ROOTS+=("$CODEX_HOME/skills")
fi
CANDIDATE_ROOTS+=("$HOME/AgentTools/skills" "$HOME/.codex/skills" "/Users/jin/AgentTools/skills")

find_skill_source() {
  local skill_name="$1"
  local root
  for root in "${CANDIDATE_ROOTS[@]}"; do
    if [[ -d "$root/$skill_name" ]]; then
      echo "$root/$skill_name"
      return 0
    fi
  done
  return 1
}

linked=0
skipped=0
missing=()

while IFS= read -r skill || [[ -n "$skill" ]]; do
  [[ -z "$skill" ]] && continue
  [[ "$skill" =~ ^# ]] && continue

  target_link="$TARGET_SKILLS_DIR/$skill"

  if source_path="$(find_skill_source "$skill")"; then
    if [[ -e "$target_link" && ! -L "$target_link" ]]; then
      echo "[SKIP] $skill: target exists and is not symlink -> $target_link"
      skipped=$((skipped + 1))
      continue
    fi

    ln -sfn "$source_path" "$target_link"
    echo "[LINK] $skill -> $source_path"
    linked=$((linked + 1))
  else
    missing+=("$skill")
    echo "[MISS] $skill: source skill not found"
  fi
done < "$SKILL_LIST_FILE"

echo "[SUMMARY] linked=$linked skipped=$skipped missing=${#missing[@]}"

if (( ${#missing[@]} > 0 )); then
  echo
  echo "[ACTION REQUIRED] 아래 스킬을 추가 설치한 뒤 다시 실행하세요:"
  for skill in "${missing[@]}"; do
    echo "- $skill"
  done
  echo
  echo "AI Agent 가이드:"
  echo "1) skill-installer 스킬로 누락 스킬 설치 요청"
  echo "2) 또는 조직 스킬 저장소(예: /Users/jin/AgentTools/skills)에 스킬 추가"
  echo "3) 완료 후 재실행: bash scripts/init/sync-required-skills.sh $TARGET_DIR"
  exit 2
fi

echo "[OK] required skills symlink sync complete"
