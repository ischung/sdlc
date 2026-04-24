# Prompt — `implement-top-issue` SKILL.md 생성 요청

## 역할
당신은 Claude 스킬 작성자입니다. **`implement-top-issue` SKILL.md (v1.4, description은 v1.3 기준 + Ticket-first 가드 추가)** 한 개 파일을 만드세요. GitHub Projects 보드의 'Todo'에서 가장 높은 우선순위 이슈 1건을 픽업해 GitHub Flow로 브랜치 → AC 기반 구현 → 로컬 검증 → PR 생성까지 자동 수행하는 'AI 개발자' 스킬입니다.

## 산출물 요구사항

### Frontmatter
- `name`: `implement-top-issue`
- `description`: GitHub Projects 보드에서 **가장 높은 우선순위 이슈 1건**을 픽업해 GitHub Flow에 따라 브랜치 → 코드 구현(AC 기반) → 로컬 빌드/린트/단위·통합·E2E 테스트(UI는 Playwright) → PR 생성(`Closes #N`) → 보드 'In Progress' → 'Review' 전이까지 자동 수행하는 '구현 담당 AI 개발자' 스킬(v1.3). 이슈가 **CI/CD 파이프라인 구축** 성격이면 감지 → `ci-cd-pipeline` 스킬에 구현 위임, 검증/PR/보드 전이/워크플로우 런 모니터링은 본 스킬이 마무리(**하이브리드 모드**). 우선순위 캐스케이드: Priority 커스텀 필드(P0~P3) → `priority:p0~p3` 레이블 → 보드 표시 순서 → 이슈 번호. 결정론적 키 `(priority_score, board_index, issue_number)`. ⚠️ 단일 책임 — 새 이슈 만들지 않음. 한 번 실행에 이슈 1건만. 🚫 **이슈 우선(Ticket-first) 가드** — 로컬 파일 `#[N]` 순번 또는 GitHub Issue 번호 미부여 이슈는 거부. `append-issue` → `register-issues-to-github` 안내 후 종료. 트리거: "다음 이슈 구현해줘", "Todo 이슈 가져와서 작업해줘", "이슈 픽업해서 PR까지 만들어줘", "최우선 이슈 작업", "다음 티켓 처리", "GitHub Flow로 이슈 처리", "보드 최상단 이슈 작업해줘", "우선순위 높은 이슈 구현해줘", "AI 개발자처럼 이슈 하나 끝내줘", "/implement-top-issue", "/pickup-issue", "/work-next-issue", "/implement-priority-issue".

### 본문 구조

