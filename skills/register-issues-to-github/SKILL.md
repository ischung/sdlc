---
name: register-issues-to-github
description: >
  로컬 이슈 마크다운 파일(issues.md / issues-layered.md / issues-vertical.md
  / cicd-issues.md / final-issues.md 등)을 읽어 GitHub 저장소에 이슈로
  일괄 등록하는 스킬. 각 이슈의 제목·본문을 파싱하여 **적절한 레이블을
  자동으로 결정**하고, 저장소에 해당 레이블이 존재하지 않으면 표준 색상
  팔레트로 **자동 생성**한 뒤 부여한다. 중복 등록 방지(기존 이슈 타이틀·
  메타 라인 대조), Depends on #N 임시 번호를 실제 번호로 치환, 등록
  성공 시 원본 파일에 `**GitHub Issue**: #N` 메타를 in-place 로 추가,
  실패 항목 집계, Dry-run 지원을 포함한다. KANBAN_TOKEN(또는 gh auth
  login) 인증을 사용하며, 파괴적 작업 전에는 반드시 opt-in(A/B/C/D) 을
  받는다. 사용자가 "이슈 등록", "GitHub에 이슈 올려줘", "이슈 파일
  등록", "/register-issues-to-github", "/push-issues", "/register-issues",
  "라벨 자동 생성해서 이슈 등록", "issues.md GitHub에 올려줘",
  "final-issues.md 등록", "이슈 파일 → GitHub" 중 하나라도 언급하면
  반드시 이 스킬을 사용할 것.
---

# 이슈 파일 → GitHub 등록 스킬 v1.0

로컬에 저장된 이슈 마크다운 파일을 읽어 GitHub 저장소에 일괄 등록한다.
레이블 자동 분류·자동 생성·자동 부여, 중복 등록 방지, 의존성 번호 치환,
원본 파일 in-place 메타 업데이트를 담당한다.

---

## 슬래시 커맨드

| 커맨드 | 설명 |
| :---- | :---- |
| `/register-issues-to-github` | 지정한 이슈 파일을 GitHub 이슈로 등록 |
| `/push-issues` | 축약형 별칭 |
| `/register-issues` | 축약형 별칭 |

**이 스킬은 이슈를 "새로 만들지 않는다"** — 입력 파일(마크다운)이
전제다. 파일이 없으면 `generate-issues-layered` /
`generate-issues-vertical` / `ci-cd-pipeline` 실행을 먼저 안내한다.

---

## 지원 입력 파일 & 자동 인식

우선순위(같은 경로에 여러 개 존재 시 사용자에게 단 하나 선택 요청):

1. `final-issues.md` (ci-cd-pipeline 통합본)
2. `cicd-issues.md`
3. `issues-vertical.md`
4. `issues-layered.md`
5. `issues.md`
6. 사용자가 명시한 경로

---

## 행동 원칙

1. **파괴적 작업 opt-in**: `gh issue create`, `gh label create` 는 사용자
   A/B/C/D 선택 전에 절대 실행하지 않는다.
2. **라벨 자동 생성**: 저장소에 없는 레이블은 표준 색상으로 **만들어**
   부여한다. 기존 레이블(이름·색)은 덮어쓰지 않는다.
3. **중복 방지**: 이미 `**GitHub Issue**: #N` 메타가 있는 항목은 등록하지
   않는다. 추가로 기존 저장소의 동일 제목 이슈(`gh issue list --search
   "in:title <제목>"`) 도 건너뛰고 경고한다.
4. **원본 보존**: in-place 수정 전에 타임스탬프 백업
   (`<원본>.preregister-backup-YYYYMMDD-HHMMSS.md`) 을 만든다.
5. **의존성 일관성**: Depends on CI-N / #TEMP-N 같은 임시 참조를 등록 후
   실제 번호로 일괄 치환한다.
6. **최소권한 토큰**: `KANBAN_TOKEN`(Classic PAT 권장, `repo` 스코프) 또는
   `gh auth login` 세션만 사용. 토큰 값은 출력하지 않는다.
