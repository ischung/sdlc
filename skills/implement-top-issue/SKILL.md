---
name: implement-top-issue
description: >
  GitHub Projects 보드에서 **가장 높은 우선순위의 이슈 1건**을 픽업해 GitHub Flow에 따라
  브랜치 생성 → 코드 구현(AC 기반) → 로컬 빌드/린트/단위·통합·E2E 테스트(UI는
  Playwright) → PR 생성(`Closes #N`) → 보드 상태 'In Progress' → 'Review' 전이까지
  자동으로 수행하는 '구현 담당 AI 개발자' 스킬 (v1.3).
  이슈가 **CI/CD 파이프라인 구축** 성격이면 감지 → `ci-cd-pipeline` 스킬에 구현을 위임하고,
  검증/PR/보드 전이/워크플로우 런 모니터링은 본 스킬이 마무리하는 **하이브리드 모드**로 동작.
  우선순위 결정 캐스케이드: Priority 커스텀 필드(P0~P3) → `priority:p0~p3` 레이블
  → 보드 표시 순서 → 이슈 번호(오름차순). 결정론적 키 `(priority_score, board_index, issue_number)`.
  ⚠️ 단일 책임 — 본 스킬은 **새 이슈를 만들지 않는다.** 보드에 처리할 이슈가 없으면
  중단하고, 먼저 `generate-issues-vertical` / `generate-issues-layered` →
  `register-issues-to-github` → `github-kanban` 워크플로우로 이슈를 만들도록 안내한다.
  한 번 실행에 **이슈 1건만** 처리한다.
  사용자가 "다음 이슈 구현해줘", "Todo 이슈 가져와서 작업해줘", "이슈 픽업해서
  PR까지 만들어줘", "최우선 이슈 작업", "다음 티켓 처리", "GitHub Flow로 이슈 처리",
  "보드 최상단 이슈 작업해줘", "우선순위 높은 이슈 구현해줘", "AI 개발자처럼 이슈 하나 끝내줘",
  "/implement-top-issue", "/pickup-issue", "/work-next-issue", "/implement-priority-issue"
  중 하나라도 언급하면 반드시 이 스킬을 사용할 것. 보드/리포지토리/프로젝트 번호가
  모호하면 먼저 사용자에게 확인하고 진행한다.
---

# 구현 담당 AI 개발자 스킬 — `implement-top-issue` v1.3

GitHub Projects 보드의 'Todo' 컬럼에서 **가장 높은 우선순위 이슈 1건**을 가져와 GitHub Flow에 따라 브랜치 생성 → 코드 구현 → 로컬 테스트 → PR 생성까지 자동으로 수행한다. 작업 중인 이슈는 'In Progress'로, PR을 만들면 'Review'로 전이시키며, 끝나면 PR URL과 작업 요약을 사용자에게 보고한다.

이슈가 **CI/CD 파이프라인 구축** 성격이면 STEP 4에서 `ci-cd-pipeline` 스킬에 구현을 위임하고(하이브리드 모드), STEP 5는 워크플로우 검증 툴체인(actionlint/yamllint/shellcheck/act)으로 스위치, STEP 7.5에서 `gh run watch`로 워크플로우 런을 모니터링한다.

## 핵심 약속

- **한 번에 이슈 1건만**. 다중 처리·병렬 실행 금지.
- **우선순위 기반 픽업**. 보드 최상단이 아니라 **정책적으로 계산된 최우선 이슈**를 고른다.
- **이슈 생성 금지**. 보드가 비었거나 'Todo'에 항목이 없으면 즉시 중단하고 선행 스킬 안내.
- **AC(Acceptance Criteria) 기반 구현**. AC가 없는 이슈는 사용자에게 보강을 먼저 요청.
- **로컬 우선**. CI/CD 의존 없이 로컬 빌드·린트·단위·통합·E2E 테스트를 통과시킨다.
- **UI는 Playwright**. UI 변경이 있으면 Playwright 시나리오를 작성/실행한다.
- **CI/CD 이슈는 위임**. 파이프라인 구축 성격이 감지되면 `ci-cd-pipeline`에 구현 위임 + 본 스킬이 검증·PR·모니터링 마무리.
- **PR 본문에 `Closes #N`** 명시. 머지 시 이슈가 자동 종료되도록 한다.
- **결정론적 선택**. 동률이면 `(priority_score, board_index, issue_number)` 키로 명확히 하나를 고른다.

---

## 슬래시 커맨드

| 커맨드 | 설명 |
| :---- | :---- |
| `/implement-top-issue` | 'Todo' 컬럼에서 최우선 이슈 1건 → 구현 → PR 생성까지 풀 사이클 |
| `/implement-priority-issue` | 위 커맨드의 별칭 (우선순위 기반임을 강조) |
| `/pickup-issue` | 위 커맨드의 별칭 |
| `/work-next-issue` | 위 커맨드의 별칭 |

### 주요 인자

| 인자 | 기본값 | 설명 |
| :---- | :---- | :---- |
| `--issue N` | — | 우선순위 무시, 지정 이슈를 강제 픽업 (STEP 1 분기) |
| `--priority P0\|P1\|P2\|P3` | — | 해당 우선순위 범위 내에서만 픽업 |
| `--include-priority` | `P0,P1,P2,P3` | 쉼표로 구분된 허용 우선순위 (예: `--include-priority P0,P1`) |
| `--dry-run` | off | 실제 변경 없이 계획만 출력 |
| `--cicd-mode` | auto | `auto`(감지) / `on`(강제 CI/CD 모드) / `off`(강제 일반 모드) |

---

## 전제 조건

| 항목 | 설명 |
| :---- | :---- |
| `gh` CLI | 설치 + `gh auth status`로 인증 확인. Project 쓰기에는 `project` 스코프 필요. |
| `git` | 설치 + 사용자 이름/이메일 설정. |
| 작업 디렉터리 | GitHub 리포지토리(루트). `gh repo view`로 자동 감지. |
| 기본 브랜치 | `gh repo view --json defaultBranchRef`로 자동 감지. `main`/`master`/`develop` 등 |
| 프로젝트 보드 | `github-kanban` 스킬로 사전 생성된 Projects v2 보드. 컬럼: Todo / In Progress / Review / Done. Priority 단일 선택 필드(P0~P3) 권장. |
| KANBAN_TOKEN (권장) | 조직 프로젝트나 Fine-grained PAT 환경에서는 `KANBAN_TOKEN`(Classic PAT, scope: `repo`, `project`)을 export. 본 스킬이 `GH_TOKEN`으로 자동 승격. |
| 깨끗한 작업 트리 | 시작 전 `git status`가 clean이어야 함. dirty면 사용자에게 stash/commit 여부 확인. |
| CI/CD 모드 (선택) | CI/CD 이슈 위임 시 `ci-cd-pipeline` 스킬 존재. 검증 툴 `actionlint` / `yamllint` / `shellcheck` / `act` 설치 권장. |

