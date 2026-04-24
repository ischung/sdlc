# Prompt — `register-issues-to-github` SKILL.md 생성 요청

## 역할
당신은 Claude 스킬 작성자입니다. **`register-issues-to-github` SKILL.md (v1.1)** 한 개 파일을 만드세요. 로컬 이슈 마크다운 파일을 GitHub 저장소에 일괄 등록하고 **STEP 9에서 칸반 보드 Todo 컬럼까지 반영**하는 "파일 → GitHub Issues → 칸반 보드" 원스톱 스킬입니다.

## 산출물 요구사항

### Frontmatter
- `name`: `register-issues-to-github`
- `description`: 로컬 이슈 마크다운 파일(issues.md / issues-layered.md / issues-vertical.md / cicd-issues.md / final-issues.md 등)을 읽어 GitHub 저장소에 이슈로 일괄 등록하고, **이어서 Projects v2 칸반 보드의 Todo 컬럼까지 반영**(v1.1). 각 이슈의 제목·본문을 파싱해 **적절한 레이블을 자동 결정**하고, 저장소에 해당 레이블이 없으면 표준 색상 팔레트로 **자동 생성** 후 부여. 중복 등록 방지(기존 이슈 타이틀·메타 라인 대조), Depends on #N 임시 번호를 실제 번호로 치환, 등록 성공 시 원본 파일에 `**GitHub Issue**: #N` 메타를 in-place 추가, 실패 항목 집계, Dry-run 지원. **STEP 9에서 github-kanban-skill의 add-issues / from-final-issues 로직을 호출**해 등록된 이슈를 보드 Todo에 일괄 배치(강한 opt-in). 존재 이유: "이슈 우선(Ticket-first) 원칙" — 이슈 없이 구현 시작 금지를 위해 파일·GitHub·보드 세 곳을 항상 같은 스냅샷으로 유지. KANBAN_TOKEN(또는 gh auth login) 인증, 파괴적 작업 전 opt-in(A/B/C/D). 트리거: "이슈 등록", "GitHub에 이슈 올려줘", "이슈 파일 등록", "/register-issues-to-github", "/push-issues", "/register-issues", "라벨 자동 생성해서 이슈 등록", "issues.md GitHub에 올려줘", "final-issues.md 등록", "이슈 파일 → GitHub", "보드에 이슈 올려줘", "파일에 있는 이슈 보드에 등록".

### 본문 구조

1. 제목: `# 이슈 파일 → GitHub 등록 스킬 v1.0` + 한 단락 요약(레이블 자동 분류·자동 생성·자동 부여, 중복 방지, 의존성 번호 치환, in-place 메타 업데이트).
2. **슬래시 커맨드 표** 3개: `/register-issues-to-github`, `/push-issues`, `/register-issues`. 이 스킬은 이슈를 새로 만들지 않으며 입력 파일이 전제. 파일 부재 시 `generate-issues-layered` / `-vertical` / `ci-cd-pipeline` 안내. 런타임 신규 이슈는 `append-issue` 사용. 한 번 실행에 파일 → GitHub → 보드까지 반영해 Ticket-first 원칙 강제.
3. **지원 입력 파일 & 자동 인식** — 우선순위 6단(final-issues.md ⭐ → cicd-issues.md → issues-vertical.md → issues-layered.md → issues.md → 사용자 명시 경로).
4. **행동 원칙 7개**:
   1. 파괴적 작업 opt-in (`gh issue create`/`gh label create`은 A/B/C/D 전 절대 실행 금지)
   2. 라벨 자동 생성(표준 색상, 기존은 덮어쓰지 않음)
   3. 중복 방지(`**GitHub Issue**: #N` 메타 + `gh issue list --search "in:title"`)
   4. 원본 보존(`<원본>.preregister-backup-YYYYMMDD-HHMMSS.md`)
   5. 의존성 일관성(임시 ID → 실제 번호 일괄 치환)
   6. 최소권한 토큰(KANBAN_TOKEN Classic PAT `repo` 또는 gh auth login만)
   7. 투명성(진행률 + 최종 요약)
