---
name: ci-cd-pipeline
description: >
  GitHub 저장소에서 **CI/CD 파이프라인(.github/workflows, Dockerfile, 배포 스크립트,
  PR 보호 규칙, 시크릿, smoke/보안 게이트 등)** 을 실제로 구현 · 검증 · 배포까지 완료하는
  전담 스킬 (v1.1). `implement-top-issue` v1.3 의 하이브리드 모드에서 `[CI]`/`[CD]`/
  `[Security]`/`[Infra]`(v2 레거시) 카테고리 이슈가 감지되면 자동 위임되는 실행기이며,
  독립 실행(슬래시 커맨드)도 지원한다. 이슈의 `profile:staging` / `profile:prod` 레이블을
  읽어 타겟 프로필을 결정하고, `yamllint → actionlint → shellcheck → act` 로컬 검증
  체인과 시크릿 화이트리스트 가드, `gh run watch --exit-status` 워크플로 모니터링,
  스테이징 smoke 실패 시 자동 롤백까지 자동 수행한다.
  사용자가 "CI/CD 구현", "CI 파이프라인 구축", "CD 배포 파이프라인 만들어줘",
  "GitHub Actions 워크플로 작성", "배포 자동화", "스테이징/프로덕션 배포",
  "PR 보호 규칙 설정", "smoke test 자동화", "SAST/의존성 스캔 파이프라인",
  "/ci-cd-pipeline", "/run-ci-cd", "/implement-cicd-issue" 중 하나라도 언급하면
  반드시 이 스킬을 사용할 것. 일반 기능(유저 스토리 · 수직 슬라이스) 구현을 원하면
  `implement-top-issue` 를 사용하되, 해당 스킬의 v1.3 이상이 CI/CD 이슈를 만나면
  내부적으로 이 스킬에 위임한다. 이슈 번호가 지정되지 않으면 먼저 이슈 번호를 물어본다.
---

# CI/CD 파이프라인 구현 스킬 v1.1

`[CI]` / `[CD]` / `[Security]` / `[Infra]`(v2 레거시) 카테고리 이슈를 받아 **실제 워크플로 파일과 배포 파이프라인을 작성하고, 로컬 검증 → PR → 머지 후 실제 실행까지 완결**하는 전담 스킬이다. `implement-top-issue` v1.3 이 일반 기능 이슈와 CI/CD 이슈를 동일한 인터페이스로 처리하기 위해 이 스킬에 **위임(delegate)** 한다.

**결과물**: `.github/workflows/*.yml`, `.github/CODEOWNERS`, `Dockerfile*`, `fly.toml`/`render.yaml`/`vercel.json`, `deploy/**/*.sh`, PR 보호 규칙 활성화, 상태 배지가 적용된 README, 스테이징/프로덕션 환경에서의 실제 실행 결과.

---

## 슬래시 커맨드

| 커맨드 | 설명 |
| :---- | :---- |
| `/ci-cd-pipeline --issue N` | 이슈 #N(`[CI]`/`[CD]`/`[Security]`/`[Infra]`)을 이 스킬로 구현 |
| `/run-ci-cd --issue N` | 축약 별칭 |
| `/implement-cicd-issue N` | implement-top-issue v1.3 이 내부 위임할 때 사용하는 경로 |
| `/ci-cd-pipeline --dry-run --issue N` | 실제 변경 없이 계획만 출력 (STEP 8~10 스킵) |

### `implement-top-issue` v1.3 와의 호출 계약 (명문화)

- v1.3 의 `--cicd-mode auto|on|off` 플래그는 **v1.3 쪽에서만 해석**하며 이 스킬에는 전달되지 않는다.
- v1.3 은 CI/CD 카테고리 감지 시 이 스킬을 `/implement-cicd-issue N` 경로로 호출한다.
- 이 스킬은 **실행 결과(성공/실패/롤백)만** 반환하며, 다음 이슈 픽업은 v1.3 이 본인 큐로 재진입해 처리한다 (이 스킬이 v1.3 를 호출하지 않음 — 순환 금지).

이 스킬은 **오로지 CI/CD 관련 이슈**만을 다룬다. 일반 기능 이슈가 인자로 들어오면 `implement-top-issue` 로 되돌려 보낸다.

---

## 범위(Scope) vs 비범위(Out of Scope)

### 이 스킬이 다루는 작업
- GitHub Actions 워크플로 파일 신설/수정 (`.github/workflows/*.yml`)
- PR 보호 규칙(`gh api repos/:owner/:repo/branches/:branch/protection`), CODEOWNERS, 브랜치 규칙
- 상태 배지, 라벨 규칙(`.github/labeler.yml`), 의존성 그룹(`.github/dependabot.yml`)
- 컨테이너 파일(`Dockerfile`, `docker-compose.yml`) — 배포 목적에 한정
- 배포 매니페스트(`fly.toml`, `render.yaml`, `vercel.json`, `app.yaml`, `cloudbuild.yaml`)
- 배포 스크립트(`deploy/*.sh`, `scripts/release.sh`)
- 스모크 테스트(배포 대상 URL 에 대한 HTTP/E2E 스모크)
- 보안 게이트(SAST: CodeQL/Semgrep, 의존성: `npm audit`/`pip-audit`/Dependabot, 시크릿: Gitleaks/truffleHog)
- 시크릿 등록 **안내** (실제 값은 절대 커밋하지 않음) — `gh secret set` 지시서만 제공

### 이 스킬이 다루지 않는 작업
- 애플리케이션 비즈니스 로직 / API 엔드포인트 / UI 컴포넌트 → `implement-top-issue`
- DB 마이그레이션 로직 → `implement-top-issue`
- TechSpec 작성 → `write-techspec`
- 이슈 생성 / 보드 배치 → `generate-issues-*` / `github-kanban`

---

## 핵심 철학 — Green Pipeline First, Safety by Gates

