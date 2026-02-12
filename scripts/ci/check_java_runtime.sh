#!/usr/bin/env bash
set -euo pipefail

MIN_MAJOR="${1:-11}"
RECOMMENDED_MAJOR="${2:-17}"

if ! command -v java >/dev/null 2>&1; then
  echo "[ERROR] java 명령을 찾을 수 없습니다. JDK ${MIN_MAJOR}+를 설치하세요." >&2
  exit 1
fi

raw_version="$(java -version 2>&1 | head -n 1 || true)"
ver_token="$(java -version 2>&1 | awk -F '"' '/version/ {print $2; exit}')"

if [[ -z "$ver_token" ]]; then
  echo "[ERROR] Java 버전을 파싱할 수 없습니다: $raw_version" >&2
  exit 1
fi

major="${ver_token%%.*}"
if [[ "$major" == "1" ]]; then
  rest="${ver_token#1.}"
  major="${rest%%.*}"
fi

if ! [[ "$major" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] Java 메이저 버전을 파싱할 수 없습니다: $ver_token" >&2
  exit 1
fi

if (( major < MIN_MAJOR )); then
  cat >&2 <<EOT
[ERROR] 현재 JVM이 Java ${major} (${ver_token}) 입니다.
AGP 8.11.2 / Ktor 3.3.3 / Compose 1.10.0 템플릿은 Java ${MIN_MAJOR}+가 필요합니다. (권장: ${RECOMMENDED_MAJOR})

조치 예시:
- macOS (Homebrew): brew install openjdk@${RECOMMENDED_MAJOR}
- zsh:
  export JAVA_HOME="$(/usr/libexec/java_home -v ${RECOMMENDED_MAJOR} 2>/dev/null || true)"
  export PATH="$JAVA_HOME/bin:$PATH"

확인:
  java -version
  ./gradlew --version
EOT
  exit 1
fi

if (( major < RECOMMENDED_MAJOR )); then
  echo "[WARN] Java ${major} 감지됨. 최소 요구사항은 충족하지만 Java ${RECOMMENDED_MAJOR}+ 권장을 권장합니다." >&2
fi

echo "[OK] Java runtime check passed: ${ver_token}"
