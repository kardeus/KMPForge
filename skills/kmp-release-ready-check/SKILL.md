# kmp-release-ready-check

## 목적
릴리즈 전 필수 품질 게이트를 표준화한다.

## 필수 게이트
1. 빌드/테스트
- `./gradlew test`
- `./gradlew :composeApp:assembleDebug`
- `./gradlew :server:test` (서버 모듈 사용 시)

2. 문서/정책
- PDCA 산출물 누락 여부
- `docs/00-policy` 최신화 여부

3. 리뷰 스킬 적용
- 모바일 변경: `kmp-mobile-reviewer`
- 서버 변경: `kotlin-server-reviewer`
- 혼합: 두 스킬 모두

4. 배포 준비
- 서버 배포 태스크 포함 시 `./scripts/deploy-server.sh` 실행 계획 존재 여부

## 결과
- PASS/FAIL
- 실패 항목별 수정 TODO
- 재검증 명령