```
 이슈(#N, [CI]/[CD]/[Security]/[Infra])
        │
        ▼
 ┌────────────────────────────────────────────────────────────────┐
 │ 1. 저장소 상태 점검 (clean tree, default branch 동적 추출 + 최신) │
 └────────────────────────────────────────────────────────────────┘
        │
        ▼
 ┌────────────────────────────────────────────────────────────────┐
 │ 2. 프로필 결정 (profile:staging / profile:prod / auto) + 충돌 검사│
 └────────────────────────────────────────────────────────────────┘
        │
        ▼
 ┌────────────────────────────────────────────────────────────────┐
 │ 3. 플랫폼 자동 감지 (fly/vercel/render/k8s/커스텀)                │
 └────────────────────────────────────────────────────────────────┘
        │
        ▼
 ┌────────────────────────────────────────────────────────────────┐
 │ 4. 피처 브랜치 (ci/<N>-slug | cd/<N>-slug | sec/<N>-slug)       │
 └────────────────────────────────────────────────────────────────┘
        │
        ▼
 ┌────────────────────────────────────────────────────────────────┐
 │ 5. 카테고리별 구현 분기 (신설 vs 수정 모드 포함)                   │
 │   · [CI]                   → 5.A                                │
 │   · [CD] profile:staging   → 5.B                                │
 │   · [CD] profile:prod      → 5.C                                │
 │   · [Security]             → 5.D                                │
 │   · [Infra] (레거시)       → 5.E (분해 후 5.A~5.D 재실행)        │
 └────────────────────────────────────────────────────────────────┘
        │
        ▼
 ┌────────────────────────────────────────────────────────────────┐
 │ 6. 로컬 검증 체인 (yamllint → actionlint → shellcheck → act)    │
 └────────────────────────────────────────────────────────────────┘
        │
        ▼
 ┌────────────────────────────────────────────────────────────────┐
 │ 7. 시크릿 가드 (${{ secrets.X }} 형태만 허용, 리터럴 금지)       │
 └────────────────────────────────────────────────────────────────┘
        │
        ▼
 ┌────────────────────────────────────────────────────────────────┐
 │ 8. 커밋 (ci(...)/cd(...)/sec(...) conventional scope) + PR      │
 └────────────────────────────────────────────────────────────────┘
        │
        ▼
 ┌────────────────────────────────────────────────────────────────┐
 │ 9. 머지 후 워크플로 모니터링 (10분 경고 · 30분 하드 타임아웃)      │
 └────────────────────────────────────────────────────────────────┘
        │
        ▼
 ┌────────────────────────────────────────────────────────────────┐
 │ 10. 스모크 결과 → 성공: 이슈 close · 실패: 자동 롤백 + 회고       │
 └────────────────────────────────────────────────────────────────┘
```

**핵심 원칙**: "초록불이 아닌 파이프라인은 파이프라인이 아니다." 로컬에서 actionlint/act 를 통과하지 못한 워크플로는 PR 도 올리지 않는다. 스테이징 smoke 가 실패한 배포는 자동 롤백하되, 프로덕션 배포는 **수동 승인 게이트** 를 거친다.

---

## 행동 원칙

1. **위임 가능 일방향**: 이 스킬은 `implement-top-issue` v1.3 으로부터 호출만 받고, 그 반대 방향으로 호출하지 않는다 (순환 방지).
2. **카테고리 검증**: 입력 이슈의 레이블이 `[CI]`/`[CD]`/`[Security]`/`[Infra]` 중 하나가 아니면 즉시 중단 + `implement-top-issue` 로 반환.
3. **Default 브랜치 동적**: 모든 git/gh 명령은 `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` 결과를 사용. `main` 하드코딩 금지.
4. **로컬 검증 필수**: actionlint/yamllint/shellcheck/act 설치 확인 → 미설치 시 설치 제안 → 검증 통과 후에만 PR 생성.
5. **시크릿 리터럴 금지**: `secrets.*` 혹은 `vars.*` 레퍼런스만 허용. AWS/GitHub/Slack 토큰 등 DENY 패턴 발견 시 즉시 중단.
6. **최소 1개 워크플로 변경**: [CI]/[CD] 이슈는 커밋 diff 에 `.github/workflows/*.yml` 이 최소 하나 이상 포함되어야 한다.
7. **프로필 게이트**: `profile:prod` 이슈는 반드시 수동 승인 단계(`environment:` + `required_reviewers`)를 워크플로에 포함.
8. **파일 모드 자동 선택**: 기존 워크플로 파일이 있으면 **Edit 모드(최소 diff)**, 없으면 **Write 모드(신설)**.
9. **멱등성**: 스크립트/워크플로 재실행 시 동일 결과 (`apply -f` / `deploy --if-changed`).
10. **관측 가능**: 모든 배포 워크플로는 스모크 테스트 결과를 GitHub Summary 또는 Slack/Webhook 에 전송.
11. **Conventional Commits**: `ci(<scope>): …` / `cd(<scope>): …` / `sec(<scope>): …` 스코프 강제. **v1.3 의 `ci(…)` 일괄 원칙을 세분화한 형태** — Changelog 참조.
12. **GitHub Flow**: default 브랜치 직접 푸시 금지. 모든 변경은 PR 경유.

---

## AI 시스템 프롬프트 — `/ci-cd-pipeline`

당신은 숙련된 DevOps / Platform Engineer 입니다. 제공된 이슈(`[CI]`/`[CD]`/`[Security]`/`[Infra]`)를 받아 **GitHub Actions 워크플로 · 배포 매니페스트 · 보안 게이트** 를 실제 저장소에 반영하고, 로컬 검증 체인 통과 후 PR → 머지 → 실제 워크플로 실행 모니터링 → 성공/실패 기반 이슈 close 또는 롤백까지 완료합니다.

---

## 워크플로우

### STEP 0 — 구분 고지 + 입력 검증

최초 응답 한 줄:

> "`ci-cd-pipeline` v1.1 실행 — CI/CD 전용 파이프라인 구현 스킬입니다. `implement-top-issue` v1.3 의 하이브리드 모드에서도 이 스킬로 위임됩니다. 대상 이슈의 `[CI]`/`[CD]`/`[Security]`/`[Infra]` 레이블과 `profile:staging|prod` 를 기준으로 실행 분기를 결정합니다."

그 다음 입력 검증:

- `--issue N` 인자가 없으면: "어떤 이슈를 구현할까요? 번호를 입력해주세요 (예: `--issue 42`)" 로 되묻는다.
- `gh auth status` 실패 시 중단 + `gh auth login` 안내.
- 현재 디렉토리가 git 저장소가 아니면 중단 + `cd <repo>` 안내.
- **Default 브랜치 추출**: `DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)` → 이후 모든 단계에서 `$DEFAULT` 사용.

### STEP 1 — 이슈 로드 + 카테고리 판정

```
gh issue view <N> --json number,title,body,labels,assignees,milestone,projectItems
```

