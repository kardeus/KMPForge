#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
mkdir -p "$ROOT_DIR/docs/00-policy"

cat > "$ROOT_DIR/docs/00-policy/README.md" <<'EOT'
# 00-policy

이 디렉토리는 완료된 기능의 정책/운영 기준을 압축 기록합니다.

## 기록 원칙
- Why: 변경 이유
- What: 정책/설계 핵심
- Impact: 영향 범위(모듈/의존성/API)
- Guardrail: 재발 방지 규칙

## 필수 업데이트 트리거
- 아키텍처 변경
- 의존성 버전/구성 변경
- 서버 계약(엔티티/스키마/API) 변경
EOT

echo "[OK] docs policy initialized: $ROOT_DIR/docs/00-policy"
