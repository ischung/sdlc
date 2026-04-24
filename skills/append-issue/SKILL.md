---
name: append-issue
description: >
  프로젝트 진행 중 **새로 발생한 버그·기능·운영 이슈**를 기존 이슈
  마크다운 파일(issues.md / final-issues.md / issues-vertical.md /
  issues-layered.md / cicd-issues.md)에 **표준 블록 형식으로 append**
  하고, 이어서 `register-issues-to-github` 스킬을 호출해 GitHub Issues
  + 칸반 보드 Todo 컬럼까지 한 번에 반영하는 "런타임 이슈 등록" 스킬.
  파일을 단일 진실 공급원(SSoT) 으로 유지하여 "이슈 없이 구현 금지"
  원칙을 강제한다. 대화형으로 제목·유형(bug/feature/chore/docs/ops)·
  설명·AC(수락 기준)·의존성·우선순위·분할 전략을 받아 블록을 생성하고,
  기존 최대 `#[N]` 로컬 순번을 찾아 N+1 로 이어 붙인다. append 직후
  자동으로 `register-issues-to-github` STEP 0~9 를 실행(사용자 opt-in)
  하여 파일·GitHub·보드 세 곳의 스냅샷을 같은 시점으로 맞춘다.
  사용자가 "이 버그 이슈로 등록해줘", "이 기능 새 이슈로 추가",
  "이슈 파일에 추가", "/append-issue", "/add-issue", "/new-issue",
  "이슈 하나 더 만들어줘", "런타임 이슈 등록", "파일에 이슈 append",
  "새 이슈 추가 후 보드에 올려줘" 중 하나라도 언급하면 반드시 이
  스킬을 사용할 것. ⚠️ 구현 요청("이거 고쳐줘", "이 기능 만들어줘") 이
  왔는데 아직 이슈가 없다면, 이 스킬을 **먼저** 호출한 다음에
  implement-top-issue 로 넘어가야 한다.
---

# 런타임 이슈 append 스킬 — `append-issue` v1.0

프로젝트 진행 중 새로 생긴 요구사항(버그 수정·기능 추가·운영 개선)을
**이슈 파일 → GitHub Issues → 칸반 보드** 세 곳에 "이슈 우선(Ticket-first)
원칙" 대로 반영한다.

---

## 왜 이 스킬이 필요한가 — 교육적 배경

대학 강의에서 소프트웨어 공학을 가르칠 때 가장 먼저 학생들에게
주입해야 하는 원칙 중 하나가 **"추적성(Traceability)"** 이다. 모든
코드 변경은 "왜 이 변경이 존재하는가?" 라는 질문에 **이슈 번호 하나**로
답할 수 있어야 한다. 한 줄 비유:

> 병원에서 의사가 환자를 치료하기 전에 **차트(의무기록)** 를 먼저
> 여는 것과 같다. 차트 없이 환자에게 주사를 놓는 의사는 없다.

`generate-issues-*` 는 프로젝트 **초기 기획** 시 한 번에 대량의 이슈를
만들기 위한 스킬이다. 하지만 실제 개발은 초기 기획대로 흐르지 않는다.
QA 에서 버그가 나오고, 이해관계자가 새 기능을 요청하고, 운영에서
장애가 터진다. 이런 **런타임 이슈** 도 똑같이 파일 → GitHub → 보드의
경로로 기록돼야 **같은 기준으로 우선순위·의존성·진행 상황**이 추적된다.

이 스킬은 그 공백을 메운다.

---

## 슬래시 커맨드

| 커맨드 | 설명 |
| :---- | :---- |
| `/append-issue` | 대화형으로 이슈를 받아 파일에 append → register-issues-to-github 호출 |
| `/add-issue` | 별칭 |
| `/new-issue` | 별칭 |

### 주요 인자