---

## 행동 원칙

1. **우선순위 우선**: 보드 최상단이 아니라 "가장 중요한 것"을 고른다. 캐스케이드: Priority 커스텀 필드 → `priority:p*` 레이블 → 보드 표시 순서 → 이슈 번호.
2. **단일 책임**: 본 스킬은 "이슈를 PR까지 끌고 가는" 한 가지만 한다. 이슈 생성·라벨 자동 생성·머지·릴리스는 다른 스킬에 위임. CI/CD 구현도 `ci-cd-pipeline`에 위임.
3. **명시적 확인**: 보드 선택, 이슈 픽업 결과, 브랜치명, PR 생성 직전, CI/CD 위임 직전 등 **destructive한 행동 직전에는 사용자에게 확인**(A/B/C 옵션)을 받는다.
4. **Dry-run 친화적**: `--dry-run` 인자 시 실제 변경 없이 계획만 출력.
5. **AC 우선**: 코드 작성 전에 AC를 체크리스트로 재나열하고, 각 AC를 어떻게 충족할지 한 줄씩 매핑. AC는 이슈 본문에서 **자동 파싱**.
6. **테스트 우선 사고(TDD 권장)**: 가능하면 실패하는 테스트부터 작성. 최소한 PR 전 테스트 추가는 강제.
7. **로컬 우선**: 모든 검증을 로컬에서 통과시킨다. CI 결과를 기다리는 워크플로우 가정 X. **예외**: CI/CD 모드에서는 STEP 7.5에서 원격 워크플로우 런을 폴링(설계상 필요).
8. **GitHub Flow 준수**: 기본 브랜치(자동 감지) 직접 푸시 금지. 항상 feature 브랜치 → PR.
9. **컨벤션 존중**: 리포지토리에 `.editorconfig`, `.eslintrc`, `prettier`, `pre-commit`, `Makefile`, `package.json scripts`, `pyproject.toml` 등 규칙이 있으면 그것을 우선 사용.
10. **이슈 메타에 발자국**: 작업 시작·종료 시 이슈에 코멘트(어느 브랜치에서 작업 중인지, PR 링크, 우선순위 신호)를 남긴다.
11. **결정론적 타이 브레이커**: 동률이면 `(priority_score, board_index, issue_number)` 키로 정렬. 재실행해도 같은 결과.
12. **종료 후 보고**: 항상 마지막에 PR URL + 변경 파일 요약 + 다음 권장 액션을 사용자에게 보고.

---

## AI 시스템 프롬프트 — `/implement-top-issue`

당신은 우리 프로젝트의 **'구현 담당 AI 개발자'**입니다. GitHub Projects 보드의 'Todo' 컬럼에서 **우선순위가 가장 높은 이슈**를 픽업하여, GitHub Flow(브랜치 → 커밋 → PR)에 따라 코드를 작성하고 로컬에서 검증한 뒤 기본 브랜치를 향한 Pull Request를 생성합니다. 이슈가 CI/CD 파이프라인 구축 성격이면 구현을 `ci-cd-pipeline` 스킬에 위임하고, 검증·PR·워크플로우 모니터링으로 마무리합니다. 한 번 실행에 **이슈 1건만** 처리하며, 보드에 처리할 이슈가 없으면 새 이슈를 만들지 않고 사용자에게 선행 워크플로우를 안내합니다.

---

## 워크플로우

### STEP 0 — 사전 점검 & 보드 선택

```bash
# 0.1 인증 / 리포 확인
# KANBAN_TOKEN이 있으면 GH_TOKEN으로 자동 승격 (이후 모든 gh 호출에서 재사용)
[ -n "$KANBAN_TOKEN" ] && export GH_TOKEN="$KANBAN_TOKEN"

gh auth status
OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name  -q '.name')

# 0.2 기본 브랜치 자동 감지 (main/master/develop 등 리포별 상이)
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name')
echo "리포지토리: $OWNER/$REPO   기본 브랜치: $DEFAULT_BRANCH"

# 0.3 작업 트리 깨끗한지 확인
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️ 워킹트리가 dirty 합니다. stash/commit 여부를 사용자에게 확인하세요."
  exit 1
fi

# 0.4 기본 브랜치 최신화
git fetch origin
git checkout "$DEFAULT_BRANCH"
git pull --ff-only origin "$DEFAULT_BRANCH"

# 0.5 프로젝트 번호 확인 (사용자 미지정 시 후보 출력 후 선택)
gh project list --owner "$OWNER" --format json | jq -r '.projects[] | "#\(.number) \(.title)"'
```

사용자에게 묻기:

"작업할 프로젝트 보드를 알려주세요.
A) #N (방금 출력된 목록 중 하나의 번호)
B) 보드가 아직 없어요 → `github-kanban` 스킬로 먼저 만드세요
C) 직접 이슈 번호로 작업할게요 → `--issue N` 인자로 다시 호출"

### STEP 1 — 우선순위 기반 최우선 이슈 픽업

> **선정 정책 (캐스케이드)**
> 1. **Priority 커스텀 필드** (P0/P1/P2/P3) — 가장 강한 신호. 숫자가 작을수록 높다.
> 2. **`priority:p0` ~ `priority:p3` 레이블** — 커스텀 필드가 없으면 폴백.
> 3. **보드 표시 순서** (gh project item-list 출력 순서) — 위 둘 다 없을 때의 폴백.
> 4. **이슈 번호 (오름차순)** — 궁극의 타이 브레이커.
>
> 정렬 키: `(priority_score, board_index, issue_number)`
> - `priority_score`: P0=0, P1=1, P2=2, P3=3, 없음=9
> - 레이블 기반 스코어도 동일 매핑
> - `board_index`: 보드상 위치 (0부터)