**카테고리 판정 규칙** (`implement-top-issue` v1.3 의 감지 로직과 동일 + `[Infra]` 레거시 수용):

```
CI_LABELS         = {"[CI]", "ci", "strategy:ci"}
CD_LABELS         = {"[CD]", "cd", "cicd", "strategy:cicd"}
SECURITY_LABELS   = {"[Security]", "security", "sast"}
INFRA_LEGACY      = {"[Infra]", "infra"}                 # v2.0 레거시 — 5.E 로 분해

TITLE_KEYWORDS_CI = ["CI", "lint", "test", "워크플로우", "workflow",
                     "GitHub Actions", "PR 보호"]
TITLE_KEYWORDS_CD = ["CD", "배포", "deploy", "스테이징", "staging",
                     "프로덕션", "production", "파이프라인"]
TITLE_KEYWORDS_SEC= ["SAST", "보안", "security", "스캔", "scan",
                     "취약점", "vulnerability", "Gitleaks", "CodeQL"]

BODY_PATH_HINTS_CI  = [".github/workflows/ci", "actionlint", "pre-commit"]
BODY_PATH_HINTS_CD  = [".github/workflows/deploy", "fly.toml", "render.yaml",
                       "vercel.json", "Dockerfile", "Jenkinsfile",
                       ".gitlab-ci.yml", "app.yaml", "cloudbuild.yaml"]
BODY_PATH_HINTS_SEC = ["codeql", "semgrep", "dependabot", "gitleaks",
                       "trufflehog", "npm audit", "pip-audit"]

category =
  1) if any(INFRA_LEGACY) in issue.labels        → [Infra] (→ STEP 5.E 재분해)
  2) if any(SECURITY_LABELS) in issue.labels
     OR any(TITLE_KEYWORDS_SEC) in title
     OR any(BODY_PATH_HINTS_SEC) in body         → [Security]
  3) if any(CD_LABELS) in issue.labels
     OR any(TITLE_KEYWORDS_CD) in title
     OR any(BODY_PATH_HINTS_CD) in body          → [CD]
  4) if any(CI_LABELS) in issue.labels
     OR any(TITLE_KEYWORDS_CI) in title
     OR any(BODY_PATH_HINTS_CI) in body          → [CI]
  5) else → 본 스킬 종료, implement-top-issue 로 반환
```

판정 결과를 사용자에게 1줄로 요약:

> "이슈 #42 — `[CD] profile:staging` · `mandatory-gate` → STEP 5.B (스테이징 자동 배포 구현) 경로로 진행합니다."

`[Infra]` 레거시가 감지되면 추가 안내:

> "⚠️ `[Infra]` 는 generate-issues-layered v2.0 에서 사용된 레거시 레이블입니다. `[CI]` / `[CD]` 로 분해해 처리합니다 (STEP 5.E). 차후에는 두 스킬의 v3.0 출력을 권장합니다."

### STEP 2 — 저장소 상태 검사 + Default 브랜치 동기화

```bash
git status --porcelain                                   # 비어있지 않으면 중단 (stash 제안)
CURRENT=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT" != "$DEFAULT" ]; then git checkout "$DEFAULT"; fi
git pull --ff-only origin "$DEFAULT"                     # 실패 시 중단 + 수동 rebase 안내
```

### STEP 3 — 프로필 결정 + 충돌 검사

이슈의 레이블에서 추출:
- `profile:staging` 만 → staging (자동 배포 가능)
- `profile:prod` 만 → prod (수동 승인 필수)
- **둘 다 존재** → **오류 중단** + "프로필 레이블이 충돌합니다. 둘 중 하나만 부여해주세요" 안내
- 둘 다 없음 → 본문/제목 키워드 추론 (`production|prod|live` → prod, 아니면 staging)

사용자 확인:

> "프로필을 `staging` 으로 판정했습니다. 맞나요?
>  A) 네, staging 으로 진행
>  B) prod 로 변경 (수동 승인 게이트 포함)
>  C) 중단"

### STEP 4 — 플랫폼 자동 감지

배포 플랫폼을 저장소 파일로 감지 (이후 5.B/5.C 의 배포/롤백 명령 선택에 사용):

```
detect_platform():
  · fly.toml              → fly      (배포: flyctl deploy, 롤백: flyctl releases rollback)
  · vercel.json           → vercel   (배포: vercel deploy --prod=false, 롤백: vercel rollback)
  · render.yaml           → render   (배포: render CLI, 롤백: 매뉴얼)
  · app.yaml              → gcp-ae   (배포: gcloud app deploy, 롤백: gcloud app versions migrate)
  · cloudbuild.yaml       → gcp-build (배포: gcloud builds submit)
  · k8s/ or **/*.yaml (+kind:Deployment)
                          → k8s      (배포: kubectl apply, 롤백: kubectl rollout undo)
  · Dockerfile 단독       → generic-docker (배포 대상 사용자 입력 필요)
  · 해당 없음             → 사용자에게 플랫폼 선택 요청
```

감지 결과를 사용자에게 1줄 요약 + 틀리면 수정 받음.

### STEP 5 — 피처 브랜치 생성

| 카테고리 | 브랜치 접두사 | 예시 |
| :---- | :---- | :---- |
| `[CI]` | `ci/` | `ci/42-pr-protection` |
| `[CD] profile:staging` | `cd/` | `cd/42-staging-auto-deploy` |
| `[CD] profile:prod` | `cd/` | `cd/42-prod-approval-gate` |
| `[Security]` | `sec/` | `sec/42-sast-codeql` |
| `[Infra]` 레거시 | 분해 후 `ci/` 또는 `cd/` | (5.E 참조) |

**Slug 생성 규칙 (한국어 대응)**:

```
slug = issue.title
       ─► 영문·숫자·하이픈·공백만 남기고 제거
       ─► 연속 공백/특수문자 → 단일 하이픈
       ─► 소문자화, 40자 초과 시 절단
       ─► 결과가 3자 미만이면 "issue-<N>" 폴백
         (예: "스테이징 자동 배포" → "issue-42")

git checkout -b "<prefix><N>-<slug>"
```

### STEP 5' — 카테고리별 구현 분기 (파일 모드 자동 선택)

**파일 존재 여부에 따른 모드 분기**:

- **Write 모드 (신설)**: 타깃 파일이 없을 때. 전체 구조를 새로 작성.
- **Edit 모드 (수정)**: 타깃 파일이 이미 존재할 때. **최소 diff 로만** 수정 — 기존 워크플로 파괴 금지.

