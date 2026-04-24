# Prompt — `ci-cd-pipeline` SKILL.md 생성 요청

## 역할
당신은 Claude 스킬 작성자입니다. **`ci-cd-pipeline` 스킬의 SKILL.md (v1.1)** 한 개 파일을 만드세요. 이 스킬은 GitHub 저장소에서 CI/CD 파이프라인을 **실제로 구현·검증·배포까지 완료**하는 전담 스킬입니다.

## 산출물 요구사항

### Frontmatter
- `name`: `ci-cd-pipeline`
- `description`: GitHub 저장소에서 **CI/CD 파이프라인(.github/workflows, Dockerfile, 배포 스크립트, PR 보호 규칙, 시크릿, smoke/보안 게이트 등)을 실제로 구현·검증·배포까지 완료**하는 전담 스킬(v1.1). `implement-top-issue` v1.3 하이브리드 모드에서 `[CI]`/`[CD]`/`[Security]`/`[Infra]`(v2 레거시) 카테고리 이슈가 감지되면 자동 위임되는 실행기이자 독립 슬래시 커맨드 모두 지원. 이슈의 `profile:staging`/`profile:prod` 레이블로 타겟 결정. `yamllint → actionlint → shellcheck → act` 로컬 검증 체인, 시크릿 화이트리스트 가드, `gh run watch --exit-status` 워크플로 모니터링, 스테이징 smoke 실패 시 자동 롤백까지 자동 수행. 트리거: "CI/CD 구현", "CI 파이프라인 구축", "CD 배포 파이프라인 만들어줘", "GitHub Actions 워크플로 작성", "배포 자동화", "스테이징/프로덕션 배포", "PR 보호 규칙 설정", "smoke test 자동화", "SAST/의존성 스캔 파이프라인", "/ci-cd-pipeline", "/run-ci-cd", "/implement-cicd-issue". 일반 기능 구현은 `implement-top-issue` 사용. 이슈 번호 없으면 먼저 묻기.

### 본문 구조