```bash
PROJECT_NUMBER=<사용자가 선택한 번호>

# 1.0 사용자 인자: --issue N 이 있으면 우선순위 계산 생략, 강제 픽업
if [ -n "$FORCE_ISSUE" ]; then
  ISSUE_NUMBER="$FORCE_ISSUE"
  # 해당 카드가 보드에 있는지 확인 (--argjson으로 안전 주입)
  TOP_ITEM_JSON=$(gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --format json --limit 200 \
    | jq -c --argjson n "$ISSUE_NUMBER" \
        '.items[] | select(.content.number==$n)')
  [ -z "$TOP_ITEM_JSON" ] && { echo "❌ #$ISSUE_NUMBER 이(가) 보드에 없습니다."; exit 1; }
else
  # 1.1 'Todo' 상태 + 우선순위 계산해서 정렬
  # jq: # 는 주석, // 는 대안 연산자
  # Projects v2 draft 카드는 content.number가 null이므로 반드시 제외
  TOP_ITEM_JSON=$(gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --format json --limit 200 \
    | jq -c --arg include "${INCLUDE_PRIORITY:-P0,P1,P2,P3}" '
        # 우선순위 문자열 → 숫자 스코어
        def score(p):
          if   p=="P0" then 0
          elif p=="P1" then 1
          elif p=="P2" then 2
          elif p=="P3" then 3
          else 9 end;

        # Projects v2 Priority 필드는 gh 버전에 따라 두 가지 경로로 평탄화될 수 있음
        def prio_field:
          ( .value."Priority"
            // ( .value.fieldValues.nodes[]?
                 | select(.field.name? == "Priority")
                 | .name? )
            // null );

        ($include | split(",")) as $allow
        | [ .items[]
            # draft 카드(링크된 이슈 없음) 제외
            | select(.content.number != null)
            # Todo 상태만
            | select(.status == "Todo")
          ] as $todo
        | ( $todo
            | to_entries  # board_index 부여
            | map({
                board_index: .key,
                item: .value,
                prio: (prio_field)
              })
          ) as $withPrio
        | $withPrio
        | map(. + {score: score(.prio)})
        | map(select(.prio == null or (.prio as $p | $allow | index($p))))
        | sort_by(.score, .board_index, (.item.content.number))
        | .[0]? | (if . == null then null else (.item + {_prio: .prio, _prio_source: "Projects-Priority-Field"}) end)
      ')

  # 1.2 Priority 필드가 없으면 priority:p* 레이블 기반으로 재시도
  if [ "$TOP_ITEM_JSON" = "null" ] || [ -z "$TOP_ITEM_JSON" ]; then

    # 모든 열린 이슈의 레이블을 1회 API 호출로 가져와 메모리 맵 작성 (N→1 API 호출 최적화)
    ALL_LABELS=$(gh issue list --repo "$OWNER/$REPO" --state open \
                   --json number,labels --limit 500 \
                 | jq -c 'map({(.number|tostring): [.labels[].name]}) | add')

    TOP_ITEM_JSON=$(gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --format json --limit 200 \
      | jq -c --argjson labels "$ALL_LABELS" --arg include "${INCLUDE_PRIORITY:-P0,P1,P2,P3}" '
          def labelScore(ls):
            if   (ls|index("priority:p0")) then 0
            elif (ls|index("priority:p1")) then 1
            elif (ls|index("priority:p2")) then 2
            elif (ls|index("priority:p3")) then 3
            else 9 end;

          def labelPrio(ls):
            if   (ls|index("priority:p0")) then "P0"
            elif (ls|index("priority:p1")) then "P1"
            elif (ls|index("priority:p2")) then "P2"
            elif (ls|index("priority:p3")) then "P3"
            else null end;

          ($include | split(",")) as $allow
          | [ .items[]
              | select(.content.number != null)
              | select(.status == "Todo")
            ]
          | to_entries
          | map({
              board_index: .key,
              item: .value,
              ls: ( $labels[(.value.content.number|tostring)] // [] )
            })
          | map(. + { prio: labelPrio(.ls), score: labelScore(.ls) })
          | map(select(.prio == null or (.prio as $p | $allow | index($p))))
          | sort_by(.score, .board_index, (.item.content.number))
          | .[0]? | (if . == null then null else (.item + {_prio: .prio, _prio_source: "priority-label"}) end)
        ')
  fi

  # 1.3 그래도 없으면 '보드 표시 순서 상단 = 최우선'으로 폴백
  if [ "$TOP_ITEM_JSON" = "null" ] || [ -z "$TOP_ITEM_JSON" ]; then
    TOP_ITEM_JSON=$(gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --format json --limit 200 \
      | jq -c '
          [.items[]
             | select(.content.number != null)
             | select(.status == "Todo")
          ] | .[0]? | (if . == null then null else . + {_prio: null, _prio_source: "board-top"} end)
        ')
  fi
fi

if [ "$TOP_ITEM_JSON" = "null" ] || [ -z "$TOP_ITEM_JSON" ]; then
  echo "❌ 'Todo' 컬럼이 비어 있거나 허용된 우선순위 범위에 항목이 없습니다."
  echo "→ 먼저 generate-issues-vertical / generate-issues-layered → register-issues-to-github → github-kanban 흐름으로 이슈를 만들거나 우선순위를 설정하세요."
  exit 0
fi

ITEM_ID=$(echo "$TOP_ITEM_JSON"     | jq -r '.id')
ISSUE_NUMBER=$(echo "$TOP_ITEM_JSON" | jq -r '.content.number')
ISSUE_TITLE=$(echo "$TOP_ITEM_JSON"  | jq -r '.content.title')
PRIO_LABEL=$(echo "$TOP_ITEM_JSON"   | jq -r '._prio // "N/A"')
PRIO_SOURCE=$(echo "$TOP_ITEM_JSON"  | jq -r '._prio_source // "board-top"')

echo "픽업: #$ISSUE_NUMBER — $ISSUE_TITLE  (우선순위: $PRIO_LABEL, 신호원: $PRIO_SOURCE)"
```

### STEP 1.5 — CI/CD 이슈 감지 (하이브리드 모드 판정)

```bash
# 이슈 본문/레이블/제목을 끌어와 CI/CD 성격 여부 판정
gh issue view "$ISSUE_NUMBER" --repo "$OWNER/$REPO" \
  --json title,body,labels,assignees > /tmp/issue-${ISSUE_NUMBER}.json

ISSUE_BODY=$(jq -r '.body // ""'          /tmp/issue-${ISSUE_NUMBER}.json)
ISSUE_LABELS=$(jq -r '[.labels[].name]|join(",")' /tmp/issue-${ISSUE_NUMBER}.json)

# 1) 레이블 힌트
LABEL_HINT=$(echo "$ISSUE_LABELS" | grep -Eo '\b(infra|ci|cd|cicd|strategy:cicd|\[Infra\])\b' | head -1)
# 2) 제목 키워드
TITLE_HINT=$(echo "$ISSUE_TITLE" | grep -Eoi 'CI/?CD|파이프라인|워크플로우|workflow|GitHub[[:space:]]*Actions|배포|deploy(ment)?' | head -1)
# 3) 본문 경로 힌트
BODY_HINT=$(echo "$ISSUE_BODY" | grep -Eo '\.github/workflows/|Dockerfile|Jenkinsfile|\.gitlab-ci\.yml|fly\.toml|render\.yaml' | head -1)

# 사용자 강제 오버라이드
case "${CICD_MODE:-auto}" in
  on)  IS_CICD=1 ;;
  off) IS_CICD=0 ;;
  *)
    if [ -n "$LABEL_HINT$TITLE_HINT$BODY_HINT" ]; then IS_CICD=1; else IS_CICD=0; fi
    ;;
esac

if [ "$IS_CICD" = "1" ]; then
  echo "🧭 CI/CD 성격 감지됨 — 힌트: label=[$LABEL_HINT] title=[$TITLE_HINT] body=[$BODY_HINT]"
fi
```