7. **투명성**: 각 이슈 등록 시 진행률 표시, 최종 요약에 성공/실패/건너뜀
   수와 URL 목록 포함.

---

## STEP 0 — Pre-flight

```bash
# 0.1 필수 커맨드
command -v gh >/dev/null || { echo "❌ gh CLI 미설치"; exit 1; }
command -v jq >/dev/null || { echo "❌ jq 미설치"; exit 1; }

# 0.2 인증 (KANBAN_TOKEN 이 있으면 GH_TOKEN 으로 export)
if [ -n "${KANBAN_TOKEN:-}" ]; then
  export GH_TOKEN="$KANBAN_TOKEN"
  echo "🔑 KANBAN_TOKEN 사용 (값은 출력하지 않음)"
fi
gh auth status >/dev/null 2>&1 || { echo "❌ 미인증 — gh auth login 또는 KANBAN_TOKEN 설정"; exit 1; }

# 0.3 repo 스코프 확인 (issue 쓰기용)
if ! gh auth status 2>&1 | grep -Eq "'repo'|scopes:.*\brepo\b"; then
  # 실호출로 fallback 판정
  gh issue list --limit 1 >/dev/null 2>&1 || { echo "❌ repo 스코프 없음 — PAT 재발급 또는 gh auth refresh -s repo"; exit 1; }
fi

# 0.4 대상 저장소 식별
REPO_FULL="${REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)}"
[ -z "$REPO_FULL" ] && { echo "❌ 저장소 미식별 — owner/repo 인자 필요"; exit 1; }
OWNER="${REPO_FULL%%/*}"; REPO="${REPO_FULL##*/}"
echo "대상 저장소: $REPO_FULL"
```

---

## STEP 1 — 입력 파일 선택

현재 디렉터리를 스캔해 지원 파일을 찾는다. 후보가 여러 개면 사용자에게
A/B/C/… 선택지를 제시해 **단 하나**만 고른다.

```text
다음 이슈 파일들이 발견되었습니다. 어느 파일을 등록할까요?
  A) final-issues.md      ⭐ 권장 (CI/CD 통합본)
  B) cicd-issues.md
  C) issues-vertical.md
  D) issues-layered.md
  E) 직접 경로 입력
  F) 취소
```

사용자가 A~E 중 하나를 고르기 전까지 다음 단계로 진행하지 않는다.

---

## STEP 2 — 파일 파싱

파일을 읽어 이슈 블록을 분리하고, 각 블록에서 다음 메타를 추출한다.

| 추출 대상 | 소스 |
| :---- | :---- |
| 로컬 순번 `#[N]` | 이슈 헤더 `## #[N] ...` |
| 레이블 태그 | 헤더의 `[Setup]`, `[DB]`, `[Slice]` 등 |
| Phase | 본문의 `**Phase**: 0 · Walking Skeleton` 등 |
| 분할 전략 | 헤더 `분할 전략: Layered / Vertical Slice` |
| 의존성 | `**의존성**: Depends on #N` 또는 `CI-N` |
| 마일스톤 | `**마일스톤**: M1 Core MVP` (있으면) |
| 순번 레이블 | `order:NNN` (있으면) |
| 필수 게이트 | `mandatory-gate` 표식(CI/CD 스킬 산출물) |
| 배포 프로파일 | `profile:<ID>` 표식 |
| 기존 GitHub 번호 | `**GitHub Issue**: #NNN` (있으면 중복으로 skip) |

jq 기반 파서가 어려우면 awk/sed 로 섹션 분리 후 정규식 매칭.

---

## STEP 3 — 레이블 결정 규칙 (자동 부여)

각 이슈에 부여할 **레이블 집합**은 다음 규칙의 **합집합**이다.

### 3.1 카테고리 레이블 (제목의 `[태그]` → 레이블 이름)

