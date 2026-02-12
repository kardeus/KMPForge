# KMPForge

Kotlin Multiplatform(KMP) 프로젝트를 한 번에 초기화하는 CLI입니다.

## 기준 버전 (Template Baseline)
- Java Runtime: 최소 `11+`, 권장 `17+`
- Android Studio: `Android Studio Otter 3 Feature Drop | 2025.2.3`
- Gradle Wrapper: `8.14.3`
- Kotlin: `2.3.0`
- Android Gradle Plugin (AGP): `8.11.2`
- Compose Multiplatform: `1.10.0`
- Ktor: `3.3.3`
- Logback: `1.5.24`
- Android SDK:
  - `compileSdk = 36`
  - `targetSdk = 36`
  - `minSdk = 24`

참고: 위 값은 KMPForge 내장 템플릿(`templates/kmp-base`) 기준이며, 템플릿이 바뀌면 함께 갱신해야 합니다.

## 설치 (GitHub 원라인)
```bash
git clone https://github.com/kardeus/KMPForge.git /tmp/KMPForge && \
bash /tmp/KMPForge/install.sh && \
rm -rf /tmp/KMPForge
```

## 설치 (로컬 저장소에서)
```bash
cd KMPForge
bash install.sh
```

`install.sh`는 기본적으로 아래를 자동 수행합니다.
- `kmpforge` CLI 설치/업데이트
- 필수 스킬 자동 설치 (`https://github.com/kardeus/KMPForgeSkills.git`, branch `main`)

자동 스킬 설치를 끄려면:
```bash
KMPFORGE_INSTALL_SKILLS=false bash install.sh
```

스킬 설치 실패를 무시하고 CLI 설치만 진행하려면:
```bash
KMPFORGE_ALLOW_SKILL_INSTALL_FAILURE=true bash install.sh
```

## 업데이트 (이미 설치한 사용자)
```bash
# 기본 설치 경로(~/.kmpforge)를 사용하는 경우
bash ~/.kmpforge/install.sh
```

```bash
# 커스텀 설치 경로를 사용한 경우
KMPFORGE_HOME=/custom/path/kmpforge bash /custom/path/kmpforge/install.sh
```

업데이트 후 현재 버전 확인:
```bash
kmpforge help
```

## 사용법
```bash
kmpforge help
kmpforge init --name MyApp --package com.example.myapp --target ./MyApp
kmpforge install-scripts --target ./MyApp
kmpforge doctor --target ./MyApp
```

## 설치 후 Task 실행 방법
1. Codex/Claude 같은 AI CLI를 프로젝트 루트에서 실행한다.
2. 현재 프로젝트에서 사용 가능한 스킬 목록을 확인한다.
```bash
# 현재 이 프로젝트에서 사용 가능한 스킬 목록입니다.
1. docs-policy-organizer
2. kmp-mobile-dev
3. kmp-mobile-reviewer
4. kotlin-server-reviewer
5. mobile-mcp-emulator-test
6. pdca-model-router
7. pdca-runner
```
3. Task를 입력한다.
```bash
pdca-runner 간단한 계산기를 만들어줘
```
4. AI Agent가 Plan/Do/Check/Act 순서로 수행하도록 진행한다.
5. Android Studio에서 생성/수정 결과를 열어 확인한다.

커스텀 템플릿 경로를 명시하려면:
```bash
kmpforge init --name MyApp --package com.example.myapp --target ./MyApp --template-source /path/to/template
```

## `init`가 자동으로 하는 작업
- 기본 모듈 디렉토리 생성 (`composeApp`, `shared`, `docs`, 선택적으로 `server`, `iosApp`)
- (기본) KMPForge 내장 템플릿(`templates/kmp-base`)으로 Android/iOS/Server KMP 기본 파일 세트를 생성
- `AGENTS.md` 템플릿 복사
- 운영 스크립트 설치 (`scripts/apply_kotlin_signature_header.sh`, `scripts/ci/pre_pr.sh`, `scripts/ci/pr_create.sh`, `scripts/deploy-server.sh`)
- `docs/00-policy` 기본 정책 문서 생성
- GitHub workflow 생성 (`ci.yml`, `pr-guard.yml`, `PULL_REQUEST_TEMPLATE.md`)
- `.githooks` 생성 및 git repo인 경우 `core.hooksPath=.githooks` 자동 설정
- 필수 스킬 심볼릭 링크 동기화

## Skill 심볼릭 동기화
- 소스: `scripts/init/required-skills.txt`
- 타깃: `<project>/skills/<skill>` 심볼릭 링크
- 탐색 경로:
  - `$KMPFORGE_SKILLS_ROOT` (설정된 경우)
  - `${KMPFORGE_HOME:-$HOME/.kmpforge}/skills`
  - `$CODEX_HOME/skills`
  - `$HOME/AgentTools/skills`
  - `$HOME/.codex/skills`
- 누락 시 스크립트가 필요한 스킬 목록과 AI Agent 액션 가이드를 출력한다.

수동 실행:
```bash
kmpforge sync-skills --target ./MyApp
```

필수 스킬을 원격 저장소에서 설치 + 심볼릭 동기화:
```bash
kmpforge install-skills \
  --target ./MyApp \
  --repo https://github.com/kardeus/KMPForgeSkills.git \
  --branch main
```

설치 루트(기본 `~/.kmpforge/skills`)를 커스텀하려면:
```bash
kmpforge install-skills \
  --target ./MyApp \
  --repo https://github.com/kardeus/KMPForgeSkills.git \
  --root /custom/skills/root
```

## Skill 사용 시점 (TalkAbout 패턴)
- Plan 시작: `pdca-model-router` 실행 후 `pdca-runner`
- Do(개발): `kmp-mobile-dev`
- Check(모바일 회귀): `mobile-mcp-emulator-test`
- Check(리뷰): 변경 범위에 따라 `kmp-mobile-reviewer` / `kotlin-server-reviewer`
- Act(문서 정책): `docs-policy-organizer`
- 정책 업데이트 요청(`정책 업데이트해줘`): `docs-policy-organizer` 필수

## 권장 운영 루프
1. `pdca-model-router`
2. `pdca-runner`
3. 구현/테스트
4. `docs-policy-organizer`

## 보조 스크립트
- Kotlin 헤더 일괄 적용: `scripts/apply_kotlin_signature_header.sh`
- Java 런타임 점검: `scripts/ci/check_java_runtime.sh`
- Java 런타임 자동 보정(macOS): `scripts/ci/fix_java_runtime.sh` 또는 `scripts/ci/check_java_runtime.sh 11 17 --auto-fix`
- 빌드 헬스체크: `scripts/ci/build_health_check.sh`
- PR 사전 점검: `scripts/ci/pre_pr.sh`
- PR 생성 자동화: `scripts/ci/pr_create.sh`
- 서버 배포(docker compose 기반): `scripts/deploy-server.sh`