사용자 확인:

"보드에서 최우선 이슈를 픽업했습니다.

- **#$ISSUE_NUMBER**: $ISSUE_TITLE
- 우선순위: `$PRIO_LABEL`  (신호원: `$PRIO_SOURCE`)
- 보드: #$PROJECT_NUMBER
- CI/CD 모드: `$([ "$IS_CICD" = "1" ] && echo ON || echo OFF)`

이 이슈로 진행할까요?
A) 네, 진행해주세요
B) 다른 우선순위 범위로 다시 고르기 → `--include-priority P0` 같은 인자 사용
C) 특정 이슈 번호로 강제 픽업 → `--issue N`
D) 일단 멈출게요"

### STEP 2 — 'In Progress' 전이 + 본인 Assign

```bash
# 2.1 프로젝트 / Status 필드 / In Progress 옵션 ID
PROJECT_ID=$(gh project list --owner "$OWNER" --format json \
  | jq -r --argjson n "$PROJECT_NUMBER" '.projects[] | select(.number==$n) | .id')

STATUS_FIELD_ID=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json \
  | jq -r '.fields[] | select(.name=="Status") | .id')

INPROGRESS_OPTION_ID=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json \
  | jq -r '.fields[] | select(.name=="Status") | .options[] | select(.name=="In Progress") | .id')

# 2.2 보드 카드 상태 변경
gh project item-edit \
  --project-id "$PROJECT_ID" \
  --id "$ITEM_ID" \
  --field-id "$STATUS_FIELD_ID" \
  --single-select-option-id "$INPROGRESS_OPTION_ID"

# 2.3 본인을 assignee로 지정 (gh 인증 사용자 = 'AI 개발자' 계정)
ME=$(gh api user -q .login)
gh issue edit "$ISSUE_NUMBER" --repo "$OWNER/$REPO" --add-assignee "$ME"

# 2.4 이슈에 시작 코멘트 남기기 (우선순위 신호 명시)
gh issue comment "$ISSUE_NUMBER" --repo "$OWNER/$REPO" \
  --body "🤖 \`implement-top-issue\` 스킬이 이 이슈를 픽업했습니다.
- 우선순위: ${PRIO_LABEL}  (신호원: ${PRIO_SOURCE})
- 모드: $([ "$IS_CICD" = "1" ] && echo 'CI/CD 하이브리드' || echo '일반')
- 곧 \`feature/issue-${ISSUE_NUMBER}-...\` 브랜치에서 작업을 시작합니다."
```

### STEP 3 — 이슈 본문 분석 + AC 자동 파싱 + 브랜치 생성

```bash
# 3.1 슬러그 생성 (제목 → kebab-case, 영문/숫자만, 40자 내; macOS iconv 폴백)
SLUG=$(echo "$ISSUE_TITLE" \
  | { iconv -t ASCII//TRANSLIT 2>/dev/null || cat; } \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' \
  | cut -c1-40)
[ -z "$SLUG" ] && SLUG="task"

BRANCH="feature/issue-${ISSUE_NUMBER}-${SLUG}"
echo "브랜치명: $BRANCH"

# 3.2 AC 자동 파싱 (# 수락 기준 / Acceptance Criteria / AC / 인수 기준)
AC_LINES=$(echo "$ISSUE_BODY" | awk '
  /(^## )?(수락 기준|Acceptance Criteria|AC|인수 기준)/ {flag=1; next}
  /^## / && flag {flag=0}
  flag && /^[[:space:]]*-[[:space:]]*\[[ x]\]/ {print}
')

if [ -z "$AC_LINES" ]; then
  echo "⚠️ 이슈 본문에서 AC(수락 기준)를 찾지 못했습니다. 보강 후 재시도하세요."
  exit 1
fi

echo "AC 추출 결과:"
echo "$AC_LINES"

# 3.3 브랜치 생성 + 체크아웃
git checkout -b "$BRANCH"
```

사용자에게 다음을 보여준다:

```
📋 이슈 #$ISSUE_NUMBER 분석 결과

제목     : $ISSUE_TITLE
우선순위 : $PRIO_LABEL  (신호원: $PRIO_SOURCE)
레이블   : $ISSUE_LABELS
브랜치   : $BRANCH
모드     : [일반 | CI/CD 하이브리드]

AC(인수 기준):
$AC_LINES

각 AC에 대한 구현 매핑(초안):
- AC-1 → src/.../X.ts에서 함수 추가, 단위 테스트 1개
- AC-2 → API 엔드포인트 신설, 통합 테스트 1개
- AC-3 → UI 컴포넌트 수정, Playwright 시나리오 1개
        (또는 CI/CD 모드: .github/workflows/deploy.yml 워크플로우 + actionlint 통과)

이대로 구현을 시작할까요?
A) 네, 진행
B) AC 매핑을 수정하고 싶어요
C) 이슈 본문에 AC가 부족해요 → 보강 후 재시도
```

> **AC가 비어 있거나 모호하면** 즉시 중단하고 사용자에게 이슈 보강을 요청한다. 임의로 추정해서 구현 시작 금지.

### STEP 4 — 코드 구현 (AC 기반) · CI/CD 이슈면 위임 분기

#### 4.A 일반 모드 (IS_CICD=0)

원칙:

- **TDD 권장**: 가능하면 실패하는 테스트 → 구현 → 통과 순.
- **이슈 범위 안에서만 변경** (YAGNI). 무관한 리팩터는 별도 이슈로 분리.
- **컨벤션 존중**: 프로젝트의 lint/format 규칙을 그대로 따른다.
- **커밋 단위는 작게**, 메시지는 [Conventional Commits](https://www.conventionalcommits.org) 권장.
- **민감 정보 커밋 금지**: `.env`, 키 파일은 `.gitignore` 확인 후 staging.

#### 4.B CI/CD 하이브리드 모드 (IS_CICD=1)

CI/CD 구현은 본 스킬이 직접 수행하지 않고 **`ci-cd-pipeline` 스킬에 위임**한다. 사용자에게 다음을 묻는다:

"🧭 감지된 CI/CD 성격 이슈입니다. 어떻게 진행할까요?

A) `ci-cd-pipeline` 스킬에 **구현 위임** (권장)
   → 해당 스킬이 워크플로우 파일/표준·시크릿·캐시 전략·검증 도구를 만들고,
   → 본 스킬은 STEP 5(검증), STEP 6(PR), STEP 7(보드 전이), STEP 7.5(런 모니터링)를 마무리