| 인자 | 기본값 | 설명 |
| :---- | :---- | :---- |
| `--file <path>` | 자동 감지 | append 대상 이슈 파일(아래 우선순위 참고) |
| `--type bug\|feature\|chore\|docs\|ops\|test` | 대화형 질문 | 이슈 유형 (레이블 결정에 사용) |
| `--title "..."` | 대화형 질문 | 이슈 제목 |
| `--priority P0\|P1\|P2\|P3` | P2 | 우선순위 |
| `--depends-on #N[,#M...]` | 없음 | 선행 이슈 (로컬 순번 또는 실제 GitHub 번호) |
| `--skip-register` | off | append 만 하고 GitHub 등록/보드 반영은 건너뜀 (비권장) |
| `--dry-run` | off | 파일 변경·GitHub 호출 없이 생성될 블록 미리보기 |

---

## 행동 원칙

1. **파일은 단일 진실 공급원(SSoT)**: GitHub Issues / 보드는 파일의
   **사본**이다. 원본(파일)을 먼저 고치고 그 다음에 사본을 동기화한다.
2. **이슈 하나에 한 번 실행**: 한 번 실행으로 여러 이슈를 묶지 않는다.
   "사소해 보이니까 하나로 합치자" 는 유혹은 추적성을 깬다.
3. **표준 블록 형식 강제**: `generate-issues-*` 가 쓰는 블록 형식과
   동일한 스키마를 유지해야 `register-issues-to-github` 와
   `github-kanban-skill` 이 파싱에 실패하지 않는다.
4. **자동 순번**: 파일 내 가장 큰 `#[N]` 을 찾아 `#[N+1]` 로 이어 붙인다.
   사용자가 수동으로 번호를 정하지 않도록 한다(충돌 방지).
5. **AC 필수**: 수락 기준(Acceptance Criteria) 없이 append 하지 않는다.
   AC 가 없으면 사용자에게 "이 이슈가 '완료'라는 건 어떻게 확인하죠?" 를
   세 번 질문하여 최소 1개 이상의 체크박스를 채운다.
6. **파괴적 작업 opt-in**: 파일 수정 직전, GitHub/보드 반영 직전에
   A/B/C/D 확인.
7. **백업 우선**: 파일 수정 전에
   `<원본>.append-backup-YYYYMMDD-HHMMSS.md` 백업을 먼저 만든다.
8. **체인 실행**: 기본 동작은 append → register → kanban 까지 한 번에
   흐른다. `--skip-register` 를 쓰지 않는 한 체인은 끊기지 않는다.

---

## STEP 0 — Pre-flight

```bash
# 0.1 필수 커맨드
command -v gh >/dev/null || { echo "⚠️ gh 미설치 — --skip-register 로만 실행 가능"; }
command -v awk >/dev/null || { echo "❌ awk 미설치"; exit 1; }

# 0.2 KANBAN_TOKEN → GH_TOKEN 승격 (있을 때만)
[ -n "${KANBAN_TOKEN:-}" ] && export GH_TOKEN="$KANBAN_TOKEN"
```

---

## STEP 1 — 대상 이슈 파일 선택

현재 디렉터리를 스캔해 아래 우선순위로 기본 후보를 정한다. 같은 경로에
여러 개가 있으면 A/B/C 로 선택지를 제시한다.

1. `final-issues.md` ⭐ (CI/CD 통합본 — 실행 순서 권위)
2. `issues-vertical.md`
3. `issues-layered.md`
4. `cicd-issues.md`
5. `issues.md`
6. 사용자 직접 지정 (`--file`)

파일이 하나도 없다면:

```text
append 대상이 될 이슈 파일이 없습니다. 다음 중 하나를 선택하세요:

  A) 새로 issues.md 파일을 만든다 (빈 헤더 + 이번 이슈 한 개만 포함)
  B) 먼저 프로젝트 초기 이슈를 생성한다:
       /generate-issues-vertical   (수직 분할)
       /generate-issues-layered    (계층 분할)
       /ci-cd-pipeline             (CI/CD 포함 통합)
  C) 취소
```

---

## STEP 2 — 대화형 이슈 수집