| 제목 태그 | GitHub 레이블 이름 | 기본 색(hex, `#` 제외) | 설명 |
| :---- | :---- | :---- | :---- |
| `[Setup]` | `setup` | `0052cc` | 초기 셋업 |
| `[Infra]` | `infra` | `1d76db` | 인프라·공통 미들웨어 |
| `[DB]` | `db` | `5319e7` | 데이터 모델·마이그레이션 |
| `[Backend]` | `backend` | `0e8a16` | API 엔드포인트 |
| `[Core Logic]` | `core-logic` | `b60205` | 도메인 로직 |
| `[Frontend]` | `frontend` | `d93f0b` | 컴포넌트·페이지 |
| `[UI/UX]` | `ui-ux` | `e99695` | 스타일·반응형·접근성 |
| `[Test]` / `[QA]` | `qa` | `fbca04` | 테스트 |
| `[Docs]` | `docs` | `c5def5` | 문서화 |
| `[Skeleton]` | `skeleton` | `006b75` | Walking Skeleton |
| `[Slice]` | `slice` | `0075ca` | Vertical Slice |
| `[Ops]` | `ops` | `5d4037` | 운영·관측성 |
| `[A11y]` | `a11y` | `f9d0c4` | 접근성 |
| `[CI/CD]` | `cicd` | `0969da` | 파이프라인 이슈 |

### 3.2 분할 전략 레이블 (공통 부여)

- `분할 전략: Layered` → `strategy:layered` (색 `fef2c0`)
- `분할 전략: Vertical Slice` → `strategy:vertical-slice` (색 `fef2c0`)
- `ci-cd-pipeline` 산출물 → `strategy:cicd` (색 `fef2c0`)

### 3.3 Phase 레이블 (존재 시)

| 본문 표기 | 레이블 |
| :---- | :---- |
| Phase 0 · Walking Skeleton | `phase-0-skeleton` (색 `bfdadc`) |
| Phase 1 · Core MVP | `phase-1-mvp` (색 `bfd4f2`) |
| Phase 2 · MVP 확장 | `phase-2-extend` (색 `d4c5f9`) |
| Phase 3 · 운영화 | `phase-3-ops` (색 `f9d0c4`) |

### 3.4 우선순위 / 특수 표식

- `mandatory-gate` (보안·E2E·Smoke 등) → `mandatory-gate` (색 `b60205`)
- `order:NNN` → `order:NNN` (색 `ededed`) — 있는 그대로 전달
- `profile:<ID>` → `profile:<ID>` (색 `c2e0c6`)
- 본문에 P0/P1/P2/P3 표기 → `priority:p0` ~ `priority:p3`
  (색 `b60205` / `d93f0b` / `fbca04` / `c5def5`)

### 3.5 사용자 커스텀 레이블

이슈 본문에 `**추가 레이블**: foo, bar` 라인이 있으면 그대로 부여 대상에
추가한다. 저장소에 없으면 **회색(`ededed`)** 으로 새로 만든다.

---

## STEP 4 — 저장소 레이블 inventory & 자동 생성

등록 루프에 진입하기 전에 **딱 한 번** 실행한다.