B) 이 이슈를 **일반 모드로 강제 처리** (대부분 비권장) — `--cicd-mode off` 로 재호출
C) **CI/CD 성격 오판정** — 레이블/제목/본문 힌트를 재확인, 종료"

사용자가 A를 선택하면:
1. 본 스킬은 잠시 대기 상태가 되어 `ci-cd-pipeline` 스킬에 컨텍스트(이슈 번호·AC·브랜치·리포·기본 브랜치)를 전달한다.
2. `ci-cd-pipeline` 스킬이 **같은 브랜치 `$BRANCH`** 위에 워크플로우·관련 스크립트·문서를 커밋한다.
3. 돌아오면 STEP 5로 진입한다.

진행 중간 보고 예시: "AC-1(워크플로우 스켈레톤) 구현 완료. actionlint 0 오류 확인했어요. 다음 AC-2(시크릿 주입) 진행합니다."

### STEP 5 — 로컬 빌드 / 린트 / 테스트 (모드별 스위치)

#### 5.A 일반 모드

```bash
# 자동 감지 — 실패는 변수로 캡처 (|| true 로 삼키지 않는다)
has_script() { jq -re --arg k "$1" '.scripts[$k] // empty' package.json >/dev/null 2>&1; }
BUILD_OK=1; LINT_OK=1; TEST_OK=1; E2E_OK=1

if [ -f package.json ]; then
  PM=$(jq -r '.packageManager // "npm"' package.json | sed 's/@.*//')
  case "$PM" in
    pnpm) RUN="pnpm" ;;
    yarn) RUN="yarn" ;;
    *)    RUN="npm run" ;;
  esac
  has_script build && { $RUN build;  BUILD_OK=$?; BUILD_OK=$([ $BUILD_OK -eq 0 ] && echo 1 || echo 0); }
  has_script lint  && { $RUN lint;   LINT_OK=$?;  LINT_OK=$([ $LINT_OK  -eq 0 ] && echo 1 || echo 0); }
  has_script test  && { $RUN test;   TEST_OK=$?;  TEST_OK=$([ $TEST_OK  -eq 0 ] && echo 1 || echo 0); }
elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  ( ruff check . || flake8 . ); LINT_OK=$?;  LINT_OK=$([ $LINT_OK -eq 0 ] && echo 1 || echo 0)
  pytest -q;                     TEST_OK=$?;  TEST_OK=$([ $TEST_OK -eq 0 ] && echo 1 || echo 0)
elif [ -f go.mod ]; then
  go build ./... && go vet ./...; BUILD_OK=$?; BUILD_OK=$([ $BUILD_OK -eq 0 ] && echo 1 || echo 0)
  go test ./...;                  TEST_OK=$?;  TEST_OK=$([ $TEST_OK  -eq 0 ] && echo 1 || echo 0)
elif [ -f Cargo.toml ]; then
  cargo build && cargo clippy -- -D warnings; BUILD_OK=$?; BUILD_OK=$([ $BUILD_OK -eq 0 ] && echo 1 || echo 0)
  cargo test; TEST_OK=$?; TEST_OK=$([ $TEST_OK -eq 0 ] && echo 1 || echo 0)
fi

# UI 변경이면 Playwright E2E
if [ -d e2e ] || [ -d tests/e2e ] || grep -q '"@playwright/test"' package.json 2>/dev/null; then
  npx playwright install --with-deps >/dev/null 2>&1 || true
  npx playwright test; E2E_OK=$?; E2E_OK=$([ $E2E_OK -eq 0 ] && echo 1 || echo 0)
fi
```

#### 5.B CI/CD 모드

워크플로우/스크립트/Dockerfile 등을 대상으로 **정적 검증 + 드라이런**을 수행한다.

```bash
BUILD_OK=1; LINT_OK=1; TEST_OK=1; E2E_OK=1

# 5.B.1 GitHub Actions 워크플로우 정적 린트
if ls .github/workflows/*.yml >/dev/null 2>&1; then
  if command -v actionlint >/dev/null 2>&1; then
    actionlint; LINT_OK=$?; LINT_OK=$([ $LINT_OK -eq 0 ] && echo 1 || echo 0)
  else
    echo "⚠️ actionlint 미설치. brew install actionlint 또는 go install github.com/rhysd/actionlint/cmd/actionlint@latest 권장"
  fi

  if command -v yamllint >/dev/null 2>&1; then
    yamllint -d relaxed .github/workflows/; YL=$?
    [ $YL -ne 0 ] && LINT_OK=0
  fi
fi

# 5.B.2 셸 스크립트 린트
if command -v shellcheck >/dev/null 2>&1; then
  SH_FILES=$(git ls-files '*.sh' 2>/dev/null)
  if [ -n "$SH_FILES" ]; then
    echo "$SH_FILES" | xargs shellcheck; SC=$?
    [ $SC -ne 0 ] && LINT_OK=0
  fi
fi

# 5.B.3 Act 드라이런 (워크플로우 실행 없이 파싱·플랜만)
if command -v act >/dev/null 2>&1 && ls .github/workflows/*.yml >/dev/null 2>&1; then
  act -n; AC=$?
  BUILD_OK=$([ $AC -eq 0 ] && echo 1 || echo 0)
fi

# 5.B.4 Dockerfile 존재 시 빌드 가능성만 확인 (선택)
if [ -f Dockerfile ] && command -v docker >/dev/null 2>&1; then
  docker build --pull --no-cache -t implement-top-issue-ci-check . >/dev/null
  BR=$?; [ $BR -ne 0 ] && BUILD_OK=0
fi

# 5.B.5 "신규 워크플로우 파일 ≥ 1" 요건
NEW_WF=$(git diff --name-only --diff-filter=A "$DEFAULT_BRANCH"...HEAD -- '.github/workflows/*.yml' | wc -l | tr -d ' ')
if [ "$NEW_WF" = "0" ]; then
  echo "⚠️ 신규 워크플로우 파일이 없습니다. CI/CD 이슈 요건을 충족하지 못합니다."
  TEST_OK=0
else
  TEST_OK=1
fi
E2E_OK=1  # CI/CD 모드에서는 E2E 미요구 (런 모니터링은 STEP 7.5)
```

#### 5.C 검증 게이트 (공통)

```bash
GATE_FAIL=0
for v in "$BUILD_OK" "$LINT_OK" "$TEST_OK" "$E2E_OK"; do
  [ "$v" = "0" ] && GATE_FAIL=1
done

echo "검증 게이트: build=$BUILD_OK lint=$LINT_OK test=$TEST_OK e2e=$E2E_OK  →  $([ $GATE_FAIL -eq 0 ] && echo PASS || echo FAIL)"

if [ "$GATE_FAIL" = "1" ]; then
  echo "❌ 검증 게이트 실패. STEP 4로 회귀하여 수정하세요 (3회 연속 실패 시 사용자에게 보고)."
  exit 1
fi
```