모든 체크리스트 앞에 파일 모드 결정을 선행한다:
```
MODE = "Edit" if exists(".github/workflows/<target>.yml") else "Write"
```

#### 5.A `[CI]` 경로 — Lint / Test / PR 보호

체크리스트:
- [ ] `.github/workflows/ci.yml` 또는 동등 파일 (Write/Edit 모드 결정)
- [ ] 트리거: `on: { pull_request: { branches: [$DEFAULT] }, push: { branches: [$DEFAULT] } }`
- [ ] 단계: `actions/checkout@v4` → setup(toolchain) → `lint` → `test` → (옵션) `build`
- [ ] 매트릭스 전략이 필요하면 최소 OS 1종, 언어 버전 2종 이하로 시작
- [ ] **PR 보호 규칙 활성화** (admin 권한 필요):
  ```bash
  gh api -X PUT "/repos/:owner/:repo/branches/$DEFAULT/protection" \
    -F required_status_checks[contexts][]=<ci-job-name>
  ```
  권한 부족 시 → 경고 + "Settings → Branches → Branch protection rules 에서 수동으로 `$DEFAULT` 에 required check 를 추가하세요" 안내로 폴백.
- [ ] README 에 상태 배지 1줄 추가
- [ ] 실패 시 annotated PR comment 출력 (`actions/github-script` 또는 default `GITHUB_TOKEN`)

#### 5.B `[CD] profile:staging` 경로 — 자동 배포 + Smoke

체크리스트 (STEP 4 의 `platform` 변수에 따라 명령 치환):
- [ ] `.github/workflows/deploy-staging.yml` (Write/Edit 모드)
- [ ] 트리거: `on: { push: { branches: [$DEFAULT] } }` 또는 `workflow_run` (CI 성공 후 체이닝)
- [ ] Job 순서: 빌드 → 스테이징 배포(`<platform_deploy_cmd>`) → smoke
- [ ] smoke: `curl -fsS --retry 5 --retry-delay 3 "$STAGING_URL/health"` 최소, 가능하면 Playwright 1 시나리오
- [ ] 실패 시 `<platform_rollback_cmd>` 자동 실행 (rollback job 분리, `if: failure()`)
- [ ] 환경변수: `secrets.STAGING_URL`, `secrets.<PLATFORM>_TOKEN` 등
- [ ] 배포 후 GitHub Step Summary 에 버전 + URL + smoke 결과 append

#### 5.C `[CD] profile:prod` 경로 — 수동 승인 + 블루/그린 또는 카나리

체크리스트:
- [ ] `.github/workflows/deploy-prod.yml` (Write/Edit 모드)
- [ ] 트리거: `on: { workflow_dispatch: {}, release: { types: [published] } }`
- [ ] `environment: production` + `required_reviewers` 지정 — Settings → Environments 수동 구성 안내
- [ ] 배포 전 staging smoke 재확인(`workflow_run` 로 deploy-staging 성공 이력 참조)
- [ ] Job 순서: gate(승인) → prod 배포(`<platform_deploy_cmd>`) → prod smoke → (실패시) rollback
- [ ] Prod smoke: `/health` + 핵심 유저 여정 1건(`login → 메인 페이지 로드`)
- [ ] 롤백 조건: smoke 실패 OR p50 latency > 2× 베이스라인 OR error rate > 1%
- [ ] 릴리즈 노트 자동 생성(`actions/create-release` 또는 `softprops/action-gh-release`)

#### 5.D `[Security]` 경로 — SAST · 의존성 · 시크릿 스캔

체크리스트:
- [ ] `.github/workflows/security.yml` 또는 개별 파일 (Write/Edit 모드)
- [ ] **SAST**: CodeQL(`github/codeql-action`) 또는 Semgrep(`returntocorp/semgrep-action`), 최소 주 1회 + PR 트리거
- [ ] **의존성 감사**: `.github/dependabot.yml` 에 `package-ecosystem` 모두 등록 (주 1회 updates) + PR 트리거에 `npm audit --audit-level=high` / `pip-audit --strict`
  > ⚠️ Dependabot updates 는 저장소 Settings → Code security and analysis 에서 **수동으로 활성화** 해야 동작한다. 파일만으로는 켜지지 않으므로 PR 본문에 활성화 안내 포함.
- [ ] **시크릿 스캔**: Gitleaks(`gitleaks/gitleaks-action`) 또는 truffleHog PR 트리거
- [ ] 실패 시 PR 머지 차단 (`mandatory-gate` 레이블 → PR 보호 required check 에 등록)
- [ ] 대시보드: Security tab 의 알림 활성화 + 보고서 경로 README 에 문서화

#### 5.E `[Infra]` 레거시 분해 경로

v2.0 의 `[Infra]` 단일 레이블을 v3.0 의 `[CI]` / `[CD]` 로 분해 후 5.A~5.C 재실행:

```
1) 본문·제목을 TITLE_KEYWORDS_CI / TITLE_KEYWORDS_CD / BODY_PATH_HINTS_CI / BODY_PATH_HINTS_CD 로 스코어링
2) 최고 스코어 카테고리를 제안 → 사용자 승인
3) 이슈 코멘트로 "`[Infra]` 를 `[CI]`/`[CD]` 로 재분류했습니다" 보고
4) 해당 카테고리의 5.A/5.B/5.C 재실행
```

*(레이블 재부여는 선택 — register-issues-to-github 가 추후 일괄 마이그레이션 지원 예정)*

### STEP 6 — 로컬 검증 체인 (필수, 순차 실행)

`$DEFAULT` 대비 **변경된 파일만** 스캔:

```bash
CHANGED=$(git diff --name-only "origin/$DEFAULT...HEAD")

# 1) yamllint — 변경된 workflow yml 만
echo "$CHANGED" | grep '^\.github/workflows/.*\.ya\?ml$' \
  | xargs -r yamllint -c .yamllint

# 2) actionlint — 변경된 workflow 만 (미설치 시 중단)
echo "$CHANGED" | grep '^\.github/workflows/.*\.ya\?ml$' \
  | xargs -r actionlint

# 3) shellcheck — 변경된 .sh 만
echo "$CHANGED" | grep '\.sh$' \
  | xargs -r shellcheck

# 4) act -l (옵션)
act -l 2>/dev/null || true

# 5) act --dryrun -j <job> (옵션)
```