1. 제목: `# 구현 담당 AI 개발자 스킬 — \`implement-top-issue\` v1.4` + 한 단락 요약(GitHub Flow 자동 수행 + CI/CD 위임 분기).
2. **핵심 약속** — 이슈 1건만, 우선순위 기반, **Ticket-first 가드**, 이슈 생성 금지, AC 기반, 로컬 우선, UI는 Playwright, CI/CD 위임, PR `Closes #N`, 결정론적.
3. **슬래시 커맨드 표** 4개: `/implement-top-issue`, `/implement-priority-issue`, `/pickup-issue`, `/work-next-issue`. **주요 인자 표** — `--issue N`, `--priority`, `--include-priority`, `--dry-run`, `--cicd-mode auto|on|off`.
4. **전제 조건 표** — gh CLI(project 스코프), git, 작업 디렉터리, 기본 브랜치 자동 감지(`gh repo view --json defaultBranchRef`), 프로젝트 보드(github-kanban으로 사전 생성, 컬럼 Todo/In Progress/Review/Done, Priority 권장), KANBAN_TOKEN(권장), 깨끗한 작업 트리, CI/CD 모드(actionlint/yamllint/shellcheck/act 권장).
5. **행동 원칙 12개** — 우선순위 우선, 단일 책임, 명시적 확인(A/B/C), Dry-run, AC 우선, TDD 권장, 로컬 우선(CI/CD 모드 STEP 7.5 예외), GitHub Flow, 컨벤션 존중, 이슈 메타 발자국, 결정론적 타이 브레이커, 종료 후 보고.
6. **AI 시스템 프롬프트 — `/implement-top-issue`** 한 단락.
7. **워크플로우** STEP -1 ~ STEP 8:
   - **STEP -1 — 이슈 우선(Ticket-first) 가드** — 판정 규칙 G1~G5 (구현 지시인데 #NNN 없음 / `--issue` 가 `#[N]` 형식 / 파일명·제목만 / `--issue N` 미존재 또는 closed / `--issue N` 보드 Todo에 없음). 차단 시 메시지 + 복구 절차(`/append-issue` → `/register-issues-to-github` → 이 스킬 재호출, `--issue`엔 GitHub 실제 번호). bash 인자 형식 정규화 코드(`#[N]` 거부, 정수 강제).
   - STEP 0 — 사전 점검 + 보드 선택. KANBAN_TOKEN→GH_TOKEN 승격, OWNER/REPO/DEFAULT_BRANCH 자동 감지, 워킹트리 dirty 차단, 기본 브랜치 최신화, 프로젝트 후보 출력 + A/B/C 선택.
   - STEP 1 — 우선순위 기반 픽업. 정책 캐스케이드 4단(Priority 필드 → priority:p* 레이블 → 보드 표시 순서 → 이슈 번호). 정렬 키 `(priority_score, board_index, issue_number)`. 사용자 인자 `--issue` 강제 픽업 분기(G4/G5 검증). jq 코드(draft 카드 제외 `content.number != null`, Priority 경로 이중화 `.value."Priority" // .value.fieldValues.nodes[]`, `--include-priority` 필터링). 1.2 레이블 폴백(`gh issue list` 1회 + 메모리 맵). 1.3 보드 표시 순서 폴백.
   - STEP 1.5 — CI/CD 이슈 감지. 레이블 힌트(infra/ci/cd/cicd/strategy:cicd/[Infra]) + 제목 키워드 + 본문 경로 힌트(.github/workflows/, Dockerfile, fly.toml 등). `--cicd-mode auto|on|off` 처리. 사용자 확인 A/B/C/D.
   - STEP 2 — 'In Progress' 전이 + 본인 Assign. project_id, status_field_id, in_progress_option_id 추출 → `gh project item-edit`. assignee 추가, 시작 코멘트.
   - STEP 3 — 이슈 본문 분석 + AC 자동 파싱 + 브랜치 생성. slug(`feature/issue-N-kebab`, macOS iconv 폴백, 영문/숫자 40자). AC awk 파서(수락 기준 / Acceptance Criteria / AC / 인수 기준 + `- [ ]` 또는 `- [x]`). AC 부재 시 중단. 사용자에게 AC 매핑 초안 보여주고 A/B/C.
   - STEP 4 — 코드 구현(AC 기반). 4.A 일반 모드 원칙(TDD, YAGNI, 컨벤션, 작은 커밋, 민감 정보 금지). 4.B CI/CD 하이브리드 모드 — `ci-cd-pipeline`에 위임 A/B/C. 위임 시 컨텍스트(이슈 번호·AC·브랜치·리포·기본 브랜치) 전달, 같은 `$BRANCH` 위에 커밋 후 STEP 5로 복귀.
   - STEP 5 — 로컬 빌드/린트/테스트. 5.A 일반(package.json 자동 감지 npm/pnpm/yarn → build/lint/test, pyproject/requirements → ruff/flake8/pytest, go.mod → go build/vet/test, Cargo.toml → cargo build/clippy/test, e2e/tests/e2e 또는 @playwright/test 감지 시 Playwright). 5.B CI/CD 모드(actionlint/yamllint/shellcheck/act -n + Dockerfile 빌드 가능성 + 신규 워크플로우 파일 ≥ 1 검증). 5.C 검증 게이트 공통(BUILD/LINT/TEST/E2E 변수 캡처, GATE_FAIL 분기, 3회 연속 실패 시 사용자 보고).
   - STEP 6 — 커밋 & PR 생성. 민감 파일 감지(`.env*`, `secret`, `credential`, `*.pem`, `*.key`, `id_rsa`, CI/CD 워크플로 `${{ secrets.X }}` 리터럴은 안전 → 내용 grep 안 함). `git add -A` 금지(명시적 화이트리스트). Conventional Commits 스코프(`ci`/`feat`). 커밋 본문 `Refs #N`. PR 생성: `--base $DEFAULT --head $BRANCH --title "{scope}(#N): 제목" --body $PR_BODY --assignee $ME`. PR 본문 템플릿(개요/변경 사항/AC 충족 여부/로컬 검증/리뷰어 봐야 할 곳/비고 + `Closes #N`).
   - STEP 7 — 보드 'Review' 전이 + 이슈 PR 링크 코멘트.
   - STEP 7.5 — (CI/CD 모드 전용) 워크플로우 런 모니터링. `gh run list --branch $BRANCH --limit 1` → `gh run watch $RUN_ID --exit-status`. 성공 → PR 코멘트 🟢, 실패 → PR 코멘트 🔴 + run URL, 자동 리커버리 X.
   - STEP 8 — 최종 보고. 이슈/우선순위/모드/브랜치/PR/보드/변경 요약/로컬 검증/다음 액션.
8. **브랜치/커밋/PR 컨벤션 표**.
9. **안전장치(Safety Guards) 18개** — Dry-run, dirty tree 차단, 기본 브랜치 직접 푸시 금지, force-push 금지, 이슈 미존재 차단, Draft 카드 제외(`content.number != null`), AC 결손 차단, 검증 게이트 실결선(`|| true` 금지), 민감정보 차단, 명시적 staging, 단일 이슈 제한, 보드 인증 실패 처리, 강제 픽업 입력 검증(`--argjson`), iconv 폴백, Priority 필드 경로 이중화, CI/CD 모드 위임, 워크플로우 런 모니터링 종료 조건, **18번 Ticket-first 가드(어떤 --force도 우회 금지)**.
10. **실패/예외 처리 표** — Todo 비어있음, G1 GitHub 번호 없이 구현 요청, G2 `#[N]` 로컬 순번, G4 저장소 미존재, G5 보드에 없음, dirty tree, AC 부재, 빌드/테스트 실패 3회, Playwright 미설치, gh pr create 실패, status 옵션명 다름, 인증 권한 부족, 동일 이슈 PR 존재, ci-cd-pipeline 부재, actionlint/yamllint/shellcheck 미설치, 워크플로우 트리거 안 됨.
11. **다른 스킬과의 관계 (Single Responsibility)** — ASCII 다이어그램 + 표(generate-issues-* / register-issues-to-github / github-kanban / 본 스킬 / ci-cd-pipeline / 머지·릴리스 분리).
12. **사용 예시** 8건(다음 이슈 / 우선순위 높은 / P0만 / `--issue 42` / CI/CD 자동 위임 / `--cicd-mode off` / 보드 비어있으면 종료 / dirty 시 `--dry-run`).
13. **Changelog** — v1.4 / v1.3(CI/CD 하이브리드) / v1.2(20개 패치) / v1.1(우선순위 픽업) / v1.0.

## 톤 / 스타일
- 한국어 + bash/jq 코드블록.
- 모든 jq 코드는 `--argjson`/`--arg`로 안전 주입.

## 검증
- 트리거 키워드 13개 이상 모두 포함?
- STEP -1(Ticket-first 가드) G1~G5 모두 명시?
- 안전장치 18개 모두 명시(특히 #18 Ticket-first 가드)?
- CI/CD 하이브리드 모드 STEP 1.5/STEP 4.B/STEP 5.B/STEP 7.5 일관 흐름?
- jq에서 draft 카드 제외(`content.number != null`) 명시?