다음 필드를 순서대로 질문한다. 인자로 넘어온 값이 있으면 해당 질문을
건너뛴다.

### 2.1 필수 필드

| 필드 | 질문 예시 | 검증 |
| :---- | :---- | :---- |
| 유형 | "이 이슈의 유형은? bug / feature / chore / docs / ops / test" | enum |
| 제목 | "이슈 제목을 한 줄로 써주세요 (80자 이내 권장)" | 1~120자 |
| 설명(Description) | "문제·동기·배경을 2~5줄로 설명해주세요" | 최소 20자 |
| 수락 기준(AC) | "이 이슈가 '완료' 라는 건 어떻게 확인하죠? 체크박스로 3개 이상 적어주세요." | ≥ 1 |

### 2.2 선택 필드

| 필드 | 기본값 | 비고 |
| :---- | :---- | :---- |
| 우선순위 | P2 | P0~P3, bug 유형은 기본 P1 |
| 분할 전략 | 파일의 기존 전략 상속 | Vertical Slice / Layered / CI/CD |
| Phase | Phase 1 · Core MVP | 파일이 `phase-*` 레이블을 쓰면 그중 선택 |
| 의존성 | 없음 | `#[N]` 또는 GitHub `#NNN` |
| 마일스톤 | 없음 | 기존 파일에 M0/M1 등이 있을 때만 권장 |
| 재현 절차 | bug 유형만 | Step 1 → Step 2 → 기대/실제 |

### 2.3 자동 파생

| 파생 항목 | 규칙 |
| :---- | :---- |
| 로컬 순번 `#[N]` | 파일 내 최대 순번 + 1 |
| 제목 태그 | `feature`→`[Backend]`/`[Frontend]`/`[Core Logic]` 중 본문 힌트로 선택, `bug`→`[Fix]`, `docs`→`[Docs]`, `ops`→`[Ops]`, `chore`→상황별 |
| 레이블 집합 | 유형·우선순위·분할 전략·Phase 합집합 |
| 브랜치 슬러그 힌트 | 제목 → kebab-case (40자) — implement-top-issue 가 이를 그대로 사용 |

---

## STEP 3 — 블록 렌더링 (표준 스키마)

아래는 **표준 블록 템플릿** 이다. `register-issues-to-github` 의 STEP 2
파서와 `github-kanban-skill` 의 `kanban-from-final-issues` 추출기가 모두
이 형식을 기대한다. 한 글자도 임의로 변형하지 말 것.

```markdown
## #[{N}] [{카테고리태그}] {제목}

**유형**: {bug|feature|chore|docs|ops|test}
**분할 전략**: {Layered|Vertical Slice|CI/CD}
**Phase**: {0 · Walking Skeleton|1 · Core MVP|2 · MVP 확장|3 · 운영화}
**우선순위**: {P0|P1|P2|P3}
**의존성**: {없음|Depends on #[M]|Depends on #NNN}
**마일스톤**: {없음|M0|M1|M2|M3}
**추가 레이블**: {없음|쉼표,구분,커스텀}

### 배경 / 문제
{2~5줄 설명}

### 재현 절차 (bug 유형일 때만)
1. …
2. …
3. 기대: …
   실제: …

### 구현 메모
{AC 충족을 위해 건드려야 할 모듈/경로/결정사항 한두 줄}

### 수락 기준 (Acceptance Criteria)
- [ ] {AC-1}
- [ ] {AC-2}
- [ ] {AC-3}

### 테스트 계획
- 단위: …
- 통합: …
- E2E(Playwright, UI 변경 시): …
```

⚠️ `**GitHub Issue**: #N` 메타 라인은 **여기서 절대 넣지 않는다**.
이 라인은 `register-issues-to-github` 가 실제 등록 후 in-place 로
추가한다. append 단계에서 미리 넣으면 중복 감지 로직이 오동작한다.

---

## STEP 4 — 미리보기 & opt-in

생성될 블록을 전체 출력하고 사용자에게 확인한다.

