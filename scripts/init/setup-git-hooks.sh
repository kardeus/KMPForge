#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
HOOK_DIR="$ROOT_DIR/.githooks"

mkdir -p "$HOOK_DIR"

cat > "$HOOK_DIR/pre-commit" <<'EOT'
#!/usr/bin/env bash
set -euo pipefail

branch_name="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
if [[ "$branch_name" == "main" || "$branch_name" == "master" ]]; then
  echo "[BLOCK] main/master 브랜치 직접 커밋은 금지됩니다."
  echo "feature/* 브랜치에서 작업하세요."
  exit 1
fi

# Block common secret/config files from being committed.
blocked_patterns='(^|/)local\.properties$|(^|/)\.env$|\.keystore$|\.jks$|(^|/)google-services\.json$|(^|/)GoogleService-Info\.plist$'
if git diff --cached --name-only | grep -E "$blocked_patterns" >/dev/null 2>&1; then
  echo "[BLOCK] 민감/로컬 설정 파일이 staged 상태입니다."
  echo "staged 파일에서 제거 후 다시 커밋하세요."
  exit 1
fi

exit 0
EOT

cat > "$HOOK_DIR/commit-msg" <<'EOT'
#!/usr/bin/env bash
set -euo pipefail

msg_file="$1"
msg="$(head -n 1 "$msg_file" | tr -d '\r')"

if [[ -z "$msg" ]]; then
  echo "[BLOCK] 커밋 메시지가 비어 있습니다."
  exit 1
fi

if [[ ${#msg} -lt 8 ]]; then
  echo "[BLOCK] 커밋 메시지는 최소 8자 이상으로 작성하세요."
  exit 1
fi

exit 0
EOT

cat > "$HOOK_DIR/pre-push" <<'EOT'
#!/usr/bin/env bash
set -euo pipefail

if [[ -f "./gradlew" ]]; then
  echo "[INFO] pre-push: running ./gradlew test"
  ./gradlew test
else
  echo "[INFO] pre-push: gradlew not found, skip"
fi
EOT

chmod +x "$HOOK_DIR/pre-commit" "$HOOK_DIR/commit-msg" "$HOOK_DIR/pre-push"

if git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$ROOT_DIR" config core.hooksPath .githooks
  echo "[OK] git hooks configured: core.hooksPath=.githooks"
else
  echo "[WARN] $ROOT_DIR 는 git repo가 아닙니다."
  echo "git init 이후 아래를 실행하세요:"
  echo "git -C $ROOT_DIR config core.hooksPath .githooks"
fi

echo "[OK] git hooks generated: $HOOK_DIR"