1. 제목: `# CI/CD 파이프라인 구현 스킬 v1.1`. 결과물: `.github/workflows/*.yml`, CODEOWNERS, Dockerfile*, fly.toml/render.yaml/vercel.json, deploy/**/*.sh, PR 보호 규칙, 상태 배지 README.
2. **슬래시 커맨드 표** 4개: `/ci-cd-pipeline --issue N`, `/run-ci-cd --issue N`, `/implement-cicd-issue N`(v1.3 위임 경로), `/ci-cd-pipeline --dry-run --issue N`.
3. **`implement-top-issue` v1.3과의 호출 계약** — `--cicd-mode` 플래그는 v1.3 쪽에서만 해석, 이 스킬에는 전달되지 않음. v1.3은 `/implement-cicd-issue N`로 위임. 이 스킬은 결과만 반환(순환 금지).
4. **범위 vs 비범위** — 다루는 작업(워크플로/PR 보호/CODEOWNERS/배지/labeler/dependabot/Docker/배포 매니페스트/배포 스크립트/스모크/보안 게이트/시크릿 등록 안내) vs 다루지 않는 작업(앱 비즈니스 로직/DB 마이그레이션 로직/TechSpec 작성/이슈 생성·보드).
5. **핵심 철학 — Green Pipeline First, Safety by Gates** ASCII 흐름도(이슈 → ① 저장소 점검 → ② 프로필 결정 → ③ 플랫폼 자동 감지 → ④ 피처 브랜치 → ⑤ 카테고리별 분기 → ⑥ 로컬 검증 체인 → ⑦ 시크릿 가드 → ⑧ 커밋+PR → ⑨ 머지 후 워크플로 모니터링 → ⑩ 성공 종결/실패 롤백).
6. **행동 원칙 12개** — 위임 가능 일방향, 카테고리 검증, Default 브랜치 동적, 로컬 검증 필수, 시크릿 리터럴 금지, 최소 1개 워크플로 변경, 프로필 게이트, 파일 모드 자동 선택(Edit/Write), 멱등성, 관측 가능, Conventional Commits(`ci(...)`/`cd(...)`/`sec(...)`), GitHub Flow.
7. **AI 시스템 프롬프트 — `/ci-cd-pipeline`** 한 단락.
8. **워크플로우** STEP 0 ~ STEP 10:
   - STEP 0 — 구분 고지 + 입력 검증(`--issue N` 없으면 묻기, gh auth, git 저장소 확인, `$DEFAULT` 추출).
   - STEP 1 — 이슈 로드 + 카테고리 판정. CI/CD/Security/Infra 레이블 + TITLE_KEYWORDS + BODY_PATH_HINTS로 5단 우선순위 판정 코드블록 제공.
   - STEP 2 — 저장소 상태 검사 + Default 브랜치 동기화(코드).
   - STEP 3 — 프로필 결정(`profile:staging`/`prod`/충돌 시 중단/추론).
   - STEP 4 — 플랫폼 자동 감지(fly.toml→fly, vercel.json→vercel, render.yaml→render, app.yaml→gcp-ae, cloudbuild.yaml→gcp-build, k8s, generic-docker, 미감지 시 사용자 선택).
   - STEP 5 — 피처 브랜치 생성(접두사 `ci/`/`cd/`/`sec/`, 한국어 slug 폴백 `issue-<N>`).
   - STEP 5' — 카테고리별 구현 분기 (Write/Edit 모드 자동 선택). 5.A `[CI]`(lint/test/PR 보호 + admin 권한 부족 시 수동 안내 폴백), 5.B `[CD] profile:staging`(자동 배포 + smoke + rollback), 5.C `[CD] profile:prod`(수동 승인 환경 + staging smoke 재확인 + 블루/그린 또는 카나리 + 릴리즈 노트), 5.D `[Security]`(SAST/의존성/시크릿 스캔, Dependabot Settings 수동 활성화 안내), 5.E `[Infra]` 레거시 분해(스코어링 → 사용자 승인 → 5.A~5.C 재실행).
   - STEP 6 — 로컬 검증 체인(`git diff --name-only` 변경 파일만 yamllint → actionlint → shellcheck → act -l/--dryrun). 3회 연속 실패 시 중단. actionlint 설치 대안 표(brew/바이너리/Go/Docker).
   - STEP 7 — 시크릿 가드. ALLOW 정규식, DENY 패턴(AWS AKIA/ASIA, GitHub PAT 5종 ghp/github_pat/gho/ghu/ghs/ghr, Slack xox*, PEM/OpenSSH 개인 키, JWT 주의), FILE_BLOCK(.env*/*.pem/*.key/*.p12). `${{ env.X }}`는 경고만.
   - STEP 8 — 커밋 + PR. Conventional Commits 스코프 표(`ci(workflow|lint|test)`/`cd(staging|prod)`/`sec(sast|deps|secrets)`). `gh pr create`는 `--fill` 미사용, `--title`/`--body-file`/`--base $DEFAULT`/반복 `--label`. PR 본문 템플릿(관련 이슈/분류/변경 요약/로컬 검증 체크/시크릿 가드/배포 후 확인/활성화 필요 Settings 체크박스).
   - STEP 9 — 머지 후 워크플로 모니터링(`gh run watch --exit-status`). 타임아웃: 10분 경고 / 30분 하드 타임아웃.
   - STEP 10 — 성공 경로(이슈 close + `deployed:staging`/`deployed:prod` 레이블 + Projects auto-workflow가 Status=Done 전환) / 실패 경로(staging 자동 롤백, prod incident 이슈 생성). 실패 회고 코멘트 템플릿.
9. **프로필별 DoD** — `profile:staging` / `profile:prod` / `[Security]` 각 5~6개 체크.
10. **검증 도구 체인 표** — yamllint, actionlint(필수), shellcheck, act, gh(필수), gitleaks.
11. **브랜치/커밋/PR 규약 표** — Default 동적, 접두사, slug 규칙, 커밋 스코프, 본문, PR 제목·플래그·레이블, default push 금지.
12. **시크릿 화이트리스트** — 허용/금지 패턴 상세.
13. **자동 롤백 정책 표** — staging/prod별 트리거·롤백 명령(플랫폼별)·이슈 조치.
14. **형제·호출·위임 관계** — ASCII 다이어그램(generate-issues-* → register → kanban → implement-top-issue v1.3 → ci-cd-pipeline). 표로 호출 계약 정리. **순환 호출 금지** 강조.
15. **안전장치(Safety Guards) 17개** — 카테고리 가드, Default 동적, default push 금지, 시크릿 리터럴 가드, actionlint 필수, PR 없이 머지 금지, prod 수동 승인 필수, 프로필 충돌 차단, 롤백 정의 필수, 워크플로 최소 1개 변경, 파일 모드 자동, gh run watch 타임아웃, 이중 실행 금지, Dry-run, 순환 호출 방지, admin 권한 폴백, Infra 레거시 분해.
16. **실패/예외 처리** 표(이슈 카테고리 아님, gh auth 미인증, default 추출 실패, dirty tree, actionlint 미설치, 3회 실패, 시크릿 감지, profile 충돌, 플랫폼 감지 실패, 기존 PR, Edit 모드 전환, 10분/30분 타임아웃, smoke 실패, prod 승인자 없음, 브랜치 보호 admin 권한 없음, Dependabot 비활성, Infra 레거시, 한국어 slug 변환 실패).
17. **사용 예시** 6건.
18. **Changelog** — v1.1(현재, Tier 1/2/3 패치 17건 상세) / v1.0.

## 톤 / 스타일
- 한국어 + bash/python 코드블록 적극 활용.
- 모든 배포 명령은 플랫폼별 변수(`<platform_deploy_cmd>`)로 표기.

## 검증
- 트리거 키워드 11개 모두 포함?
- STEP 0~10 + STEP 5'(5.A~5.E) 분기 모두 있음?
- DENY 패턴에 GitHub fine-grained PAT(`github_pat_*`) 포함?
- 타임아웃 10분 경고 / 30분 하드 타임아웃 명시?
- 안전장치 17개 모두 명시?
- `--cicd-mode`는 v1.3에서 해석되고 본 스킬에 전달되지 않음을 명문화?
