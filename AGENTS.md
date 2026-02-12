# AGENTS.md (KMPForge Base)

## 응답 규칙
- 답변은 항상 한국어로 작성한다.
- 구현/검증 결과는 실행 명령 중심으로 간결하게 보고한다.

## 프로젝트 표준 구조
- `composeApp/` : Compose Multiplatform UI (Android + shared UI)
- `shared/` : 공통 비즈니스 로직/도메인
- `server/` : Ktor 서버
- `iosApp/` : iOS Wrapper
- `docs/` : Plan/Design/Analysis/Report + 정책 문서
- `scripts/` : 자동화 스크립트

## 빌드/테스트 기준 명령
- `./gradlew test`
- `./gradlew :composeApp:assembleDebug`
- `./gradlew :server:test`
- `./gradlew :server:run`

## Skill 동기화 규칙
- 프로젝트 시작 직후 `bash scripts/init/sync-required-skills.sh .`를 실행해 필요한 스킬을 `skills/`에 심볼릭 링크한다.
- 스킬 누락 시 스크립트가 누락 목록과 AI Agent 액션 가이드를 출력하며, 누락 스킬 설치 후 재실행한다.

## 브랜치/커밋 규칙
- 기능 작업 시작 시 `feature/*` 브랜치를 생성한다.
- 기능 코드 + 정책 문서 업데이트를 원칙적으로 1회 커밋으로 반영한다.
- 이미 push 이후 정책 누락 발견 시에만 추가 커밋을 허용한다.
- `.githooks`를 사용해 main/master 직접 커밋 차단 및 기본 커밋 품질 가드를 적용한다.

## PDCA 작업 규칙
- 반드시 `pdca-model-router`를 먼저 실행한 뒤 `pdca-runner`를 실행한다.
- 소규모 국소 수정 발견 시 `pdca-model-router`를 재실행해 fast-path를 적용한다.
- 아키텍처/보안/계약 변경 가능성이 있으면 default 경로로 수행한다.

## 리뷰 스킬 적용 규칙
- 모바일 변경(`shared`, `composeApp`, `iosApp`) 포함: `kmp-mobile-reviewer`
- 서버 변경(`server`) 포함: `kotlin-server-reviewer`
- 혼합 변경: 두 스킬 모두 적용해 영역 분리 리뷰

## 문서 정책 업데이트 규칙
- 사용자가 `정책 업데이트해줘`를 요청하면 `docs-policy-organizer`를 사용한다.
- PDCA 완료 후 `docs-policy-organizer`를 먼저 실행해 `docs/00-policy`를 최신화한다.
- 구조 변경 + dependency 변경(`libs.versions.toml`, `*.gradle.kts`, `gradle.properties`, `settings.gradle.kts`) 시 변경 이유/영향 범위를 `docs/00-policy`에 기록한다.

## 서버 관련 규칙
- 서버 개발 시 `docs` 내 ERD/API 계약 문서를 기준으로 개발한다.
- 엔티티/스키마/API 계약 변경이 있으면 ERD 문서를 함께 갱신한다.
- 서버 배포 작업이 포함되면 `./scripts/deploy-server.sh`를 실행한다.

## 피처 완료 체크리스트
- [ ] `pdca-model-router` 실행
- [ ] `pdca-runner` 실행 및 산출물 점검
- [ ] 구현/테스트 완료
- [ ] 필요 시 회귀 테스트 재수행
- [ ] `feature/*` 브랜치에서 작업
- [ ] 리뷰 스킬 적용 완료
- [ ] `docs-policy-organizer` 실행
- [ ] 정책 문서 반영 확인
- [ ] commit / push / PR(main)
- [ ] PR 완료 후 local branch 삭제