5. **STEP 0 — Pre-flight**(bash) — gh/jq 미설치 확인, KANBAN_TOKEN→GH_TOKEN 승격(값 미출력), `repo` 스코프 확인 (없으면 `gh issue list --limit 1`로 fallback 판정), 대상 저장소 식별(`gh repo view --json nameWithOwner`).
6. **STEP 1 — 입력 파일 선택** — 후보 여러 개면 A~F 선택지(F 취소). 단 하나 고를 때까지 다음 단계 진행 금지.
7. **STEP 2 — 파일 파싱** 표 — 추출 대상 9가지: 로컬 순번 `#[N]`, 레이블 태그(`[Setup]` 등), Phase, 분할 전략, 의존성(`Depends on #N` / `CI-N`), 마일스톤, 순번 레이블(`order:NNN`), 필수 게이트(`mandatory-gate`), 배포 프로파일(`profile:<ID>`), 기존 GitHub 번호. jq 파서 어려우면 awk/sed 정규식.
8. **STEP 3 — 레이블 결정 규칙(자동 부여)** — 각 이슈의 레이블 집합은 다음의 합집합:
   - 3.1 카테고리 레이블 표(15개): `[Setup]`→`setup` `0052cc`, `[Infra]`→`infra` `1d76db`, `[DB]`→`db` `5319e7`, `[Backend]`→`backend` `0e8a16`, `[Core Logic]`→`core-logic` `b60205`, `[Frontend]`→`frontend` `d93f0b`, `[UI/UX]`→`ui-ux` `e99695`, `[Test]`/`[QA]`→`qa` `fbca04`, `[Docs]`→`docs` `c5def5`, `[Skeleton]`→`skeleton` `006b75`, `[Slice]`→`slice` `0075ca`, `[Ops]`→`ops` `5d4037`, `[A11y]`→`a11y` `f9d0c4`, `[CI/CD]`→`cicd` `0969da`.
   - 3.2 분할 전략 레이블: `strategy:layered` / `strategy:vertical-slice` / `strategy:cicd` 모두 `fef2c0`.
   - 3.3 Phase 레이블 표: `phase-0-skeleton` `bfdadc`, `phase-1-mvp` `bfd4f2`, `phase-2-extend` `d4c5f9`, `phase-3-ops` `f9d0c4`.
   - 3.4 우선순위 / 특수 표식: `mandatory-gate` `b60205`, `order:NNN` `ededed`, `profile:<ID>` `c2e0c6`, `priority:p0~p3` (`b60205` / `d93f0b` / `fbca04` / `c5def5`).
   - 3.5 사용자 커스텀: `**추가 레이블**: foo, bar` 라인이 있으면 그대로 부여, 미존재 시 회색 `ededed` 자동 생성.
