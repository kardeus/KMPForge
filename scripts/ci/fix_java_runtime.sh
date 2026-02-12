#!/usr/bin/env bash
set -euo pipefail

TARGET_MAJOR="${1:-17}"
APPLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=true
      shift
      ;;
    --help|-h)
      cat <<'EOT'
Usage:
  ./scripts/ci/fix_java_runtime.sh [targetMajor] [--apply]

Examples:
  ./scripts/ci/fix_java_runtime.sh 17 --apply
EOT
      exit 0
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        TARGET_MAJOR="$1"
        shift
      else
        echo "[ERROR] unknown option: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ "$OSTYPE" != darwin* ]]; then
  echo "[ERROR] 현재 자동 보정은 macOS 기준으로 제공됩니다." >&2
  echo "Linux/Windows는 JAVA_HOME을 수동 설정하세요." >&2
  exit 1
fi

if ! command -v /usr/libexec/java_home >/dev/null 2>&1; then
  echo "[ERROR] /usr/libexec/java_home 명령을 찾을 수 없습니다." >&2
  exit 1
fi

JAVA_HOME_CANDIDATE="$(/usr/libexec/java_home -v "$TARGET_MAJOR" 2>/dev/null || true)"
if [[ -z "$JAVA_HOME_CANDIDATE" ]]; then
  echo "[ERROR] JDK $TARGET_MAJOR 가 설치되어 있지 않습니다." >&2
  echo "설치 후 재실행하세요. (예: brew install openjdk@$TARGET_MAJOR)" >&2
  exit 1
fi

if [[ "$APPLY" != "true" ]]; then
  echo "[INFO] detected JAVA_HOME candidate: $JAVA_HOME_CANDIDATE"
  echo "[INFO] 적용하려면 --apply 옵션을 사용하세요."
  exit 0
fi

SHELL_NAME="$(basename "${SHELL:-zsh}")"
if [[ "$SHELL_NAME" == "bash" ]]; then
  RC_FILE="$HOME/.bashrc"
else
  RC_FILE="$HOME/.zshrc"
fi

mkdir -p "$(dirname "$RC_FILE")"
touch "$RC_FILE"

START_MARK="# >>> KMPForge JAVA_HOME >>>"
END_MARK="# <<< KMPForge JAVA_HOME <<<"

TMP_FILE="$(mktemp)"
awk -v s="$START_MARK" -v e="$END_MARK" '
  BEGIN { skip=0 }
  $0==s { skip=1; next }
  $0==e { skip=0; next }
  skip==0 { print }
' "$RC_FILE" > "$TMP_FILE"

cat >> "$TMP_FILE" <<EOT
$START_MARK
export JAVA_HOME="$JAVA_HOME_CANDIDATE"
export PATH="\$JAVA_HOME/bin:\$PATH"
$END_MARK
EOT

mv "$TMP_FILE" "$RC_FILE"

echo "[OK] JAVA_HOME updated in $RC_FILE"
echo "[INFO] 현재 쉘에 즉시 적용하려면:"
echo "source $RC_FILE"
echo "java -version"