```text
아래 블록을 <파일명>.md 끝에 append 합니다:

  ─────────────────────────────────────────────
  (렌더된 블록 전체 미리보기)
  ─────────────────────────────────────────────

대상 파일 : final-issues.md
위치      : 파일 끝 (마지막 이슈 블록 다음)
백업      : final-issues.append-backup-20260424-103012.md
예상 레이블: bug, priority:p1, phase-1-mvp, strategy:vertical-slice
다음 단계 : register-issues-to-github → kanban-from-final-issues (자동)

어떻게 진행할까요?
  A) append + GitHub + 보드 반영까지 전부 진행 ⭐ (권장)
  B) append 만 하고 GitHub/보드 반영은 나중에 (--skip-register 와 동일)
  C) 블록을 수정하고 싶어요 → STEP 2 일부 필드 재질문
  D) 취소
```

---

## STEP 5 — 파일 append (STEP 4 에서 A 또는 B 선택 시)

```bash
SRC="<STEP 1 에서 선택된 파일>"
TS=$(date +%Y%m%d-%H%M%S)
cp -p "$SRC" "${SRC%.md}.append-backup-${TS}.md"

# 파일 끝이 개행으로 끝나는지 확인 (아니면 개행 추가)
[ -n "$(tail -c1 "$SRC")" ] && printf '\n' >> "$SRC"

# 블록 추가
cat >> "$SRC" <<'BLOCK'
(STEP 3 에서 렌더된 블록 내용)
BLOCK

echo "✅ $SRC 에 #[${N}] 블록 append 완료"
echo "💾 백업: ${SRC%.md}.append-backup-${TS}.md"
```

append 직후 파일을 다시 읽어 다음을 확인한다:

- 새 블록이 정확히 한 개만 추가되었는가?
- `#[N]` 이 기존 최대 번호 + 1 인가?
- 기존 이슈 블록들은 손상되지 않았는가? (라인 수 비교 + 랜덤 3개
  블록 해시 비교)

하나라도 어긋나면 **즉시 백업에서 복원** 하고 사용자에게 보고한다.

---

## STEP 6 — 후속 실행 (STEP 4 에서 A 선택 시)

**`register-issues-to-github` 스킬을 같은 세션에서 호출**한다.

- 입력 파일: STEP 1 에서 선택된 파일 (고정 전달, 사용자에게 다시 묻지
  않음)
- 등록 범위: 이번에 추가된 `#[N]` 블록 하나만 (나머지는 이미 메타가
  있으면 건너뛰므로 자연스럽게 배제됨)
- STEP 9 보드 반영까지 포함: 기본값 A (order 보존 배치)

체인 실행 도중 어느 단계에서 실패하면:

| 실패 지점 | 복구 정책 |
| :---- | :---- |
| append 실패 | 백업 자동 복원 + 중단. 후속 스킬 호출 안 함 |
| GitHub 등록 실패 | 파일 append 는 유지(취소하지 않음). `**GitHub Issue**` 메타가 없는 상태로 남으므로 재실행으로 복구 가능 |
| 보드 반영 실패 | GitHub 등록은 유지. STEP 9.5 경고 로그가 파일 상단에 추가되고, 사용자에게 `/kanban-from-final-issues` 수동 실행 안내 |

---

## STEP 7 — 최종 보고

```text
✅ 런타임 이슈 등록 완료

📁 파일       : final-issues.md
💾 백업       : final-issues.append-backup-20260424-103012.md
🧾 새 이슈    : #[19] [Fix] 로그인 시 세션 토큰 갱신 실패 (P1, bug)
🔗 GitHub     : #67  https://github.com/.../issues/67
📊 보드       : #7  Sprint 2026-04  (Todo 컬럼 19번째)
🏷 생성 레이블: 0  (모두 기존 존재)

⏭️ 이제 구현하시려면:
  /implement-top-issue --issue 67         # 이 이슈 강제 픽업
  /implement-top-issue --include-priority P1  # P1 범위에서 최우선 자동 픽업
```