```bash
# 4.1 현재 저장소 레이블 목록
EXISTING_LABELS=$(gh label list --repo "$REPO_FULL" --limit 500 --json name -q '.[].name')

# 4.2 이번 등록에 필요한 레이블 집합 (STEP 3 규칙으로 산출) — 예시:
NEEDED_LABELS=(
  "setup" "infra" "db" "backend" "core-logic" "frontend" "ui-ux" "qa" "docs"
  "skeleton" "slice" "ops" "a11y" "cicd"
  "strategy:layered" "strategy:vertical-slice" "strategy:cicd"
  "phase-0-skeleton" "phase-1-mvp" "phase-2-extend" "phase-3-ops"
  "mandatory-gate"
  # order:NNN, profile:<ID> 등은 실제 이슈에서 동적으로 추가
)

# 4.3 표준 색상 맵
declare -A COLOR
COLOR[setup]="0052cc";       COLOR[infra]="1d76db"
COLOR[db]="5319e7";          COLOR[backend]="0e8a16"
COLOR[core-logic]="b60205";  COLOR[frontend]="d93f0b"
COLOR[ui-ux]="e99695";       COLOR[qa]="fbca04"
COLOR[docs]="c5def5";        COLOR[skeleton]="006b75"
COLOR[slice]="0075ca";       COLOR[ops]="5d4037"
COLOR[a11y]="f9d0c4";        COLOR[cicd]="0969da"
COLOR["strategy:layered"]="fef2c0"
COLOR["strategy:vertical-slice"]="fef2c0"
COLOR["strategy:cicd"]="fef2c0"
COLOR["phase-0-skeleton"]="bfdadc"
COLOR["phase-1-mvp"]="bfd4f2"
COLOR["phase-2-extend"]="d4c5f9"
COLOR["phase-3-ops"]="f9d0c4"
COLOR["mandatory-gate"]="b60205"
COLOR["priority:p0"]="b60205"
COLOR["priority:p1"]="d93f0b"
COLOR["priority:p2"]="fbca04"
COLOR["priority:p3"]="c5def5"

# 4.4 누락 레이블 계산 & 사용자 확인
MISSING=()
for L in "${NEEDED_LABELS[@]}"; do
  echo "$EXISTING_LABELS" | grep -qxF "$L" || MISSING+=("$L")
done

if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "⚠️  저장소에 없는 레이블 ${#MISSING[@]} 개가 필요합니다:"
  printf '   • %s\n' "${MISSING[@]}"
  # opt-in
  echo "자동으로 생성할까요?"
  echo "  A) 모두 생성"
  echo "  B) 하나씩 확인하며 생성"
  echo "  C) 레이블 없이 이슈 본문에만 카테고리 표시 (등록은 label 없이)"
  echo "  D) 취소"
fi
```

A 선택 시:

```bash
for L in "${MISSING[@]}"; do
  COL="${COLOR[$L]:-ededed}"   # 매핑 없으면 회색
  # 기본 설명: order:/profile: 같은 범주는 접두사 기반 설명
  DESC=""
  case "$L" in
    order:*)    DESC="Execution order rank (auto)";;
    profile:*)  DESC="Deployment profile (auto)";;
    strategy:*) DESC="Issue splitting strategy";;
    phase-*)    DESC="Project phase";;
    priority:*) DESC="Priority tier";;
    mandatory-gate) DESC="Immutable safety gate (security/E2E/smoke)";;
    *)          DESC="Auto-created by register-issues-to-github";;
  esac
  if gh label create "$L" --repo "$REPO_FULL" --color "$COL" --description "$DESC" 2>/dev/null; then
    echo "  ✅ label created: $L (#$COL)"
  else
    echo "  ℹ️  label exists or failed: $L (skip)"
  fi
done
```

> 동적으로 추가될 `order:NNN` / `profile:<ID>` / 커스텀 레이블은 각 이슈
> 등록 **직전**에 같은 방식으로 존재 여부를 확인하고 없으면 그 자리에서
> 생성한다.

---

## STEP 5 — 등록 대상 요약 & 최종 opt-in

```text
등록 요약
  • 파일       : final-issues.md
  • 저장소     : myorg/myrepo
  • 총 이슈    : 23 개
  • 이미 등록  : 3 개 (GitHub Issue 메타 존재 → 건너뜀)
  • 동일 제목 존재 : 1 개 (저장소에서 발견 → 건너뜀)
  • 신규 등록  : 19 개
  • 레이블 추가: 6 개 자동 생성 (승인됨)
  • 마일스톤   : M0/M1/M2/M3 (ci-cd-pipeline 산출물일 때 자동 생성)

진행 방식:
  A) 전체 등록 진행
  B) Dry-run — 실제 호출 없이 요약만 출력
  C) 일부만 등록 (순번 범위 지정, 예: 1-10)
  D) 취소
```

---

## STEP 6 — 순차 등록 (진행률)