실패 시 구체적 파일·라인·규칙명을 출력하고 STEP 5' 로 복귀. **3회 연속 실패 시 사용자에게 보고 + 중단**.

**actionlint 설치 대안** (Go 환경 없어도 가능):

| 환경 | 명령 |
| :---- | :---- |
| macOS (Homebrew) | `brew install actionlint` |
| Linux (바이너리 다운로드) | `curl -sSLO https://github.com/rhysd/actionlint/releases/latest/download/actionlint_linux_amd64.tar.gz && tar -xzf actionlint_linux_amd64.tar.gz` |
| Go 환경 | `go install github.com/rhysd/actionlint/cmd/actionlint@latest` |
| Docker | `docker run --rm -v "$(pwd):/repo" -w /repo rhysd/actionlint:latest` |

### STEP 7 — 시크릿 가드

변경된 모든 파일 전수 스캔:

```python
# 의사 코드 — 실제는 rg 또는 python regex 로 구현
ALLOW = r"\$\{\{\s*(secrets|vars|env|github|inputs|steps|matrix|runner|needs|strategy)\.[A-Za-z0-9_]+\s*\}\}"

DENY_PATTERNS = [
  r"AKIA[0-9A-Z]{16}",                            # AWS Access Key
  r"ASIA[0-9A-Z]{16}",                            # AWS STS
  r"ghp_[A-Za-z0-9]{36,}",                        # GitHub classic PAT
  r"github_pat_[A-Za-z0-9_]{80,}",                # GitHub fine-grained PAT
  r"gho_[A-Za-z0-9]{36,}",                        # GitHub OAuth
  r"ghu_[A-Za-z0-9]{36,}",                        # GitHub user-to-server
  r"ghs_[A-Za-z0-9]{36,}",                        # GitHub app install
  r"ghr_[A-Za-z0-9]{36,}",                        # GitHub refresh token
  r"xox[baprs]-[A-Za-z0-9-]{10,}",                # Slack
  r"-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----",  # 개인 키
  r"eyJ[A-Za-z0-9_\-]{20,}\.[A-Za-z0-9_\-]{20,}\.[A-Za-z0-9_\-]{20,}",  # JWT (주의성 탐지)
]

FILE_BLOCK = [r"\.env(\..*)?$", r"\.pem$", r"\.key$", r"\.p12$"]
```

- `${{ secrets.X }}` · `${{ vars.X }}` 레퍼런스는 허용.
- `${{ env.X }}` 는 **경고만** (정적 검사로 secrets 주입 여부를 완전히 판정할 수 없음 — 사용자가 의도를 확인).
- DENY 패턴 히트 시 즉시 중단 + 해당 파일/라인 보고 + "값을 `gh secret set` 으로 등록하고 레퍼런스로 치환하세요" 안내.
- FILE_BLOCK 패턴 파일의 신규 커밋 시도는 즉시 중단.
- 별도 `gh secret set <NAME> --body '<REDACTED>'` 지시서를 PR 본문에 **값 마스킹 상태** 로 포함.

### STEP 8 — 커밋 + PR

**Conventional Commits 스코프 자동 결정** (v1.3 의 `ci(...)` 일괄 원칙을 **의도적으로 세분화**):

| 카테고리 | 스코프 | 예시 제목 |
| :---- | :---- | :---- |
| `[CI]` | `ci(workflow)` / `ci(lint)` / `ci(test)` | `ci(workflow): add PR-triggered lint+test matrix` |
| `[CD] profile:staging` | `cd(staging)` | `cd(staging): auto-deploy on $DEFAULT merge + smoke` |
| `[CD] profile:prod` | `cd(prod)` | `cd(prod): approval gate + blue-green deploy` |
| `[Security]` | `sec(sast)` / `sec(deps)` / `sec(secrets)` | `sec(sast): CodeQL weekly + PR trigger` |

```bash
git add -A
git commit -m "<scope>: <요약>

Closes #<N>

- 구현 내용 요약
- 로컬 검증 결과 (actionlint/yamllint/shellcheck 통과)
- 스모크 시나리오
"
git push -u origin "<branch>"

# --fill 대신 명시적 title/body 사용 (v1.1 수정: --fill 과 --title/--body-file 충돌 제거)
# 레이블은 반복 플래그로 지정 (콤마 구분 호환성 이슈 회피)
gh pr create \
  --title "<scope>: <제목>" \
  --body-file "<PR-body.md>" \
  --base "$DEFAULT" \
  --label "<카테고리 레이블>" \
  --label "<profile 레이블>" \
  $(if has_mandatory_gate; then echo --label mandatory-gate; fi)
```

PR 본문 템플릿 (`<PR-body.md>`):

```markdown
## 관련 이슈
Closes #<N>

## 분류
- 카테고리: <[CI]/[CD]/[Security]/[Infra→분해]>
- 프로필: <staging|prod|N/A>
- Mandatory Gate: <예|아니오>
- 플랫폼: <fly|vercel|render|gcp-ae|k8s|generic-docker|기타>

## 변경 요약
- 워크플로 파일: <목록 (Write/Edit 모드 표기)>
- 매니페스트/설정: <목록>
- PR 보호 규칙 변경: <예|아니오> (admin 권한 미보유 시 수동 작업 안내 포함)

## 로컬 검증
- [x] yamllint
- [x] actionlint
- [x] shellcheck (변경된 .sh 파일)
- [x] act dry-run (선택)

## 시크릿 가드
- `${{ secrets.* }}` / `${{ vars.* }}` 레퍼런스만 사용 ✅
- DENY 패턴 스캔 통과 ✅
- 필요한 시크릿(수동 등록 필요):
  - `gh secret set STAGING_URL --body '<REDACTED>'`
  - `gh secret set <PLATFORM>_TOKEN --body '<REDACTED>'`

## 배포 후 확인 계획
- 스모크 엔드포인트: <URL>
- 성공 기준: <조건>
- 롤백 조건: <조건>

## 활성화 필요 Settings (해당 시)
- [ ] Dependabot updates (Settings → Code security and analysis)
- [ ] Environment `production` + required reviewers (Settings → Environments)
- [ ] Branch protection rule on `$DEFAULT` (Settings → Branches)
```

### STEP 9 — 머지 후 워크플로 모니터링

PR 리뷰/자동 머지 이후 (또는 사용자가 머지 완료 보고 시):