게이트가 깨지면 STEP 4로 회귀해 수정. 3회 연속 실패하면 사용자에게 막힌 지점을 보고하고 도움 요청.

**게이트 요구사항 요약**:
- 일반 모드: 빌드 / 린트 / 단위·통합 테스트 통과 + 신규 테스트 ≥ 1 (UI 변경 시 Playwright ≥ 1)
- CI/CD 모드: actionlint / yamllint / shellcheck 0 오류 + `act -n` 파싱 성공 + **신규 워크플로우 파일 ≥ 1**

### STEP 6 — 커밋 & PR 생성

```bash
# 6.1 변경 검토
git status
git diff --stat

# 6.2 민감 파일 감지 (커밋 전)
#   ⚠️ CI/CD 모드에서는 워크플로우의 ${{ secrets.X }} 패턴은 정상 문법이므로 화이트리스트.
#   그 외 파일 경로 기반 차단만 유지.
DANGER=$(git status --porcelain | awk '{print $2}' | \
  grep -E '(^|/)\.env(\..+)?$|secret|credential|\.pem$|\.key$|id_rsa' || true)
# 워크플로우 YAML 내부의 ${{ secrets.FOO }} 리터럴은 안전하므로 별도 처리 없음 (내용 grep 하지 않음)

if [ -n "$DANGER" ]; then
  echo "⚠️ 민감해 보이는 파일이 staging 대상에 포함되어 있습니다:"
  echo "$DANGER"
  echo "→ .gitignore 또는 사용자 확인 후 진행하세요. 자동 커밋 중단."
  exit 1
fi

# 6.3 명시적 staging (git add -A 금지; 추적 중인 변경만 선택)
CHANGED=$(git status --porcelain | awk '$1 !~ /^\?\?/ {print $2}')
UNTRACKED=$(git status --porcelain | awk '$1 == "??" {print $2}')

if [ -n "$UNTRACKED" ]; then
  echo "ℹ️ 추적되지 않은 파일이 있습니다. 필요하면 명시적으로 git add 하세요:"
  echo "$UNTRACKED"
fi

if [ -n "$CHANGED" ]; then
  echo "$CHANGED" | xargs -I{} git add "{}"
fi

# 6.4 커밋
COMMIT_SCOPE=$([ "$IS_CICD" = "1" ] && echo "ci" || echo "feat")
git commit -m "$(cat <<EOF
${COMMIT_SCOPE}: ${ISSUE_TITLE}

이슈 #${ISSUE_NUMBER} 의 AC를 충족하는 구현.

- 변경점 요약
- 신규 테스트/워크플로우 N개

Refs #${ISSUE_NUMBER}
EOF
)"

# 6.5 원격에 브랜치 푸시
git push -u origin "$BRANCH"

# 6.6 PR 생성 (Closes #N 으로 이슈 자동 종료 링크)
PR_BODY=$(cat <<EOF
## 개요
이슈 #${ISSUE_NUMBER} (${ISSUE_TITLE}) 구현.

- 우선순위: ${PRIO_LABEL}  (신호원: ${PRIO_SOURCE})
- 모드: $([ "$IS_CICD" = "1" ] && echo 'CI/CD 하이브리드' || echo '일반')

Closes #${ISSUE_NUMBER}

## 변경 사항
- (자동 요약: 변경 파일 / 추가·삭제 라인)
- (구현 핵심 결정사항)

## 인수 기준 충족 여부
$(echo "$AC_LINES" | sed 's/\[ \]/[x]/g')

## 로컬 검증
- ✅ 빌드 ($BUILD_OK)
- ✅ 린트 ($LINT_OK)
- ✅ 테스트 ($TEST_OK)
- ✅ E2E/워크플로우 드라이런 ($E2E_OK)

## 리뷰어가 봐야 할 곳
- \`경로/파일\` — 핵심 로직
- \`경로/파일.test\` — 회귀 방지 테스트
$([ "$IS_CICD" = "1" ] && echo "- \`.github/workflows/*.yml\` — 워크플로우 정의")

## 비고
- (성능, 보안, 마이그레이션 영향 등)

---
🤖 Generated by \`implement-top-issue\` skill (v1.3)
EOF
)

PR_URL=$(gh pr create \
  --base "$DEFAULT_BRANCH" \
  --head "$BRANCH" \
  --title "${COMMIT_SCOPE}(#${ISSUE_NUMBER}): ${ISSUE_TITLE}" \
  --body "$PR_BODY" \
  --assignee "$ME")

echo "PR 생성됨: $PR_URL"
```

> 본 스킬은 **PR 생성**까지만 한다. 자동 머지·릴리스는 수행하지 않는다.

### STEP 7 — 보드 상태 'Review'로 전이 + 이슈 코멘트

```bash
# 7.1 'Review' 옵션 ID
REVIEW_OPTION_ID=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json \
  | jq -r '.fields[] | select(.name=="Status") | .options[] | select(.name=="Review") | .id')

# 7.2 보드 카드 상태 변경
gh project item-edit \
  --project-id "$PROJECT_ID" \
  --id "$ITEM_ID" \
  --field-id "$STATUS_FIELD_ID" \
  --single-select-option-id "$REVIEW_OPTION_ID"

# 7.3 이슈에 PR 링크 코멘트
gh issue comment "$ISSUE_NUMBER" --repo "$OWNER/$REPO" \
  --body "✅ 구현 완료. 리뷰 부탁드립니다 → ${PR_URL}"
```

### STEP 7.5 — (CI/CD 모드 전용) 워크플로우 런 모니터링

CI/CD 이슈의 특성상 **로컬에서 완전 검증이 불가능**하고, PR 푸시 시점에 실제 워크플로우가 돌아야 완결된다. 따라서 CI/CD 모드에서는 PR 생성 직후 대상 워크플로우 런을 폴링한다.

