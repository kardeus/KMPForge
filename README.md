# KMPForge

Kotlin Multiplatform(KMP) 프로젝트를 한 번에 초기화하는 CLI입니다.

## 설치 (GitHub 원라인)
```bash
curl -fsSL https://raw.githubusercontent.com/<org>/KMPForge/main/install.sh | \
KMPFORGE_REPO_URL=https://github.com/<org>/KMPForge.git bash
```

## 설치 (로컬 저장소에서)
```bash
cd KMPForge
bash install.sh
```

## 사용법
```bash
kmpforge help
kmpforge init --name MyApp --package com.example.myapp --target ./MyApp
kmpforge doctor --target ./MyApp
```

## `init`가 자동으로 하는 작업
- 기본 모듈 디렉토리 생성 (`composeApp`, `shared`, `docs`, 선택적으로 `server`, `iosApp`)
- `AGENTS.md` 템플릿 복사
- `docs/00-policy` 기본 정책 문서 생성
- GitHub workflow 생성 (`ci.yml`, `pr-guard.yml`, `PULL_REQUEST_TEMPLATE.md`)
- `.githooks` 생성 및 git repo인 경우 `core.hooksPath=.githooks` 자동 설정
- 필수 스킬 심볼릭 링크 동기화

## Skill 심볼릭 동기화
- 소스: `scripts/init/required-skills.txt`
- 타깃: `<project>/skills/<skill>` 심볼릭 링크
- 탐색 경로:
  - `$CODEX_HOME/skills`
  - `$HOME/AgentTools/skills`
  - `$HOME/.codex/skills`
  - `/Users/jin/AgentTools/skills`
- 누락 시 스크립트가 필요한 스킬 목록과 AI Agent 액션 가이드를 출력한다.

수동 실행:
```bash
kmpforge sync-skills --target ./MyApp
```

## 권장 운영 루프
1. `pdca-model-router`
2. `pdca-runner`
3. 구현/테스트
4. `docs-policy-organizer`