```bash
# 최근 run_id 확보 (default 브랜치 동적)
RUN_ID=$(gh run list --branch "$DEFAULT" --limit 1 --json databaseId -q '.[0].databaseId')

# 실시간 모니터링 (exit-status 로 실패 시 비-0 종료)
gh run watch "$RUN_ID" --exit-status
```

**타임아웃 정책 (v1.1 명확화)**:

| 경과 시간 | 동작 |
| :---- | :---- |
| 10 분 | ⚠️ 경고 출력: "장시간 실행 중입니다. Actions 탭 URL 확인 권장" — 그러나 계속 대기 |
| 30 분 | ⛔ **하드 타임아웃** — `gh run watch` 종료, 이슈는 open 유지, 사용자 개입 요청 |

- **성공**: STEP 10-A
- **실패**: STEP 10-B

### STEP 10 — 성공 종결 / 실패 롤백

#### 10-A 성공 경로

- staging 이면: `gh issue close <N> --comment "✅ 스테이징 배포 + 스모크 통과 — run: <url>"`
- prod 이면: 추가로 릴리즈 태그 생성 + Ops 채널 공지
- PR 에 `deployed:staging` / `deployed:prod` 레이블 자동 부여 (반복 `--label` 플래그)
- **github-kanban 연동**: Projects v2 의 auto-workflow (GitHub 기본 제공) 가 이슈 close 시 Status 를 자동으로 "Done" 으로 전환. 이 스킬은 보드를 직접 건드리지 않음.

#### 10-B 실패 경로

| 프로필 | 자동 조치 | 이슈 처리 |
| :---- | :---- | :---- |
| staging | 자동 롤백(STEP 4 의 `<platform_rollback_cmd>`) 후 실패 원인 요약 | 이슈 유지 + `deploy:failed` 레이블 + 실패 로그 코멘트 |
| prod | **수동 승인 게이트 전이면 차단 완료**. 이미 적용된 경우 `rollback` 잡 자동 실행 | incident 이슈 생성(`priority:p0`) + 원 이슈에 링크 |

실패 회고 코멘트 템플릿:

```
🔴 CI/CD 파이프라인 실패 — #<N>

- run: <url>
- 실패 step: <step name>
- 원인 요약: <로그에서 추출한 핵심 에러>
- 자동 롤백 수행 여부: <예|아니오>
- 플랫폼: <fly|vercel|...>
- 다음 조치 제안:
  1) <조치 1>
  2) <조치 2>
```

---

## 프로필별 DoD (Definition of Done)

### `profile:staging`

- [ ] `$DEFAULT` 머지 → 자동으로 스테이징 배포 (수동 개입 없이)
- [ ] 배포 직후 smoke (`/health` 최소) 통과
- [ ] 배포 실패 시 자동 롤백
- [ ] 스테이징 URL 이 README 또는 Ops 문서에 기록
- [ ] 워크플로 1회 이상 실제 `$DEFAULT` 에서 녹색 실행 확인

### `profile:prod`

- [ ] 수동 승인 게이트(`environment: production` + `required_reviewers`)
- [ ] staging smoke 선행 조건 참조(`workflow_run`)
- [ ] prod smoke (`/health` + 핵심 유저 여정)
- [ ] 롤백 자동화(수동 트리거 경로도 포함)
- [ ] 릴리즈 노트 자동 생성
- [ ] 최소 1회 실 운영 배포 성공 확인

### `[Security]`

- [ ] SAST / 의존성 / 시크릿 각 1개 이상 도구 활성화
- [ ] PR 트리거 + 주간 스케줄 병행
- [ ] `mandatory-gate` 필수 체크로 등록
- [ ] 첫 실행에서 발견된 High/Critical 이슈 정리(또는 허용 목록화)
- [ ] Dependabot updates 저장소 Settings 에서 활성화 완료

---

## 검증 도구 체인

| 도구 | 역할 | 기본 설치 | 대안 설치 |
| :---- | :---- | :---- | :---- |
| `yamllint` | YAML 문법/인덴트/라인 길이 | `pip install yamllint --break-system-packages` | `brew install yamllint` |
| `actionlint` | GitHub Actions 워크플로 정적 분석 | `brew install actionlint` | 바이너리 / `docker run rhysd/actionlint` / `go install ...` |
| `shellcheck` | 쉘 스크립트 정적 분석 | `apt install shellcheck` / `brew install shellcheck` | `docker run koalaman/shellcheck` |
| `act` | 로컬에서 워크플로 드라이런 | `brew install act` | 바이너리 릴리즈 |
| `gh` | GitHub 메타데이터 조작/모니터링 | 필수. `gh auth status` 선행 확인 | - |
| `gitleaks` | 시크릿 스캔 | 선택 — 워크플로 내에서도 사용 | `brew install gitleaks` |

설치가 안 되어 있으면 사용자에게 설치 제안 후 스킵 여부 확인. **actionlint 는 필수, 미설치 시 중단**.

---

## 브랜치 / 커밋 / PR 규약

| 항목 | 규칙 |
| :---- | :---- |
| Default 브랜치 | **동적 추출** (`gh repo view ... -q .defaultBranchRef.name`), `main` 하드코딩 금지 |
| 브랜치 접두사 | `ci/<N>-<slug>` · `cd/<N>-<slug>` · `sec/<N>-<slug>` |
| Slug 규칙 | 영문·숫자·하이픈만, 최대 40자, 3자 미만 시 `issue-<N>` 폴백 |
| 커밋 스코프 | `ci(<sub>):` / `cd(<sub>):` / `sec(<sub>):` |
| 커밋 본문 | `Closes #N` 포함 |
| PR 제목 | 커밋 제목과 동일 |
| PR 플래그 | `--fill` 미사용, `--title` + `--body-file` + `--base $DEFAULT` + 반복 `--label` |
| PR 레이블 | 이슈 레이블 상속 + `deploy:failed`/`deployed:staging`/`deployed:prod` 동적 |
| Default 브랜치 push | **금지**. 항상 PR 경유 |

---

## 시크릿 화이트리스트

허용되는 표기 (리터럴이 아닌 레퍼런스만):
- `${{ secrets.<NAME> }}`
- `${{ vars.<NAME> }}`
- `${{ env.<NAME> }}` — ⚠️ **경고만** (정적 검사로 secrets 주입 여부를 완전 판정 불가 — 사용자 확인 요청)
- `${{ github.* }}`, `${{ inputs.* }}`, `${{ steps.* }}`, `${{ matrix.* }}`, `${{ runner.* }}`, `${{ needs.* }}`, `${{ strategy.* }}`

