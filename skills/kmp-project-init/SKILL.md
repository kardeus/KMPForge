# kmp-project-init

## 목적
신규 KMP 저장소를 표준 구조와 운영 규칙으로 빠르게 초기화한다.

## 입력
- 프로젝트 이름
- 베이스 패키지
- iOS/server 포함 여부
- 타깃 디렉토리

## 실행 절차
1. `scripts/init/config.template.env`를 복사해 `config.env`를 만든다.
2. 변수 값을 채운다.
3. `bash scripts/init/bootstrap-kmp.sh scripts/init/config.env` 실행
4. `bash scripts/init/setup-docs-policy.sh <targetDir>` 실행
5. `bash scripts/init/setup-ci.sh <targetDir>` 실행
6. `<targetDir>/AGENTS.md`를 프로젝트 상황에 맞게 배포한다.
7. 가능하면 `bash scripts/init/verify-init.sh <targetDir>` 실행

## 산출물
- 표준 모듈 디렉토리
- 정책 문서 베이스
- CI 워크플로
- 초기화 로그