---

## `--skip-register` / Dry-run 동작

- `--skip-register` : STEP 4 에서 B 선택과 동일. STEP 5(append) 까지만
  실행. **비권장** — 사용자에게 "나중에 반드시 `/register-issues` 또는
  `/kanban-from-final-issues` 를 실행해야 이슈가 구현 대기열에 잡힙니다"
  경고를 남긴다.
- `--dry-run` : STEP 5 도 실행하지 않고 STEP 3 의 렌더 결과만 출력.

---

## 오류 처리 가이드

| 증상 | 원인 | 조치 |
| :---- | :---- | :---- |
| 블록 형식 파싱 실패(register 단계) | STEP 3 템플릿에서 필드명 변형 | 템플릿 원형 복원 후 재실행 |
| `#[N]` 중복 | 파일에 임시 수정이 있어 순번이 꼬임 | 최대 순번 재계산 로직 재실행, 필요 시 수동 지정 |
| GitHub 등록 실패(401/403) | KANBAN_TOKEN 미설정/만료 | 토큰 재발급 후 재시도. 파일 append 는 이미 완료된 상태로 유지됨 |
| 보드 반영 실패 | 보드 미존재/권한 부족 | `/kanban-create` 로 보드 선생성 후 `/kanban-from-final-issues` 수동 실행 |
| AC 가 비어 있음 | 사용자가 대화에서 스킵 시도 | 3회 질문 루프. 끝까지 비면 등록 거부 |

---

## 다른 스킬과의 관계

```
                         ┌─ write-prd / write-techspec  (요구사항 문서)
                         │
[초기 기획 대량 이슈]   ┌┴── generate-issues-vertical / -layered / ci-cd-pipeline
                         │        └─→ issues-*.md / final-issues.md 생성
                         │
[런타임 신규 이슈]      └── **append-issue (본 스킬)** → 동일 파일에 한 건씩 append
                                  │
                                  ▼
                          register-issues-to-github
                            ├─ STEP 1~8: 파일 → GitHub Issues
                            └─ STEP 9 : GitHub → 칸반 보드 Todo
                                  │
                                  ▼
                          implement-top-issue / pickup-issue / work-next-issue
                            (보드 Todo 에서만 픽업 — append 없이 구현 시작 불가)
```

| 역할 | 스킬 |
| :---- | :---- |
| 초기 이슈 대량 생성 | `generate-issues-*`, `ci-cd-pipeline` |
| **런타임 이슈 1건 추가 (본 스킬)** | **`append-issue`** |
| 파일 → GitHub → 보드 동기화 | `register-issues-to-github` (STEP 9 포함) |
| 보드 자체 생성/관리 | `github-kanban-skill` |
| 실제 구현(PR 까지) | `implement-top-issue` 및 별칭들 |

---

## 사용 예시 (사용자 발화)

- "로그인 세션 토큰 버그 이슈 추가해줘" → `/append-issue` (bug)
- "대시보드에 CSV 내보내기 기능 이슈 만들어줘" → `/append-issue` (feature)
- "운영에서 메모리 누수 보여. 이슈로 먼저 등록하고 구현은 나중에" →
  `/append-issue` (ops, P0)
- "이 버그 빨리 고쳐줘" (이슈 없는 상태) → ⚠️ 곧바로 `/append-issue` 를
  먼저 실행해 파일·GitHub·보드에 등록한 뒤 구현 스킬로 넘어간다.
- "일단 파일에만 추가하고 등록은 나중에" →
  `/append-issue --skip-register`

---

## Changelog

| 버전 | 변경 내용 |
| :---- | :---- |
| **v1.0** (현재) | 최초 릴리스. 대화형 필드 수집, 표준 블록 템플릿, 자동 `#[N]` 순번, 백업, STEP 4 opt-in, `register-issues-to-github` STEP 9 까지 체인 실행, `--skip-register` / `--dry-run` 지원. 이슈 우선(Ticket-first) 원칙의 런타임 엔트리포인트. |
