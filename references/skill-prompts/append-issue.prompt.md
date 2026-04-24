# Prompt — `append-issue` SKILL.md 생성 요청

## 역할
당신은 Claude 스킬 작성자입니다. **`append-issue` SKILL.md (v1.0)** 한 개 파일을 만드세요. 프로젝트 진행 중 새로 발생한 버그/기능/운영 이슈를 기존 이슈 마크다운 파일에 표준 블록으로 append하고, 이어서 `register-issues-to-github`를 호출해 GitHub Issues + 칸반 보드 Todo까지 한 번에 반영하는 "런타임 이슈 등록" 스킬입니다.

## 산출물 요구사항

### Frontmatter
- `name`: `append-issue`
- `description`: 프로젝트 진행 중 **새로 발생한 버그·기능·운영 이슈**를 기존 이슈 마크다운 파일(issues.md / final-issues.md / issues-vertical.md / issues-layered.md / cicd-issues.md)에 **표준 블록 형식으로 append**하고, 이어서 `register-issues-to-github`를 호출해 GitHub Issues + 칸반 보드 Todo 컬럼까지 한 번에 반영. 파일을 SSoT(단일 진실 공급원)로 유지하여 "이슈 없이 구현 금지" 원칙 강제. 대화형으로 제목·유형(bug/feature/chore/docs/ops)·설명·AC·의존성·우선순위·분할 전략을 받아 블록을 생성하고, 기존 최대 `#[N]` 로컬 순번을 찾아 N+1로 이어 붙임. append 직후 자동으로 `register-issues-to-github` STEP 0~9를 실행(opt-in). 트리거: "이 버그 이슈로 등록해줘", "이 기능 새 이슈로 추가", "이슈 파일에 추가", "/append-issue", "/add-issue", "/new-issue", "이슈 하나 더 만들어줘", "런타임 이슈 등록", "파일에 이슈 append", "새 이슈 추가 후 보드에 올려줘". ⚠️ 구현 요청("이거 고쳐줘")이 왔는데 이슈가 없으면 **이 스킬을 먼저** 호출 후 implement-top-issue로.

### 본문 구조

1. 제목: `# 런타임 이슈 append 스킬 — \`append-issue\` v1.0` + 한 단락 요약(파일 → GitHub Issues → 칸반 보드 세 곳에 Ticket-first로 반영).
2. **왜 이 스킬이 필요한가 — 교육적 배경** — 추적성(Traceability) 강조, 의무기록 비유. `generate-issues-*`는 초기 기획용, 런타임 신규 이슈는 본 스킬로 같은 경로 반영.
3. **슬래시 커맨드 표** 3개: `/append-issue`, `/add-issue`, `/new-issue`. **주요 인자 표** — `--file`, `--type`, `--title`, `--priority`, `--depends-on`, `--skip-register`, `--dry-run`.
4. **행동 원칙 8개**:
   1. 파일은 SSoT
   2. 이슈 하나에 한 번 실행(묶기 금지)
   3. 표준 블록 형식 강제(register/kanban 파서 호환)
   4. 자동 순번(파일 내 최대 `#[N]` + 1)
   5. AC 필수("3번 질문 루프", AC 없으면 등록 거부)
   6. 파괴적 작업 opt-in
   7. 백업 우선(`<원본>.append-backup-YYYYMMDD-HHMMSS.md`)
   8. 체인 실행(append → register → kanban)
5. **STEP 0 — Pre-flight**(bash) — gh 미설치 시 `--skip-register` 안내, awk 필수, KANBAN_TOKEN → GH_TOKEN 승격.
6. **STEP 1 — 대상 이슈 파일 선택** — 우선순위 6개(final-issues.md ⭐ → issues-vertical.md → issues-layered.md → cicd-issues.md → issues.md → `--file`). 파일 부재 시 A(새 issues.md) / B(generate-issues-*/ci-cd-pipeline 안내) / C(취소).
7. **STEP 2 — 대화형 이슈 수집**:
   - 2.1 필수 필드 표 (유형 enum, 제목 1~120자, 설명 ≥ 20자, AC ≥ 1)
   - 2.2 선택 필드 표 (우선순위 P2 기본 / bug는 P1, 분할 전략 상속, Phase 1, 의존성, 마일스톤, 재현 절차 — bug 전용)
   - 2.3 자동 파생 표 (로컬 순번, 제목 태그 자동 결정, 레이블 집합, 브랜치 슬러그 힌트)