```bash
if [ "$IS_CICD" = "1" ]; then
  # 가장 최근의 브랜치 기준 런을 대기
  LATEST_RUN_ID=$(gh run list --branch "$BRANCH" --limit 1 --json databaseId -q '.[0].databaseId')

  if [ -n "$LATEST_RUN_ID" ] && [ "$LATEST_RUN_ID" != "null" ]; then
    echo "🔄 워크플로우 런 $LATEST_RUN_ID 모니터링 시작..."
    # --exit-status: 실패면 non-zero로 빠져나와 아래 분기로 전달
    if gh run watch "$LATEST_RUN_ID" --exit-status; then
      gh pr comment "$PR_URL" --body "🟢 워크플로우 런 $LATEST_RUN_ID 통과"
    else
      RUN_URL="https://github.com/$OWNER/$REPO/actions/runs/$LATEST_RUN_ID"
      gh pr comment "$PR_URL" --body "🔴 워크플로우 런 실패: $RUN_URL
→ 로그 확인 후 재푸시가 필요합니다. 본 스킬은 자동 리커버리 하지 않습니다."
      echo "❌ 워크플로우 실패. PR에 코멘트를 남겼습니다. 사용자에게 보고."
    fi
  else
    echo "ℹ️ 이 브랜치에 연결된 워크플로우 런이 아직 없습니다 (트리거 조건 확인 필요)."
  fi
fi
```

### STEP 8 — 사용자에게 최종 보고

```
✅ 작업 완료 보고

📌 이슈      : #${ISSUE_NUMBER} ${ISSUE_TITLE}
⭐ 우선순위  : ${PRIO_LABEL}  (신호원: ${PRIO_SOURCE})
🧭 모드      : [일반 | CI/CD 하이브리드]
🌿 브랜치    : ${BRANCH}  (베이스: ${DEFAULT_BRANCH})
🔁 PR        : ${PR_URL}
📊 보드      : #${PROJECT_NUMBER}  (Todo → In Progress → Review)

📝 변경 요약
  - 변경 파일 N개 (+추가 X / -삭제 Y 라인)
  - 신규 테스트/워크플로우: 단위 a · 통합 b · E2E c · 워크플로우 w
  - 핵심 변경점:
      1) ...
      2) ...

🧪 로컬 검증
  - 빌드 $BUILD_OK · 린트 $LINT_OK · 테스트 $TEST_OK · E2E/드라이런 $E2E_OK
  - (CI/CD 모드) 최신 런: ${LATEST_RUN_ID:-N/A}

🔜 다음 액션 권장
  A) 리뷰어 지정 + 코드 리뷰 요청
  B) 추가 이슈 처리 → /implement-top-issue 다시 실행
  C) 머지 후 보드 'Done' 전이 → 별도 머지/릴리스 스킬 사용
```

---

## 브랜치 / 커밋 / PR 컨벤션

| 항목 | 컨벤션 |
| :---- | :---- |
| 브랜치 | `feature/issue-{번호}-{kebab-slug}` (slug 영문/숫자, ≤ 40자) |
| 커밋 메시지 | Conventional Commits 권장. 본문 끝에 `Refs #N`. CI/CD 모드는 `ci(...)` 타입. |
| PR 제목 | `feat(#{번호}): {제목}` (CI/CD 모드는 `ci(#{번호}): ...`). 그 외 `fix`, `chore`, `docs`, `refactor`, `test` 허용. |
| PR 본문 | 위 STEP 6 템플릿 사용. **반드시 `Closes #{번호}` 포함**. |
| 베이스 브랜치 | `gh repo view --json defaultBranchRef`로 자동 감지. 특수 흐름(`develop` 등)은 STEP 0에서 사용자 확인. |

---

## 안전장치 (Safety Guards)

1. **Dry-run 모드**: `--dry-run` 인자 시 실제 commit/push/PR 생성 없이 계획만 출력.
2. **Dirty 워킹트리 차단**: 시작 전 `git status --porcelain` 비어있지 않으면 중단.
3. **기본 브랜치 직접 푸시 금지**: 자동 감지된 `$DEFAULT_BRANCH`에 직접 `git push` 호출 금지.
4. **force-push 금지**: 본 스킬은 `--force` / `--force-with-lease`를 자체적으로 호출하지 않는다.
5. **이슈 미존재 차단**: STEP 1에서 'Todo'가 비거나 허용 우선순위 범위에 없으면 즉시 종료. 절대 새 이슈 생성 X.
6. **Draft 카드 제외**: `.content.number != null` 필터로 Projects v2 draft 카드는 자동 제외.
7. **AC 결손 차단**: AC가 비어 있으면 STEP 3에서 중단하고 사용자에게 보강 요청.
8. **검증 게이트 실결선**: 빌드/린트/테스트/E2E 결과를 변수로 캡처하고 `GATE_FAIL` 분기로 종료. `|| true`로 실패를 삼키지 않는다.
9. **민감정보 차단**: 파일 경로 기반(`.env*`, `*secret*`, `*credentials*`, `*.pem`, `*.key`, `id_rsa`) 차단. CI/CD 워크플로우의 `${{ secrets.X }}` 리터럴은 안전 문법으로 간주 (내용 grep 대상 아님).
10. **명시적 staging**: `git add -A` 금지. 추적 중(tracked)인 변경만 화이트리스트로 stage. 미추적 파일은 사용자에게 별도 확인.
11. **단일 이슈 제한**: 한 번 실행에 이슈 1건. 종료 후 사용자가 다시 호출해야 다음 이슈 진행.
12. **보드 인증 실패 처리**: `gh project ...`가 401/403이면 STEP 0의 `KANBAN_TOKEN` 가이드로 회귀.
13. **강제 픽업 입력 검증**: `--issue N` 사용 시 `--argjson`으로 안전 주입(셸 인젝션 차단).
14. **iconv 폴백**: macOS BSD iconv가 `//TRANSLIT`를 지원하지 않을 수 있으므로 실패 시 원문 pass-through.
15. **Priority 필드 경로 이중화**: gh CLI 버전별 평탄화 차이를 흡수하기 위해 `.value."Priority"`와 `.value.fieldValues.nodes[]` 둘 다 탐색.
16. **CI/CD 모드 위임**: CI/CD 성격 감지 시 구현은 `ci-cd-pipeline`에 위임. 본 스킬이 검증·PR·모니터링만 담당. 위임 스킬 부재 시 사용자에게 A/B/C 확인.
17. **워크플로우 런 모니터링 종료 조건**: STEP 7.5는 `gh run watch --exit-status`로 명시적 성공/실패 판정. 실패 시 자동 리커버리 금지, 사용자 보고로만 처리.

---

## 실패 / 예외 처리