9. **STEP 4 — 저장소 레이블 inventory & 자동 생성** (bash) — `gh label list --limit 500`, NEEDED_LABELS 배열, 색상 맵(연관 배열), MISSING 계산 후 사용자 A/B/C/D opt-in. A 선택 시 `gh label create` 루프 + 접두사별 자동 설명(order:/profile:/strategy:/phase-/priority:/mandatory-gate). 동적 레이블(`order:NNN` 등)은 등록 직전 ensure_label.
10. **STEP 5 — 등록 대상 요약 & 최종 opt-in** — 파일/저장소/총 이슈/이미 등록/동일 제목 존재/신규 등록/레이블 추가/마일스톤 보고 → A(전체) / B(Dry-run) / C(범위 지정) / D(취소).
11. **STEP 6 — 순차 등록(진행률)** (bash) — `CI_TO_REAL` 연관 배열, 각 블록에서 TITLE/BODY/LABELS/MILESTONE 추출, 동적 레이블 ensure_label, **의존성 치환** (이미 등록된 임시 ID → `Depends on #실번호`), `--label CSV` + `--milestone` 조건부, `gh issue create` 결과에서 `[0-9]+$` 추출. **2-pass**: 뒤늦게 등장하는 임시 ID 참조도 `gh issue list --search "Depends on TMP"`로 찾아 `gh issue edit --body`로 치환.
12. **STEP 7 — 원본 파일 in-place 메타 업데이트** (bash) — 백업 만든 후 awk로 `## #[TMP]` 헤더 다음에 `**GitHub Issue**: #N → URL` 라인 삽입. 이미 메타가 있는 블록은 건드리지 않음.
13. **STEP 8 — 최종 요약** — 원본/백업/저장소 + 결과(신규/건너뜀/실패/새 레이블) + 등록된 이슈 URL 상위 5 + 다음 단계 안내(STEP 9 진입).
14. **STEP 9 — 칸반 보드 반영(이슈 우선 원칙 자동 완결)** — 본 스킬의 본질 강조 박스("파일 → GitHub Issues → **칸반 보드** 세 곳 동일 스냅샷, STEP 9는 선택이 아닌 기본값").
   - 9.1 보드 존재 확인 & 선택 — `gh project list` 출력 후 분기 표(보드 1개 → Y/N, 여러 개 → A/B/C, 없음 → `/kanban-create` 안내 또는 그 자리에서 이어가기 opt-in).
   - 9.2 반영 모드 선택(opt-in) — A) `/kanban-from-final-issues` 호환 배치 ⭐(order:NNN 우선, 없으면 파일 등장 순서, mandatory-gate → P0) / B) `/kanban-add-issues` 단순 추가 / C) 건너뛰기(비권장 — 구현 스킬이 픽업 못함) / D) 취소.
   - 9.3 반영 실행 — A 선택 시 github-kanban-skill의 kanban-from-final-issues 플로우 진입(SRC 상속, CI_TO_REAL 매핑 우선 사용, 레이블 반영). B 선택 시 `gh project item-add` 루프.
   - 9.4 반영 결과 요약 — 보드/추가된 카드/P0 자동 설정/순서 권위/보드 URL.
   - 9.5 스킵(C 선택) 시 경고 로그 — 이슈 파일 맨 위에 HTML 주석으로 미반영 이슈 번호 + 재시도 안내. 같은 파일로 재실행 시 이 경고 감지 → 재질문.
15. **Dry-run 동작(STEP 5 → B 선택 시)** — 모든 API 호출 건너뛰고 추가될 레이블/이슈별 부여 레이블/의존성 치환 플랜/마일스톤 배정/예상 호출 수만 출력.
16. **오류 처리 가이드** 표 — 401 Bad credentials, label does not exist, milestone 미존재, 중복 제목, Depends on 미치환, rate limit.
17. **토큰(KANBAN_TOKEN) 요약** — Classic PAT `repo`(+ Projects 시 `project`), Fine-grained Issues R/W, `read -rs KANBAN_TOKEN` 화면 미표시 입력, GitHub Actions `env.GH_TOKEN: ${{ secrets.KANBAN_TOKEN }}`. 상세는 github-kanban 가이드 참조.
18. **선행·후속 스킬 연계** — Ticket-first 원칙 강조 박스 + ASCII 다이어그램(write-prd → write-techspec → generate-issues-vertical/-layered/ci-cd-pipeline/append-issue → 본 스킬 STEP 1~8 + STEP 9 → implement-top-issue / pickup-issue / work-next-issue). 선행/내장 후속/구현 스킬 설명.
19. **사용 예시** 4건.

## 톤 / 스타일
- 한국어 + bash 코드블록 적극 활용.
- 색상 hex는 GitHub 표준(`#` 제외, 6자리).

## 검증
- 트리거 키워드 12개 이상 모두 포함?
- STEP 0~9 모두 있고, STEP 9에 9.1~9.5 하위 단계가 있음?
- 카테고리 레이블 표 15종 + 색상 hex 정확?
- 2-pass 의존성 치환 로직(STEP 6 후반) 명시?
- in-place 메타 업데이트 시 백업 먼저 만들고 이미 메타 있는 블록은 건드리지 않음 명시?
- "Ticket-first" 원칙이 반복 강조됨?