```bash
declare -A CI_TO_REAL    # 임시 ID(#[N], CI-N) → 실제 GitHub 번호
FAILED=()

while IFS= read -r BLOCK_ID; do
  TITLE=$(extract_title "$BLOCK_ID")
  BODY=$(extract_body   "$BLOCK_ID")
  LABELS_ARR=($(determine_labels "$BLOCK_ID"))   # STEP 3 규칙 적용
  MILESTONE=$(extract_milestone "$BLOCK_ID")

  # 동적 레이블 (order:NNN / profile:X / 사용자 커스텀) 선생성
  for L in "${LABELS_ARR[@]}"; do
    ensure_label "$L"
  done

  # 의존성 치환 — 이미 등록된 임시 ID 는 실제 번호로
  for TMP in "${!CI_TO_REAL[@]}"; do
    BODY="${BODY//Depends on ${TMP}/Depends on #${CI_TO_REAL[$TMP]}}"
  done

  # --label 옵션 문자열 (쉼표 구분)
  LABEL_CSV=$(IFS=,; echo "${LABELS_ARR[*]}")

  # 등록
  URL=$(gh issue create --repo "$REPO_FULL" \
          --title "$TITLE" \
          --body  "$BODY"  \
          --label "$LABEL_CSV" \
          ${MILESTONE:+--milestone "$MILESTONE"} 2>/dev/null) || {
    FAILED+=("$BLOCK_ID"); echo "  ❌ #$BLOCK_ID 등록 실패"; continue
  }

  REAL_NUM=$(echo "$URL" | grep -oE '[0-9]+$')
  CI_TO_REAL["$BLOCK_ID"]="$REAL_NUM"
  echo "  ✅ local #$BLOCK_ID → GitHub #$REAL_NUM  (labels: $LABEL_CSV)"

done < <(list_issue_blocks)

# 2-pass: 이미 등록된 이슈 중 뒤늦게 등장하는 Depends on 참조를 마저 치환
for TMP in "${!CI_TO_REAL[@]}"; do
  REAL=${CI_TO_REAL[$TMP]}
  # 각 실제 이슈 body 를 fetch → 치환 후 업데이트
  NEEDS_UPDATE=$(gh issue list --repo "$REPO_FULL" --search "Depends on ${TMP}" --json number -q '.[].number')
  for N in $NEEDS_UPDATE; do
    NEW_BODY=$(gh issue view "$N" --repo "$REPO_FULL" --json body -q .body \
               | sed "s|Depends on ${TMP}|Depends on #${REAL}|g")
    gh issue edit "$N" --repo "$REPO_FULL" --body "$NEW_BODY" >/dev/null
  done
done
```

---

## STEP 7 — 원본 파일 in-place 메타 업데이트

등록 완료 후, 원본 파일의 각 이슈 블록 아래에 `**GitHub Issue**: #N
(<URL>)` 메타 라인을 삽입한다. 먼저 백업을 만든다.

```bash
SRC="final-issues.md"   # 또는 선택된 파일
cp -p "$SRC" "${SRC%.md}.preregister-backup-$(date +%Y%m%d-%H%M%S).md"

for TMP in "${!CI_TO_REAL[@]}"; do
  REAL=${CI_TO_REAL[$TMP]}
  URL="https://github.com/$REPO_FULL/issues/${REAL}"
  # 블록의 헤더(## #[TMP] …) 다음에 메타 라인을 끼워 넣기
  awk -v tmp="$TMP" -v real="$REAL" -v url="$URL" '
    { print }
    /^## #\['"$TMP"'\]/ { print "**GitHub Issue**: #" real "  \u2192 " url }
  ' "$SRC" > "$SRC.tmp" && mv "$SRC.tmp" "$SRC"
done
```

이미 `**GitHub Issue**: #N` 이 있는 블록은 이번 런에서 **건너뛴 것**이므로
변경하지 않는다.

---

## STEP 8 — 최종 요약