금지 패턴(발견 시 즉시 차단):
- AWS 액세스 키 (`AKIA*`, `ASIA*`), AWS 시크릿 키(긴 Base64)
- GitHub classic PAT(`ghp_*`), **fine-grained PAT(`github_pat_*`)**, OAuth(`gho_*`), user-to-server(`ghu_*`), app install(`ghs_*`), refresh(`ghr_*`)
- Slack 토큰(`xox[baprs]-*`)
- PEM/OpenSSH 형식 개인 키(`-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----`)
- JWT 형식 — 주의 경고(커밋 금지)
- `.env*` / `*.pem` / `*.key` / `*.p12` 신규 커밋

실제 시크릿 값이 필요한 경우 PR 본문에 `gh secret set` 지시서를 **값 마스킹 상태**로 포함하고, 사용자가 실제 값을 수동 등록하도록 안내.

---

## 자동 롤백 정책

| 프로필 | 트리거 | 롤백 명령(플랫폼별) | 이슈 조치 |
| :---- | :---- | :---- | :---- |
| staging | smoke 실패 | `flyctl releases rollback` / `vercel rollback` / `kubectl rollout undo` / `gcloud app versions migrate` | `deploy:failed` 레이블 + 실패 로그 코멘트 |
| prod | smoke 실패 OR error-rate > 1% 5분 지속 | 동일 + 수동 승인 alternatives | incident 이슈 생성 + `priority:p0` |

롤백은 **별도 job** 으로 구성해 실패 job 의 `if: failure()` 조건으로 트리거한다. 롤백 성공 여부도 Slack/Webhook 알림.

플랫폼은 STEP 4 에서 자동 감지된 `<platform>` 변수를 사용해 명령어를 치환한다.

---

## 형제 · 호출 · 위임 관계

```
[이슈 생성]                     [등록]                    [관리]                  [구현 엔트리]           [CI/CD 전담 구현]
generate-issues-vertical ──►  register-issues-to-github ──► github-kanban ──► implement-top-issue ──► ci-cd-pipeline (이 스킬)
generate-issues-layered   ▲                                                         │ v1.3                                 │
                           │                                                         │ (카테고리 감지)                        │
                           │                                                         │                                     │
                           │                                                         └───── 일반 기능 이슈는 자체 구현        │
                           │                                                                                               │
                           └─────────────────────── (이 스킬은 다른 스킬을 호출하지 않음, 단방향 종단점) ─────────────────────┘
```

| 스킬 | 관계 |
| :---- | :---- |
| `implement-top-issue` v1.3 | **이 스킬의 호출자**. CI/CD 이슈 감지 시 `--cicd-mode auto/on` 이면 이 스킬로 위임 (플래그는 v1.3 쪽에서 해석, 이 스킬에는 전달되지 않음) |
| `generate-issues-vertical` v3.0 | `[CI]`/`[CD]` 이슈를 생성하는 상류 스킬 |
| `generate-issues-layered` v3.0 | 동일 — Layer 0/2/9 이슈 생성 |
| `generate-issues-layered` v2.0 (레거시) | `[Infra]` 단일 레이블 사용 — STEP 5.E 에서 분해 처리 |
| `github-kanban` v2.0 | 보드의 `mandatory-gate` + `order:NNN` 을 이 스킬이 소비할 순서로 배치. 이슈 close → Status=Done 은 Projects auto-workflow 가 처리 |
| `register-issues-to-github` | 이슈를 실제 GitHub 번호로 발행하여 이 스킬이 `--issue N` 으로 받을 수 있게 함 |
| `write-techspec` | TechSpec → 기능 요구사항. 이 스킬은 TechSpec 을 직접 읽지 않음 (간접) |

**순환 호출 금지**: `ci-cd-pipeline` 은 `implement-top-issue` 를 호출하지 않는다. 잘못된 카테고리 이슈가 들어오면 "이 이슈는 CI/CD 가 아닙니다" 메시지와 함께 종료만 한다.

---

## 안전장치 (Safety Guards)

1. **카테고리 가드**: `[CI]`/`[CD]`/`[Security]`/`[Infra]` 가 아니면 종료.
2. **Default 브랜치 동적 추출**: 모든 단계에서 `$DEFAULT` 변수 사용, `main` 하드코딩 금지.
3. **Default 브랜치 푸시 금지**: `git push origin $DEFAULT` 직접 호출 감지 시 차단.
4. **시크릿 리터럴 가드**: DENY 패턴 정규식 매칭 시 즉시 중단 + 레퍼런스 치환 안내 (GitHub classic/fine-grained PAT 전체 커버).
5. **actionlint 필수**: 미설치 시 중단 + brew/바이너리/Docker/Go 대안 설치 제안.
6. **PR 없이 머지 금지**: `--admin` / `--merge-method direct` 등 우회 옵션 금지.
7. **Prod 수동 승인 필수**: `profile:prod` 인데 `environment:` 미포함 시 중단.
8. **프로필 충돌 차단**: `profile:staging` + `profile:prod` 동시 부여 시 중단.
9. **롤백 정의 필수**: `[CD]` 이슈인데 rollback job 이 없으면 경고 + 플랫폼별 제안.
10. **워크플로 최소 1개 변경**: `[CI]`/`[CD]` 이슈의 diff 에 `.github/workflows/*.yml` 변경이 없으면 PR 생성 차단.
11. **파일 모드 자동 선택**: 기존 파일이 있으면 Edit 모드(최소 diff), 없으면 Write 모드 — 기존 워크플로 파괴 방지.
12. **`gh run watch` 타임아웃**: 10분 경고 · 30분 하드 타임아웃.
13. **이중 실행 금지**: 동일 이슈 #N 에 대해 기존 열린 PR 이 있으면 "기존 PR 먼저 처리" 안내.
14. **Dry-run 경로**: `--dry-run` 이면 STEP 8 ~ STEP 10 은 건너뛰고 계획만 출력. 또한 `git checkout -b`/`git commit`/`gh pr create`/`gh run watch` 전부 스킵.
15. **순환 호출 방지**: `implement-top-issue` 호출 금지.
16. **admin 권한 폴백**: 브랜치 보호 API 호출 실패 시 수동 설정 안내로 폴백(중단하지 않음).
17. **`[Infra]` 레거시 분해**: `[Infra]` 감지 시 5.E 로 진입 — `[CI]`/`[CD]` 로 재분류 후 진행.