8. **STEP 3 — 블록 렌더링(표준 스키마)** — `generate-issues-*` 호환 마크다운 템플릿 ```markdown 블록으로 제공:
   - 헤더 `## #[{N}] [{카테고리태그}] {제목}`
   - 메타: 유형/분할 전략/Phase/우선순위/의존성/마일스톤/추가 레이블
   - 섹션: 배경·문제 / 재현 절차(bug 전용) / 구현 메모 / Acceptance Criteria(체크박스) / 테스트 계획(단위·통합·E2E)
   - ⚠️ `**GitHub Issue**: #N` 메타 라인은 **여기서 절대 넣지 않음** (register-issues-to-github가 in-place 추가)
9. **STEP 4 — 미리보기 & opt-in** — 렌더된 블록 전체 + 백업 파일명 + 예상 레이블 + 다음 단계 표시. A(전체 진행 ⭐) / B(append만, --skip-register와 동일) / C(필드 수정) / D(취소).
10. **STEP 5 — 파일 append**(bash) — `cp -p`로 백업 → 파일 끝 개행 보정 → `cat >> "$SRC" <<'BLOCK'` heredoc로 추가. append 직후 검증(블록 정확히 1개, `#[N]` = 최대+1, 기존 블록 손상 없음 — 라인 수 + 랜덤 3개 블록 해시). 어긋나면 즉시 백업 복원.
11. **STEP 6 — 후속 실행(STEP 4 A 선택 시)** — `register-issues-to-github`을 같은 세션에서 호출. 입력 파일 고정 전달, 등록 범위 새 `#[N]`만, STEP 9 보드 반영 기본 A. 실패 복구 정책 표(append 실패 → 백업 복원·중단, GitHub 등록 실패 → 파일 유지로 재실행 복구, 보드 반영 실패 → STEP 9.5 경고 로그 + `/kanban-from-final-issues` 수동 안내).
12. **STEP 7 — 최종 보고** — 파일/백업/새 이슈 번호·제목·우선순위/GitHub URL/보드/생성된 레이블 수 + 다음 액션 안내(`/implement-top-issue --issue 67`, `--include-priority P1`).
13. **`--skip-register` / Dry-run 동작** — `--skip-register`는 STEP 5까지만(비권장 경고), `--dry-run`은 STEP 3 렌더만.
14. **오류 처리 가이드** 표(블록 형식 파싱 실패, `#[N]` 중복, GitHub 등록 401/403, 보드 반영 실패, AC 비어있음 — 3회 질문 루프).
15. **다른 스킬과의 관계** — ASCII 다이어그램(write-prd/write-techspec → generate-issues-vertical/-layered/ci-cd-pipeline ↘ append-issue ↘ register-issues-to-github (STEP 1~8 / STEP 9) → implement-top-issue). 역할 표.
16. **사용 예시** 5건(로그인 토큰 버그 / CSV 내보내기 / 운영 메모리 누수 P0 / 이슈 없는 상태에서 "빨리 고쳐줘" → 본 스킬 먼저 / `--skip-register`).
17. **Changelog** — v1.0(현재).

## 톤 / 스타일
- 한국어, 표·코드 블록 적극 활용.
- 의료 비유(차트/의무기록)는 "왜 필요한가" 섹션에만 사용.

## 검증
- 트리거 키워드 9개 이상 모두 포함?
- 표준 블록 템플릿이 generate-issues-*과 동일 스키마?
- AC 3회 질문 루프 명시?
- STEP 5에 백업 → append → 검증 → 어긋나면 복원 흐름 모두 있음?
- `**GitHub Issue**: #N` 메타는 본 스킬에서 넣지 않는다는 경고 명시?
