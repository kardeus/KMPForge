#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SERVICE="${SERVICE:-server}"
CONTAINER_NAME="${CONTAINER_NAME:-kmpforge-server}"
HEALTH_URL="${HEALTH_URL:-http://localhost:8081/api/health}"
MAX_RETRIES="${MAX_RETRIES:-30}"
SLEEP_SECONDS="${SLEEP_SECONDS:-2}"

log() {
  printf '[deploy-server] %s\n' "$*"
}

ensure_docker_running() {
  if docker info >/dev/null 2>&1; then
    return 0
  fi

  log "Docker 데몬이 실행 중이 아닙니다. 자동 기동을 시도합니다."
  local os_name
  os_name="$(uname -s)"

  case "$os_name" in
    Darwin)
      if command -v open >/dev/null 2>&1; then
        open -a Docker >/dev/null 2>&1 || true
      fi
      ;;
    Linux)
      if command -v systemctl >/dev/null 2>&1; then
        systemctl --user start docker >/dev/null 2>&1 || true
        systemctl start docker >/dev/null 2>&1 || true
      elif command -v service >/dev/null 2>&1; then
        service docker start >/dev/null 2>&1 || true
      fi
      ;;
  esac

  local retries=60
  local sleep_seconds=2
  for ((i=1; i<=retries; i++)); do
    if docker info >/dev/null 2>&1; then
      log "Docker 데몬이 준비되었습니다. ($i/$retries)"
      return 0
    fi
    sleep "$sleep_seconds"
  done

  log "Docker 데몬 기동에 실패했습니다. Docker Desktop/daemon 상태를 확인해 주세요."
  return 1
}

if ! command -v docker >/dev/null 2>&1; then
  log "docker 명령을 찾을 수 없습니다."
  exit 1
fi

if ! ensure_docker_running; then
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  log "docker compose 사용이 불가능합니다."
  exit 1
fi

log "기존 서버 컨테이너를 완전히 중지/삭제합니다."
docker compose rm -sf "$SERVICE" >/dev/null 2>&1 || true

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

log "이미지를 빌드하고 서버를 기동합니다."
docker compose up -d --build "$SERVICE"

if ! command -v curl >/dev/null 2>&1; then
  log "curl이 없어 헬스체크를 건너뜁니다."
  docker compose ps
  exit 0
fi

log "헬스체크를 수행합니다: $HEALTH_URL"
for ((i=1; i<=MAX_RETRIES; i++)); do
  if body="$(curl -fsS "$HEALTH_URL" 2>/dev/null)"; then
    log "헬스체크 성공 ($i/$MAX_RETRIES): $body"
    docker compose ps
    exit 0
  fi
  sleep "$SLEEP_SECONDS"
done

log "헬스체크 실패. 최근 서버 로그를 출력합니다."
docker compose ps
docker logs --tail 120 "$CONTAINER_NAME" || true
exit 1
