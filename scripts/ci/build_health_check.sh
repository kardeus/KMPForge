#!/usr/bin/env bash
set -uo pipefail

usage() {
  cat <<'EOT'
Usage:
  ./scripts/ci/build_health_check.sh [--quick] [--skip-android] [--skip-server] [--report <file>]

Options:
  --quick         빠른 점검 모드 (help + shared compile + server classes)
  --skip-android  Android assemble 점검 생략
  --skip-server   server 관련 점검 생략
  --report <file> 결과 요약을 파일로 저장
EOT
}

QUICK=false
SKIP_ANDROID=false
SKIP_SERVER=false
REPORT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quick) QUICK=true; shift ;;
    --skip-android) SKIP_ANDROID=true; shift ;;
    --skip-server) SKIP_SERVER=true; shift ;;
    --report)
      REPORT_FILE="${2:-}"
      if [[ -z "$REPORT_FILE" ]]; then
        echo "[ERROR] --report requires file path"
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "./gradlew" ]]; then
  echo "[ERROR] gradlew not found. 프로젝트 루트에서 실행하세요."
  exit 1
fi

chmod +x ./gradlew >/dev/null 2>&1 || true

declare -a results=()
fail_count=0

run_step() {
  local name="$1"
  local cmd="$2"

  echo "[RUN] $name"
  local start end elapsed
  start=$(date +%s)

  if bash -lc "$cmd"; then
    end=$(date +%s)
    elapsed=$((end - start))
    results+=("PASS|$name|${elapsed}s")
    echo "[PASS] $name (${elapsed}s)"
  else
    end=$(date +%s)
    elapsed=$((end - start))
    results+=("FAIL|$name|${elapsed}s")
    fail_count=$((fail_count + 1))
    echo "[FAIL] $name (${elapsed}s)"
  fi
}

if [[ -x "./scripts/ci/check_java_runtime.sh" ]]; then
  run_step "Java runtime (11+ required, 17 recommended)" "./scripts/ci/check_java_runtime.sh 11 17"
fi

run_step "Gradle version" "./gradlew --version"

if [[ "$QUICK" == "true" ]]; then
  run_step "Gradle help" "./gradlew -q help"
  if [[ -d "./shared" ]]; then
    run_step "Shared compile (JVM)" "./gradlew :shared:compileKotlinJvm"
  fi
  if [[ "$SKIP_SERVER" != "true" && -d "./server" ]]; then
    run_step "Server classes" "./gradlew :server:classes"
  fi
else
  run_step "All tests" "./gradlew test"
  if [[ "$SKIP_SERVER" != "true" && -d "./server" ]]; then
    run_step "Server tests" "./gradlew :server:test"
  fi
  if [[ "$SKIP_ANDROID" != "true" && -d "./composeApp" ]]; then
    run_step "Android debug assemble" "./gradlew :composeApp:assembleDebug"
  fi
fi

echo
echo "=== Build Health Summary ==="
for item in "${results[@]}"; do
  IFS='|' read -r status name elapsed <<<"$item"
  echo "- [$status] $name ($elapsed)"
done
echo "Failures: $fail_count"

if [[ -n "$REPORT_FILE" ]]; then
  mkdir -p "$(dirname "$REPORT_FILE")"
  {
    echo "# Build Health Report"
    echo
    echo "- Quick mode: $QUICK"
    echo "- Skip Android: $SKIP_ANDROID"
    echo "- Skip Server: $SKIP_SERVER"
    echo
    for item in "${results[@]}"; do
      IFS='|' read -r status name elapsed <<<"$item"
      echo "- [$status] $name ($elapsed)"
    done
    echo
    echo "Failures: $fail_count"
  } > "$REPORT_FILE"
  echo "[INFO] report saved: $REPORT_FILE"
fi

if [[ "$fail_count" -gt 0 ]]; then
  exit 1
fi

exit 0