---

## 실패 / 예외 처리

| 상황 | 대응 |
| :---- | :---- |
| 이슈 카테고리가 CI/CD 가 아님 | 즉시 종료 + implement-top-issue 재시도 안내 |
| `gh auth` 미인증 | 중단 + `gh auth login` 안내 |
| Default 브랜치 추출 실패 | 중단 + `gh repo view` 권한 점검 안내 |
| 저장소 tree dirty | `git stash` 또는 커밋 완료 후 재시도 안내 |
| actionlint/yamllint 미설치 | 대안 설치 명령 제안 + 동의 시 설치, 거부 시 중단 |
| 로컬 검증 3회 연속 실패 | 중단 + 마지막 실패 로그 요약 + 사용자 개입 요청 |
| 시크릿 리터럴 감지 | 해당 파일/라인 보고 + 교체 제안 |
| `profile:staging` + `profile:prod` 충돌 | 중단 + 한쪽 제거 요청 |
| 플랫폼 자동 감지 실패 | 사용자에게 플랫폼 선택 요청 (fly/vercel/render/k8s/generic-docker) |
| 기존 열린 PR 존재 | 기존 PR 링크 제공 + 병합 후 재실행 안내 |
| 기존 워크플로 파일 존재 | Edit 모드로 전환 + diff 미리보기 + 사용자 승인 |
| `gh run watch` 10분 초과 | 경고 + 계속 대기 |
| `gh run watch` 30분 초과 | 하드 타임아웃, 워크플로 URL 안내 후 중단 (이슈는 open 유지) |
| staging smoke 실패 | 플랫폼별 자동 롤백 + 실패 로그 코멘트 + 이슈 유지 |
| prod smoke 실패 | 롤백 + incident 이슈 생성(`priority:p0`) + 알림 |
| `profile:prod` 인데 승인자 없음 | Settings → Environments 안내 + environment 생성 가이드 |
| 브랜치 보호 API admin 권한 없음 | 경고 + 수동 설정 안내로 폴백 (중단 X) |
| Dependabot Settings 비활성 | PR 본문에 활성화 체크박스 포함 + 코멘트로 안내 |
| `[Infra]` 레거시 레이블 감지 | 5.E 로 진입, 재분류 후 진행 |
| 한국어 제목 slug 변환 실패 | `issue-<N>` 폴백 |

---

## 사용 예시

- "CI/CD 파이프라인 구현해줘 #42" → `/ci-cd-pipeline --issue 42`
- "스테이징 자동 배포 워크플로 만들어줘" → `/ci-cd-pipeline --issue <N>` (이슈에 `[CD] profile:staging` 필요)
- "SAST 추가해줘" → `/ci-cd-pipeline --issue <N>` (`[Security]` 이슈)
- "구현 계획만 보여줘" → `/ci-cd-pipeline --dry-run --issue <N>`
- implement-top-issue 에서 "이 이슈는 CI/CD 같은데?" → "C) 자동 위임" 선택 시 이 스킬로 분기
- v2.0 레거시 `[Infra]` 이슈 → 자동으로 5.E 분해 후 5.A/5.B 진행

---

## 변경 이력 (Changelog)

| 버전 | 변경 내용 |
| :---- | :---- |
| **v1.1** (현재) | **일관성 · 강건성 패치**. Tier 1 (기능적 결함 7건): ① STEP 1 에 `[Infra]`/`infra` 레거시 레이블 수용 + `BODY_PATH_HINTS` 를 판정식에 실제 반영. ② `main` 하드코딩 제거 — 모든 단계에서 `$DEFAULT = gh repo view -q .defaultBranchRef.name` 동적 추출. ③ STEP 6 shellcheck 가 전체 저장소가 아닌 `git diff` 변경 파일만 스캔. ④ STEP 8 의 `gh pr create` 에서 `--fill` 제거 (`--title`/`--body-file` 충돌 해소) + `--label` 반복 플래그로 변경. ⑤ 오타 "이슈은→이슈는" 수정. Tier 2 (일관성 강화 8건): ⑥ 10분 경고 · 30분 하드 타임아웃 분리 명시. ⑦ GitHub fine-grained PAT(`github_pat_*`) + OAuth/install token 패턴 DENY 추가. ⑧ `ci()`/`cd()`/`sec()` 세분화가 v1.3 `ci(...)` 일괄과 의도적 차이임을 명문화. ⑨ `profile:staging` + `profile:prod` 충돌 시 중단. ⑩ actionlint brew/바이너리/Docker 대안 설치 경로 추가. ⑪ 한국어 slug 폴백 규칙 (`issue-<N>`). ⑫ STEP 4 플랫폼 자동 감지 단계 신설 (fly/vercel/render/gcp-ae/k8s/generic-docker). ⑬ 기존 워크플로 파일 존재 시 Edit 모드(최소 diff) 자동 전환. Tier 3 (보강 5건): ⑭ 브랜치 보호 API admin 권한 부족 시 수동 설정 안내 폴백. ⑮ `${{ env.X }}` 는 경고만 (정적 검사 한계 명시). ⑯ 이슈 close 시 github-kanban Status=Done 전환은 Projects auto-workflow 가 처리함을 명시. ⑰ `--cicd-mode` 는 v1.3 측 플래그이며 이 스킬에 전달되지 않음을 명문화. ⑱ Dependabot updates 는 저장소 Settings 에서 수동 활성화 필요함을 PR 본문에 포함. 안전장치 12→17 확장. |
| v1.0 | 최초 릴리스. ① `[CI]`/`[CD]`/`[Security]` 카테고리별 5 경로 분기(5.A~5.D). ② 로컬 검증 체인(yamllint→actionlint→shellcheck→act). ③ 시크릿 화이트리스트 + DENY 패턴 정규식 가드. ④ `profile:staging` 자동 롤백, `profile:prod` 수동 승인 + 카나리/블루-그린. ⑤ Conventional Commits 스코프 자동 결정. ⑥ `gh run watch --exit-status` 기반 워크플로 모니터링 + 실패 회고 템플릿. ⑦ `implement-top-issue` v1.3 하이브리드 모드 위임 타겟. ⑧ 순환 호출 금지 + default 브랜치 푸시 금지 가드. |
