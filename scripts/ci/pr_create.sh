#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

"${SCRIPT_DIR}/pre_pr.sh"

cd "${REPO_ROOT}"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

tmp_body_file=""
cleanup() {
  if [[ -n "${tmp_body_file}" && -f "${tmp_body_file}" ]]; then
    rm -f "${tmp_body_file}"
  fi
}
trap cleanup EXIT

normalized_args=()
i=1
while [[ ${i} -le $# ]]; do
  arg="${!i}"
  case "${arg}" in
    --body|-b)
      i=$((i + 1))
      if [[ ${i} -gt $# ]]; then
        echo "오류: ${arg} 옵션에는 본문 값이 필요합니다." >&2
        exit 1
      fi
      body_value="${!i}"
      if [[ -z "${tmp_body_file}" ]]; then
        tmp_body_file="$(mktemp "${TMPDIR:-/tmp}/pr-body.XXXXXX.md")"
      fi
      printf '%b' "${body_value}" > "${tmp_body_file}"
      normalized_args+=("--body-file" "${tmp_body_file}")
      ;;
    --body=*)
      body_value="${arg#--body=}"
      if [[ -z "${tmp_body_file}" ]]; then
        tmp_body_file="$(mktemp "${TMPDIR:-/tmp}/pr-body.XXXXXX.md")"
      fi
      printf '%b' "${body_value}" > "${tmp_body_file}"
      normalized_args+=("--body-file" "${tmp_body_file}")
      ;;
    *)
      normalized_args+=("${arg}")
      ;;
  esac
  i=$((i + 1))
done

gh pr create "${normalized_args[@]}"

if [[ "${CURRENT_BRANCH}" == "HEAD" ]]; then
  echo "detached HEAD 상태이므로 로컬 브랜치 삭제를 건너뜁니다."
  exit 0
fi

if [[ ! "${CURRENT_BRANCH}" =~ ^feature/ ]]; then
  echo "현재 브랜치(${CURRENT_BRANCH})가 feature/* 규칙이 아니므로 로컬 브랜치 삭제를 건너뜁니다."
  exit 0
fi

DEFAULT_BRANCH="$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || echo "main")"
echo "PR 생성 완료. ${CURRENT_BRANCH} 삭제를 위해 ${DEFAULT_BRANCH} 브랜치로 전환합니다."

if git show-ref --verify --quiet "refs/heads/${DEFAULT_BRANCH}"; then
  git checkout "${DEFAULT_BRANCH}"
elif git show-ref --verify --quiet "refs/remotes/origin/${DEFAULT_BRANCH}"; then
  git checkout -b "${DEFAULT_BRANCH}" "origin/${DEFAULT_BRANCH}"
else
  echo "기본 브랜치(${DEFAULT_BRANCH})를 찾지 못해 로컬 브랜치 삭제를 건너뜁니다."
  exit 0
fi

git branch -D "${CURRENT_BRANCH}"
echo "로컬 브랜치 삭제 완료: ${CURRENT_BRANCH}"