| 상황 | 대응 |
| :---- | :---- |
| 'Todo'가 비어 있음 | 즉시 종료. `generate-issues-*` → `register-issues-to-github` → `github-kanban` 안내. |
| 허용 우선순위 범위에 항목이 없음 | `--include-priority` 변경 제안. |
| 작업 트리 dirty | 사용자에게 stash / commit / discard 선택 요청. 무단 변경 금지. |
| AC 부재/모호 | 이슈 본문 보강 요청. 추정 구현 금지. |
| 빌드/테스트 실패 (3회 연속) | 막힌 지점·로그·시도한 가설을 사용자에게 보고하고 도움 요청. |
| Playwright 미설치 | `npx playwright install --with-deps` 시도. 실패 시 사용자에게 환경 점검 요청. |
| `gh pr create` 실패 (브랜치 보호 등) | 보호 규칙·필수 체크 누락 여부 안내. 강제 우회 금지. |
| 보드 카드 status 옵션이 다른 이름 | "Todo/In Progress/Review/Done" 표준명 부재 시 사용자에게 매핑 확인. |
| 인증 권한 부족 (Project 쓰기) | `KANBAN_TOKEN` 가이드 + `repo`,`project` 스코프 안내. |
| 동일 이슈에 이미 열린 PR 존재 | 새 PR 생성 X. 기존 PR 링크를 보고하고 사용자 결정 대기. |
| CI/CD 모드인데 `ci-cd-pipeline` 스킬이 없음 | 사용자에게 설치 안내 + `--cicd-mode off` 재시도 옵션 제공. |
| actionlint/yamllint/shellcheck 미설치 | 경고 출력 후 해당 검사 스킵, 나머지 게이트는 계속 진행. |
| 워크플로우 런이 트리거되지 않음 | 트리거 조건(`on:` 절) 재확인 안내. 자동 수정 X. |

---

## 다른 스킬과의 관계 (Single Responsibility 분리)

```
[이슈 만들기]                                            [이슈 처리]                                [관리]
generate-issues-vertical ─┐                          ┌─ implement-top-issue ─┬─→ (CI/CD) ──→ ci-cd-pipeline  ─┐
generate-issues-layered  ─┼─→ register-issues-to-github ─→ github-kanban ─→  │    (일반)  ──→ 직접 구현          │
                          │                                                  └─→ 검증·PR·Review 전이·런 모니터링 ─┘
```

| 스킬 | 책임 |
| :---- | :---- |
| `generate-issues-vertical` / `generate-issues-layered` | 이슈 마크다운 파일 생성 (등록 X) |
| `register-issues-to-github` | 위 마크다운을 GitHub 이슈로 등록 + 라벨 자동 생성 + CI-N 치환 |
| `github-kanban` | Projects v2 보드 생성 + 등록된 이슈를 Todo에 배치 |
| **`implement-top-issue` (본 스킬)** | **Todo 1건 픽업 → 구현(또는 CI/CD 위임) → 로컬 검증 → PR + 보드 Review 전이 + (CI/CD) 런 모니터링** |
| `ci-cd-pipeline` | **CI/CD 파이프라인 구현 전담** — 워크플로우 표준·시크릿·캐시·검증 도구. 본 스킬이 하이브리드 모드에서 호출. |
| (별도) 머지/릴리스 스킬 | 리뷰 후 머지 + 보드 Done 전이 + 릴리스 노트 (본 스킬에서는 다루지 않음) |

본 스킬은 **이슈 생성·라벨 생성·머지·릴리스를 직접 수행하지 않는다.** 각 책임은 위 표의 다른 스킬로 분리되어 있다. **CI/CD 구현**도 본 스킬의 책임이 아니며, `ci-cd-pipeline`에 위임한다.

---

## 사용 예시 (사용자 발화)

- "다음 이슈 구현해줘" → `/implement-top-issue` 실행
- "우선순위 높은 이슈 먼저 작업해줘" → 동일 (기본 동작이 우선순위 기반)
- "P0만 먼저 치고 싶어" → `/implement-top-issue --include-priority P0`
- "이슈 #42 작업해줘" → `/implement-top-issue --issue 42` (STEP 1에서 강제 픽업)
- "CI/CD 이슈 같은데 자동 위임해줘" → CI/CD 감지 로직이 작동. A 선택 시 `ci-cd-pipeline` 위임.
- "CI/CD 이슈인데 그냥 내가 짤게, 일반 모드로 해" → `--cicd-mode off`
- "보드 비었지? 그럼 멈추고 알려줘" → STEP 1 종료 분기
- "지금 dirty인데 일단 보고만" → `--dry-run` 권장

---

## 변경 이력 (Changelog)

| 버전 | 변경 내용 |
| :---- | :---- |
| **v1.3** (현재) | **CI/CD 하이브리드 모드 추가 (옵션 C)**. STEP 1.5에서 레이블/제목/본문 힌트로 CI/CD 성격 감지 → STEP 4에서 A/B/C 확인 후 `ci-cd-pipeline`에 구현 위임. STEP 5 검증 툴체인을 모드별로 스위치(일반: build/lint/test/Playwright, CI/CD: actionlint/yamllint/shellcheck/act/신규 워크플로우 ≥1). STEP 6.2 민감정보 체크를 파일 경로 기반으로 유지하고 `${{ secrets.X }}` 리터럴은 안전 문법으로 간주. STEP 7.5 추가: `gh run watch --exit-status`로 워크플로우 런 모니터링 + PR 코멘트. Safety Guards #16, #17 신설, 행동 원칙 #7에 CI/CD 모드 예외 명시. 인자 `--cicd-mode auto\|on\|off` 추가. |
| **v1.2** | 20개 패치 일괄 반영. ① `KANBAN_TOKEN`→`GH_TOKEN` 자동 승격, ② 기본 브랜치 자동 감지 (`gh repo view --json defaultBranchRef`), ③ Draft 카드 제외 (`content.number != null`), ④ `\|\| true` 제거·변수 캡처로 실결선 검증 게이트 구현, ⑤ jq 주석을 `#`로 교정 (`//` 혼선 제거), ⑥ 셸 변수의 jq 주입을 `--argjson`으로 전환, ⑦ `git add -A` → 명시적 화이트리스트 staging, ⑧ 민감 파일 경로 패턴 감지 (`.env*`, `secret`, `*.pem`, `*.key`, `id_rsa`), ⑨ AC 자동 파싱(awk) 도입, ⑩ macOS iconv 폴백, ⑪ Priority 필드 경로 이중화, ⑫ 레이블 조회 N→1 API 최적화 (bulk `gh issue list` + 메모리 매핑), ⑬ `.items[] \| select(.number==$n)` shell 인젝션 방지, ⑭ 결정론적 타이 브레이커 키 `(priority_score, board_index, issue_number)`, ⑮ Safety Guards 10 → 15. |
| **v1.1** | 우선순위 기반 픽업으로 전환. Projects v2 Priority 필드 → `priority:p*` 레이블 → 보드 순서 캐스케이드. 인자 `--issue`, `--priority`, `--include-priority` 도입. |
| **v1.0** | 최초 릴리스. 보드 'Todo' 최상단 픽업 → In Progress → 브랜치 → AC 기반 구현 → 로컬 빌드/린트/단위/통합/E2E(Playwright) → PR(`Closes #N`) → Review 전이 → 보고. 단일 책임(이슈 생성/머지/릴리스 분리), Dry-run, Safety Guards 10종 포함. |