```text
✅ GitHub 등록 완료!

📁 원본 파일 : final-issues.md
💾 백업      : final-issues.preregister-backup-20260422-100542.md
🧾 저장소    : myorg/myrepo

📊 결과
  • 신규 등록 : 19 건
  • 건너뜀    : 3 건 (이미 메타 있음) + 1 건 (동일 제목 저장소에 존재)
  • 실패      : 0 건
  • 새로 만든 레이블 : 6 개  (setup, infra, db, slice, mandatory-gate, order:001)

🔗 등록된 이슈 URL (상위 5개)
  • #42 [Setup] 저장소 초기화 — https://github.com/.../issues/42
  • #43 [Infra] CI 기본 워크플로 — …
  • …

⏭️ 다음 단계
  • 칸반 보드로 관리: github-kanban 스킬 → /kanban-from-final-issues
  • 이슈 상태 ↔ PR 동기화: /kanban-sync
```

---

## Dry-run 동작 (STEP 5 → B 선택 시)

모든 API 호출을 건너뛰고 다음을 출력한다.

- 저장소에 추가될 레이블 목록 (개수·이름·색)
- 각 이슈별로 **부여될 레이블 집합** 미리보기
- 의존성 치환 플랜(`CI-3 → (등록 후 #?)`)
- 마일스톤 배정 플랜
- 예상 `gh issue create` 호출 수

실제 쓰기 작업은 없으므로 안전하게 검토 가능하다.

---

## 오류 처리 가이드

| 증상 | 원인 | 조치 |
| :---- | :---- | :---- |
| `HTTP 401 Bad credentials` | KANBAN_TOKEN 만료/오타 | 새 PAT 발급 후 재주입 |
| `label does not exist` | 레이블 동기화 실패 | STEP 4 재실행, 또는 `gh label list` 로 수기 확인 |
| `could not resolve to a Milestone` | 마일스톤 미존재 | ci-cd-pipeline STEP 4.3 로 선생성하거나, 이 스킬에서 `--milestone` 생략 |
| 중복 이슈 제목 경고 | 같은 제목이 저장소에 이미 있음 | 기본: skip / 강제 등록하려면 `ALLOW_DUP=1` 환경변수 |
| Depends on 미치환 | 임시 ID 와 파일 내 표기 불일치 | STEP 6 의 2-pass 치환이 작동하려면 `CI-N` 또는 `#[N]` 표기가 일관돼야 함 |
| rate limit | API 제한 | 실패 항목만 재시도, 필요 시 0.3s 슬립 삽입 |

---

## 토큰(KANBAN_TOKEN) 요약

- Classic PAT 권장, 스코프: **`repo`** (+ Projects 연계 시 `project`)
- Fine-grained PAT: Repository permissions → **Issues: Read and write**
- 환경변수 주입:
  ```bash
  read -rs KANBAN_TOKEN && export KANBAN_TOKEN    # 화면 미표시 입력
  ```
- GitHub Actions: `env.GH_TOKEN: ${{ secrets.KANBAN_TOKEN }}`
- 상세 가이드는 `github-kanban` 스킬의 "인증 토큰(KANBAN_TOKEN) 설정
  가이드" 섹션을 참조 (본 스킬도 동일 원칙 사용).

---

## 선행·후속 스킬 연계

- **선행**: `generate-issues-layered` / `generate-issues-vertical` /
  `ci-cd-pipeline` 중 하나로 생성된 이슈 파일.
- **후속**: `github-kanban` 으로 등록된 이슈를 Projects(v2) 칸반에 배치
  (`/kanban-from-final-issues` 권장).

---

## 사용 예시

- "issues-layered.md 를 GitHub 에 등록해줘" → `/register-issues-to-github`
- "final-issues.md 올려주고 레이블도 자동으로 만들어줘" → `/push-issues`
- "Dry-run 으로 먼저 보여줘" → STEP 5 에서 B 선택
- "1번부터 10번만 등록" → STEP 5 에서 C 선택 → 범위 입력
