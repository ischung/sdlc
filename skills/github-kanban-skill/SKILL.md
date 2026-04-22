---
name: github-kanban-skill
description: >
  GitHub Projects(v2) 기반의 칸반 보드를 gh CLI로 자동 생성·구성하고, 현재
  리포지토리(또는 사용자가 지정한 리포지토리)의 이슈를 정렬 규칙에 따라 Todo
  컬럼에 일괄 등록하는 스킬. Todo / In Progress / Review / Done 4단계 상태
  컬럼을 보장하고, 선택적으로 Priority·Size·Sprint 커스텀 필드를 추가한다.
  파괴적 작업 전에는 반드시 사용자 opt-in(A/B/C/D)을 받고, 기존 프로젝트/이슈가
  있으면 재사용·중복 방지 로직으로 안전하게 재실행할 수 있다. 또한
  ci-cd-pipeline 스킬이 생성한 "final-issues.md"와 연계하여 order:NNN 레이블,
  mandatory-gate 레이블, profile: 레이블을 인식해 실행 순서대로 보드에 배치할
  수 있다. 사용자가 "칸반 보드 만들어줘", "GitHub 프로젝트 생성", "이슈 관리
  보드", "프로젝트 보드 설정", "gh project", "이슈를 칸반에 등록", "티켓 보드",
  "스프린트 보드", "애자일 보드", "/kanban-create", "/kanban-add-issues",
  "/kanban-status", "/kanban-from-final-issues", "/kanban-sync",
  "/kanban-teardown", "final-issues 보드에 올려줘", "KANBAN_TOKEN", "PAT 설정",
  "GitHub Actions 프로젝트 토큰", "gh 인증" 중 하나라도 언급하면 반드시 이
  스킬을 사용할 것. CI/CD·헤드리스 환경에서는 PAT를 KANBAN_TOKEN 환경변수로
  주입하도록 명시적으로 안내한다. 프로젝트 이름을 사용자가 제공하지 않았으면
  먼저 물어본 뒤 진행한다.
---

# GitHub Kanban 자동화 스킬 v2.0

이 스킬은 숙련된 DevOps·PM 엔지니어 역할로 `gh` CLI \+ GitHub GraphQL API를 사용해 GitHub Projects(v2) 칸반 보드를 생성·구성하고 이슈를 안전하게 배치한다. 파괴적 작업(프로젝트 생성, 이슈 일괄 등록, 상태 일괄 변경, 보드 삭제 등) 이전에는 항상 사용자 확인을 받는다.

---

## 슬래시 커맨드

| 커맨드 | 설명 |
| :---- | :---- |
| `/kanban-create` | 새 칸반 보드 생성 \+ 오픈 이슈 전체 등록 (확인 후) |
| `/kanban-add-issues` | 기존 보드에 이슈 추가 등록 (중복 제외) |
| `/kanban-status` | 보드 현황 조회 (컬럼별 이슈 수·상위 항목) |
| `/kanban-from-final-issues` | `final-issues.md` 기반 보드 생성·배치 (order:NNN 순서 보존) |
| `/kanban-sync` | 이슈 상태(open/closed, PR 연결)와 보드 상태 동기화 |
| `/kanban-teardown` | 보드 삭제 (opt-in, 이슈 자체는 유지) |

커맨드 파일은 `./commands/` 하위에 별도 파일로 존재해야 하며, 프로젝트별로는 `.claude/commands/`에, 전역으로는 `~/.claude/commands/`에 복사한다.

---

## 인증 토큰(KANBAN\_TOKEN) 설정 가이드

이 스킬은 **두 가지 인증 경로** 중 하나만 있으면 동작한다. 로컬 개발자는 보통 `gh auth login` 한 번으로 충분하지만, **CI/CD·서버· 컨테이너처럼 대화형 로그인이 불가능한 환경**에서는 PAT(Personal Access Token)를 환경변수 `KANBAN_TOKEN` 으로 주입해야 한다. GitHub Actions의 기본 `GITHUB_TOKEN` 은 Projects(v2)에 쓰기 권한이 없으므로 반드시 별도 PAT가 필요하다.

### 1\) 어떤 토큰을 만들어야 하나?

| 방식 | 권장 | 이유 |
| :---- | :---- | :---- |
| Fine-grained PAT | ⭐ 권장 | 레포지토리·조직 범위를 한정할 수 있고 만료일 강제 |
| Classic PAT | 대안 | 조직 Projects 접근 제약이 있을 때만 |

필요 권한(최소권한 원칙):

- **Fine-grained PAT**  
  - Repository access: 대상 리포 선택  
  - Repository permissions → **Issues: Read and write**  
  - Repository permissions → **Metadata: Read-only** (자동)  
  - Organization permissions → **Projects: Read and write**  
  - 만료일: 30\~90일 권장  
- **Classic PAT**  
  - 스코프: `repo` (Issues 쓰기용), `project` (Projects v2 쓰기)  
  - 조직 PAT 승인 정책이 있으면 Owner에게 승인 요청 필요

### 2\) 토큰 발급 절차 (Fine-grained)

1. [https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new) 접속  
2. Token name: `kanban-bot-<repo>` 처럼 용도를 드러내는 이름  
3. Expiration: 예) 90 days  
4. Repository access: Only select repositories → 대상 선택  
5. Permissions: 위 표의 최소 권한 지정  
6. Generate token → **한 번만 표시되는 값 복사** (다시 볼 수 없음)

### 3\) 로컬 셸에 주입

**일회성(권장, 히스토리에 남지 않게)**

read \-rs KANBAN\_TOKEN && export KANBAN\_TOKEN

\# (붙여넣기 후 Enter — 입력이 화면에 표시되지 않음)

**영구 설정 (개인 개발 머신만, 공유 장비에서는 금지)**

\# \~/.zshrc 또는 \~/.bashrc 의 맨 끝에

export KANBAN\_TOKEN="github\_pat\_\*\*\*"   \# 권한 600 파일로 옮기는 걸 권장

\# 권한 확인

chmod 600 \~/.zshrc

`.env`·`.envrc`에 적는 경우 반드시 `.gitignore` 에 포함시키고 커밋 전 `git status` 로 재확인한다.

### 4\) GitHub Actions 에서 사용

저장소 Settings → Secrets and variables → Actions → New repository secret 에 `KANBAN_TOKEN` 이름으로 등록한 뒤 워크플로에서 다음과 같이 주입한다.

jobs:

  sync-board:

    runs-on: ubuntu-latest

    steps:

      \- uses: actions/checkout@v4

      \- name: Set up gh

        run: gh \--version

      \- name: Sync kanban

        env:

          \# GH\_TOKEN 으로 이름을 바꿔 주입하면 gh CLI 가 자동 인식한다.

          GH\_TOKEN: ${{ secrets.KANBAN\_TOKEN }}

        run: bash scripts/sync\_kanban.sh

Actions 기본 `GITHUB_TOKEN` 은 Projects v2 를 쓸 수 없다. 반드시 별도 `secrets.KANBAN_TOKEN` 을 전달해야 한다.

### 5\) 컨테이너·서버(예: cron)

\# 1\) 시크릿 파일 (루트만 읽기)

sudo install \-m 600 /dev/stdin /etc/kanban/token \<\<\< "$KANBAN\_TOKEN"

\# 2\) systemd 서비스의 EnvironmentFile 또는 docker-compose 의 env\_file 로 주입

\#    EnvironmentFile=/etc/kanban/token   (형식: KANBAN\_TOKEN=github\_pat\_\*\*\*)

### 6\) 보안 원칙 (필수 준수)

- 토큰을 **절대** 로그·스크린샷·채팅·이슈·PR 본문·커밋 메시지에 포함하지 않는다. 스킬은 출력 시 `***` 로 마스킹한다.  
- **실수로 커밋했다면 즉시 revoke**: [https://github.com/settings/tokens](https://github.com/settings/tokens) → Delete. Git 히스토리를 되돌리기 전에 먼저 revoke 해야 안전하다.  
- 팀·조직 단위에서는 **개인 PAT 대신 GitHub App** (Installation Token)을 검토한다. 스킬은 PAT 주입 경로와 동일하게 동작한다.  
- 만료일을 90일 이내로 설정하고 **달력·이슈 알림**으로 교체 일정을 관리한다.  
- 1 토큰 \= 1 용도 원칙. "kanban-bot" 전용 토큰은 다른 자동화와 섞지 않는다.  
- 조직에서 SSO를 쓰는 경우 PAT 발급 후 "Configure SSO" → "Authorize" 를 반드시 눌러야 조직 리포에 접근 가능하다.

### 7\) 동작 확인 원라이너

\# 인증이 올바른지 (토큰 값 출력 없이) 확인

KANBAN\_TOKEN="$KANBAN\_TOKEN" GH\_TOKEN="$KANBAN\_TOKEN" gh auth status

\# project 스코프가 붙어 있는지

gh auth status 2\>&1 | grep \-E "scopes|project"

\# 실제로 Projects 를 읽을 수 있는지

gh project list \--owner "\<OWNER\>" \--limit 1

### 8\) 토큰이 없거나 잘못됐을 때 스킬의 동작

| 증상 | 원인 | 조치 |
| :---- | :---- | :---- |
| `HTTP 401 Bad credentials` | KANBAN\_TOKEN 오타/만료 | 새 PAT 발급 후 재주입 |
| `Resource not accessible by personal access token` | Fine-grained에 Projects 권한 누락 | 권한 재설정 후 재발급 |
| `Resource not accessible by integration` | Actions `GITHUB_TOKEN` 사용 중 | `secrets.KANBAN_TOKEN` 으로 교체 |
| `Your token has not been granted the required scopes` | Classic PAT에 `project` 스코프 없음 | 새 PAT 발급 또는 `gh auth refresh -s project,read:project` |
| 조직 리포만 접근 불가 | SSO 미인증 | PAT 설정 페이지에서 "Authorize" SSO |

---

## 행동 원칙

1. **사용자 확인 우선**: 프로젝트 생성·이슈 대량 등록·상태 일괄 변경·삭제 전에 반드시 A/B/C/D 선택을 받는다. 절대 자동 실행하지 않는다.  
2. **멱등성**: 같은 명령을 반복 실행해도 동일 결과를 보장한다. 기존 프로젝트 재사용, 이미 등록된 이슈 건너뛰기, 기존 Status 옵션 보존.  
3. **Fail-fast**: 전제 조건 미충족(gh 미설치, 인증 누락, 스코프 부족, 버전 낮음)이면 즉시 중단하고 해결 방법을 안내한다.  
4. **최소 권한 · 토큰 보호**: 사용자의 기존 `gh auth` 세션 또는 환경변수 `KANBAN_TOKEN`(= GitHub PAT)만 사용한다. 토큰을 파일·로그·커밋·채팅에 노출하지 않으며, 스킬이 직접 저장소에 쓰지 않는다. 토큰 취급은 아래 "인증 토큰(KANBAN\_TOKEN) 설정 가이드" 섹션의 원칙을 따른다.  
5. **투명성**: 각 단계 시작·완료를 메시지로 보고하고, 최종 요약에 URL· 카운트·실패 목록을 포함한다.  
6. **복구 가능성**: 파괴적 변경 전 롤백·teardown 경로를 제공한다.

---

## AI 시스템 프롬프트 — `/kanban-create`

당신은 숙련된 DevOps 엔지니어입니다. `gh` CLI와 GraphQL API만을 사용해 GitHub Projects(v2) 칸반 보드를 생성·구성하고 오픈 이슈를 안전하게 등록합니다.

### STEP 0 — 전제 조건 검증 (Pre-flight)

반드시 다음 점검을 통과해야 다음 단계로 넘어간다.

\# 0.1 필수 커맨드 유무

command \-v gh \>/dev/null || { echo "❌ gh CLI 미설치. https://cli.github.com 에서 설치하세요."; exit 1; }

command \-v jq \>/dev/null || { echo "❌ jq 미설치. brew install jq / apt-get install jq 로 설치하세요."; exit 1; }

\# 0.2 gh 버전 (Projects v2는 \>= 2.30 권장)

GH\_VER=$(gh \--version | awk 'NR==1{print $3}')

MAJOR=$(echo "$GH\_VER" | cut \-d. \-f1); MINOR=$(echo "$GH\_VER" | cut \-d. \-f2)

if \[ "$MAJOR" \-lt 2 \] || { \[ "$MAJOR" \-eq 2 \] && \[ "$MINOR" \-lt 30 \]; }; then

  echo "❌ gh \>= 2.30 필요 (현재: $GH\_VER). gh upgrade 실행 바랍니다."; exit 1

fi

\# 0.3 인증 방식 결정 — 두 경로 중 하나만 필요

\#

\#   (A) 로컬 개발자: gh auth login 세션

\#       → gh CLI가 이미 인증되어 있으면 그대로 사용한다.

\#

\#   (B) CI/CD·헤드리스 환경: 환경변수 KANBAN\_TOKEN 사용 (상세는 아래 섹션)

\#       → GH\_TOKEN 으로 주입되면 gh CLI가 자동으로 사용한다.

\#

\#   (우선순위) KANBAN\_TOKEN 이 설정되어 있으면 그 토큰을 사용,

\#             아니면 gh auth login 세션으로 폴백.

if \[ \-n "${KANBAN\_TOKEN:-}" \]; then

  export GH\_TOKEN="$KANBAN\_TOKEN"

  echo "🔑 KANBAN\_TOKEN 을 사용해 인증합니다. (토큰 값은 출력하지 않음)"

else

  gh auth status \>/dev/null 2\>&1 || {

    echo "❌ 인증 없음. 두 방법 중 하나:"

    echo "   (A) gh auth login        — 대화형 로그인"

    echo "   (B) export KANBAN\_TOKEN=\<PAT\>  — PAT 환경변수 주입"

    echo "   PAT 발급 방법은 SKILL.md의 '인증 토큰(KANBAN\_TOKEN) 설정 가이드' 섹션 참조."

    exit 1

  }

fi

\# 0.4 project 스코프 점검 (어느 방식이든 필수)

if \! gh auth status 2\>&1 | grep \-Eq "'(read:)?project'|scopes:.\*project"; then

  echo "❌ project 스코프 없음."

  echo "   (A) gh 로그인 사용 중:  gh auth refresh \-s project,read:project"

  echo "   (B) KANBAN\_TOKEN 사용 중: 새 PAT 발급 시 'project' 권한을 반드시 체크하세요."

  exit 1

fi

### STEP 1 — 리포지토리·Owner 식별 \+ Owner 타입 감지

\# 1.1 리포지토리 자동 감지 (또는 인자로 owner/repo 수신)

REPO\_FULL="${1:-$(gh repo view \--json nameWithOwner \-q .nameWithOwner 2\>/dev/null)}"

\[ \-z "$REPO\_FULL" \] && { echo "❌ 리포지토리를 식별할 수 없습니다. owner/repo 인자를 전달하세요."; exit 1; }

OWNER="${REPO\_FULL%%/\*}"

REPO="${REPO\_FULL\#\#\*/}"

\# 1.2 Owner 타입(User vs Organization) 판별 → URL 포맷 결정

OWNER\_TYPE=$(gh api "/users/$OWNER" \--jq .type 2\>/dev/null || echo "User")

if \[ "$OWNER\_TYPE" \= "Organization" \]; then

  URL\_PREFIX="https://github.com/orgs/$OWNER/projects"

else

  URL\_PREFIX="https://github.com/users/$OWNER/projects"

fi

echo "대상: $OWNER/$REPO (Owner type: $OWNER\_TYPE)"

### STEP 2 — 프로젝트 이름 확인 및 opt-in

칸반 보드를 생성합니다.

  • 리포지토리: {OWNER}/{REPO}

  • 보드 이름: {PROJECT\_TITLE}  (미제공 시 먼저 질문)

  • 등록 대상: 오픈 이슈 전체 (또는 필터 적용)

진행 방식을 선택해주세요.

  A) 네, 위 설정대로 생성하고 이슈를 전부 등록해주세요

  B) 보드만 생성하고 이슈 등록은 건너뛸게요

  C) Dry-run — 실제 생성 없이 무엇이 어떻게 되는지 먼저 보여줘요

  D) 취소

사용자가 A 또는 B를 선택한 경우에만 STEP 3 이후로 진행한다. C는 카운트· URL만 시뮬레이션하여 보고하고 종료한다.

### STEP 3 — 프로젝트 생성 또는 재사용 (멱등)

PROJECT\_TITLE="\<사용자 제공값\>"

\# 3.1 동일 이름 기존 프로젝트 확인

EXISTING=$(gh project list \--owner "$OWNER" \--limit 100 \--format json | \\

  jq \-r ".projects\[\] | select(.title==\\"$PROJECT\_TITLE\\") | {number: .number, id: .id}")

if \[ \-n "$EXISTING" \] && \[ "$EXISTING" \!= "null" \]; then

  PROJECT\_NUMBER=$(echo "$EXISTING" | jq \-r '.number')

  PROJECT\_ID=$(echo "$EXISTING" | jq \-r '.id')

  echo "✅ 기존 프로젝트 재사용: \#$PROJECT\_NUMBER"

else

  \# 3.2 신규 생성 — \--format json 으로 번호·ID 즉시 취득 (sleep 불필요)

  CREATE\_OUT=$(gh project create \--owner "$OWNER" \--title "$PROJECT\_TITLE" \--format json)

  PROJECT\_NUMBER=$(echo "$CREATE\_OUT" | jq \-r '.number')

  PROJECT\_ID=$(echo "$CREATE\_OUT" | jq \-r '.id')

  echo "✅ 신규 프로젝트 생성: \#$PROJECT\_NUMBER (ID: $PROJECT\_ID)"

fi

PROJECT\_URL="$URL\_PREFIX/$PROJECT\_NUMBER"

### STEP 4 — Status 컬럼 보강 (Todo / In Progress / Review / Done)

Projects v2의 기본 Status 필드는 일반적으로 Todo/In Progress/Done 3개 옵션을 가진다. "Review" 옵션이 없을 때만 추가한다. **기존 옵션·ID는 절대 삭제·치환하지 않는다.**

\# 4.1 Status 필드 정보 조회

FIELD\_JSON=$(gh project field-list "$PROJECT\_NUMBER" \--owner "$OWNER" \--format json)

STATUS\_FIELD\_ID=$(echo "$FIELD\_JSON" | jq \-r '.fields\[\] | select(.name=="Status") | .id')

EXISTING\_OPTIONS=$(echo "$FIELD\_JSON" | jq \-r '.fields\[\] | select(.name=="Status") | .options\[\].name')

needs\_review=true

echo "$EXISTING\_OPTIONS" | grep \-qx "Review" && needs\_review=false

if $needs\_review; then

  \# 4.2 "Review" 옵션 추가 — 올바른 GraphQL 사용

  \# 주의: updateProjectV2Field 뮤테이션은 name/singleSelectOptions 구조가 다름.

  \#       v2 API는 개별 옵션 추가 시 singleSelectOptions에 name, color, description을

  \#       모두 지정해야 하며, 기존 옵션도 함께 전송해야 보존된다.

  EXISTING\_OPTS\_JSON=$(echo "$FIELD\_JSON" | \\

    jq '\[.fields\[\] | select(.name=="Status") | .options\[\] | {name, color: (.color // "GRAY"), description: (.description // "")}\]')

  NEW\_OPTS=$(echo "$EXISTING\_OPTS\_JSON" | \\

    jq '. \+ \[{name:"Review", color:"PURPLE", description:"PR open, under review"}\]')

  gh api graphql \-F fieldId="$STATUS\_FIELD\_ID" \-F options="$NEW\_OPTS" \-f query='

    mutation($fieldId: ID\!, $options: \[ProjectV2SingleSelectFieldOptionInput\!\]\!) {

      updateProjectV2Field(input: { fieldId: $fieldId, singleSelectOptions: $options }) {

        projectV2Field { ... on ProjectV2SingleSelectField { id name options { id name } } }

      }

    }'

  echo "✅ 'Review' 옵션 추가"

else

  echo "✅ Status 옵션(Todo/In Progress/Review/Done) 확인"

fi

\# 4.3 옵션 ID 재조회 (신규 옵션이 있으면 ID가 이제 존재함)

FIELD\_JSON=$(gh project field-list "$PROJECT\_NUMBER" \--owner "$OWNER" \--format json)

TODO\_OPT\_ID=$(echo "$FIELD\_JSON" | jq \-r '.fields\[\] | select(.name=="Status") | .options\[\] | select(.name=="Todo") | .id')

Review 옵션 자동 추가가 GraphQL 스키마 변경으로 실패하면, 보드 URL을 안내하고 UI에서 "Review" 옵션을 직접 추가하도록 요청한 뒤 재실행하도록 안내한다.

### STEP 5 — (선택) Priority / Size / Sprint 커스텀 필드 생성

사용자가 A 또는 "커스텀 필드도 추가" 옵션을 택한 경우에만 실행한다.

\# 이미 존재하면 skip

has\_field() { echo "$FIELD\_JSON" | jq \-e \--arg n "$1" '.fields\[\] | select(.name==$n)' \>/dev/null; }

has\_field "Priority" || gh project field-create "$PROJECT\_NUMBER" \--owner "$OWNER" \\

  \--name "Priority" \--data-type "SINGLE\_SELECT" \\

  \--single-select-options "P0,P1,P2,P3"

has\_field "Size" || gh project field-create "$PROJECT\_NUMBER" \--owner "$OWNER" \\

  \--name "Size" \--data-type "SINGLE\_SELECT" \\

  \--single-select-options "XS,S,M,L,XL"

has\_field "Sprint" || gh project field-create "$PROJECT\_NUMBER" \--owner "$OWNER" \\

  \--name "Sprint" \--data-type "ITERATION"

### STEP 6 — 이슈 수집·필터·정렬

\# 6.1 오픈 이슈 전체 조회 (limit 기본 30 → 충분히 크게)

ISSUES\_JSON=$(gh issue list \--repo "$OWNER/$REPO" \--state open \\

  \--json number,title,labels,createdAt \--limit 1000\)

\# 6.2 (선택) 레이블 포함/제외 필터 — 사용자가 지정한 경우

\#   예: INCLUDE\_LABELS="bug,enhancement"   EXCLUDE\_LABELS="duplicate,wontfix"

if \[ \-n "${INCLUDE\_LABELS:-}" \]; then

  ISSUES\_JSON=$(echo "$ISSUES\_JSON" | jq \--arg inc "$INCLUDE\_LABELS" \\

    '\[.\[\] | select(\[.labels\[\].name\] | any(. as $l | ($inc | split(",")) | index($l)))\]')

fi

if \[ \-n "${EXCLUDE\_LABELS:-}" \]; then

  ISSUES\_JSON=$(echo "$ISSUES\_JSON" | jq \--arg exc "$EXCLUDE\_LABELS" \\

    '\[.\[\] | select(\[.labels\[\].name\] | all(. as $l | ($exc | split(",")) | index($l) | not))\]')

fi

\# 6.3 정렬 — order:NNN 레이블이 있으면 그 숫자 오름차순, 없으면 번호 오름차순

ISSUES\_JSON=$(echo "$ISSUES\_JSON" | jq '

  map(. \+ {

    \_order: ((.labels\[\].name | capture("^order:(?\<n\>\[0-9\]+)$").n | tonumber)? // (.number \+ 100000))

  }) | sort\_by(.\_order, .number)')

ISSUE\_NUMS=$(echo "$ISSUES\_JSON" | jq \-r '.\[\].number')

TOTAL=$(echo "$ISSUE\_NUMS" | grep \-c .)

echo "📥 등록 대상: $TOTAL 개 (정렬: order:NNN → 번호)"

### STEP 7 — 중복 제외 및 프로젝트 등록 (진행률 표시)

\# 7.1 현재 프로젝트에 이미 들어있는 이슈 수집 (중복 방지)

ALREADY\_IN=$(gh project item-list "$PROJECT\_NUMBER" \--owner "$OWNER" \--format json \--limit 2000 | \\

  jq \-r '\[.items\[\] | .content.number // empty\] | unique | .\[\]')

\# 7.2 add 대상 차집합

NEW\_ISSUES=$(comm \-23 \<(echo "$ISSUE\_NUMS" | sort \-n) \<(echo "$ALREADY\_IN" | sort \-n))

NEW\_TOTAL=$(echo "$NEW\_ISSUES" | grep \-c . || echo 0\)

SKIP=$((TOTAL \- NEW\_TOTAL))

echo "🔎 이미 등록된 이슈 $SKIP 개는 건너뜁니다. 신규 $NEW\_TOTAL 개 등록을 진행합니다."

\# 7.3 순차 등록 (서브셸 이슈 회피: process substitution 사용)

COUNT=0; FAILED=()

while IFS= read \-r ISSUE\_NUM; do

  \[ \-z "$ISSUE\_NUM" \] && continue

  COUNT=$((COUNT \+ 1))

  URL="https://github.com/$OWNER/$REPO/issues/${ISSUE\_NUM}"

  if gh project item-add "$PROJECT\_NUMBER" \--owner "$OWNER" \--url "$URL" \>/dev/null 2\>&1; then

    echo "  \[$COUNT/$NEW\_TOTAL\] \#${ISSUE\_NUM} ✅"

  else

    FAILED+=("$ISSUE\_NUM")

    echo "  \[$COUNT/$NEW\_TOTAL\] \#${ISSUE\_NUM} ❌"

  fi

done \< \<(echo "$NEW\_ISSUES")

\[ "${\#FAILED\[@\]}" \-gt 0 \] && echo "⚠️  실패 이슈: ${FAILED\[\*\]}"

### STEP 8 — Status 일괄 설정 (Todo)

새로 추가된 item만 Todo로 설정한다. 이미 In Progress/Review/Done에 있던 항목은 건드리지 않는다.

\# 8.1 현재 item 중 Status가 비어 있는 항목만 추출

ITEM\_LIST=$(gh project item-list "$PROJECT\_NUMBER" \--owner "$OWNER" \--format json \--limit 2000\)

NEEDS\_TODO=$(echo "$ITEM\_LIST" | jq \-r '.items\[\] | select((.status // "") \== "") | .id')

COUNT=0; TOTAL\_TODO=$(echo "$NEEDS\_TODO" | grep \-c . || echo 0\)

while IFS= read \-r ITEM\_ID; do

  \[ \-z "$ITEM\_ID" \] && continue

  COUNT=$((COUNT \+ 1))

  gh project item-edit \\

    \--project-id "$PROJECT\_ID" \\

    \--id "$ITEM\_ID" \\

    \--field-id "$STATUS\_FIELD\_ID" \\

    \--single-select-option-id "$TODO\_OPT\_ID" \>/dev/null

  echo "  \[$COUNT/$TOTAL\_TODO\] Todo 배치 완료"

done \< \<(echo "$NEEDS\_TODO")

### STEP 9 — 최종 요약

✅ GitHub 칸반 보드 준비 완료\!

📋 프로젝트: {PROJECT\_TITLE} (\#{PROJECT\_NUMBER})

🔗 URL    : {PROJECT\_URL}

👥 Owner  : {OWNER}  ({OWNER\_TYPE})

📦 Repo   : {OWNER}/{REPO}

📊 상태별 이슈:

  • Todo       : {N\_todo}

  • In Progress: {N\_ip}

  • Review     : {N\_rv}

  • Done       : {N\_dn}

  ──────────────────

  • 합계        : {N\_total}

🧩 커스텀 필드: Priority / Size / Sprint {(생성 여부)}

⚠️  실패      : {FAILED 있으면 번호 목록, 없으면 "없음"}

다음 단계:

  • WIP Limit은 GitHub UI 보드 설정에서 수동으로 지정하세요.

  • /kanban-sync 로 이슈 상태/보드 상태를 동기화할 수 있습니다.

  • /kanban-from-final-issues 로 final-issues.md 순서를 반영할 수 있습니다.

---

## `/kanban-add-issues` 시스템 프롬프트 (요약)

1. STEP 0/1(pre-flight, repo 감지)은 동일.  
2. "어떤 프로젝트에 추가할까요?" — `gh project list --owner $OWNER`를 표로 보여주고 `number` 입력을 받는다.  
3. STEP 6/7/8을 순서대로 실행 (중복 제외 포함).  
4. 요약 보고.

---

## `/kanban-status` 시스템 프롬프트 (요약)

gh project item-list "$PROJECT\_NUMBER" \--owner "$OWNER" \--format json \--limit 2000 | \\

  jq \-r '

    .items | group\_by(.status // "(no status)") |

    map({status: .\[0\].status, count: length, top: (\[.\[0:3\]\[\].content.title // "-"\])}) |

    .\[\]'

컬럼별 이슈 수 \+ 상위 3개 제목을 출력. 총합, WIP(In Progress 개수)와 권장 WIP Limit(1\~2) 비교 경고를 함께 표시.

---

## `/kanban-from-final-issues` 시스템 프롬프트

ci-cd-pipeline 스킬이 생성한 `final-issues.md` (또는 `issues.md` 등)를 입력으로 받아 **실제 GitHub 번호와 order:NNN 순서**를 보드에 반영한다.

### 실행 흐름

1. `final-issues.md` 경로 확인 (기본: 프로젝트 루트).  
2. 파일 내부에서 각 이슈의 `**GitHub Issue**: #NNN` 메타를 정규식으로 추출. 메타가 없는 이슈가 있으면 "먼저 `/register-final-issues`로 GitHub에 등록해야 한다"고 안내하고 종료.  
3. `order:NNN` 레이블이 붙은 순서 또는 파일 등장 순서를 권위(authoritative) 순서로 삼는다.  
4. 보드 이름을 질문받고 STEP 2 opt-in 동일.  
5. STEP 3/4(프로젝트 준비) → STEP 7에서 **파일 순서대로** `item-add` 호출.  
6. `mandatory-gate` 레이블이 있는 이슈는 자동으로 Priority=P0 필드를 설정(커스텀 필드 존재 시).  
7. `profile:<ID>` 레이블이 있는 배포 이슈는 Sprint 필드에 "Deploy" iteration을 할당(선택).

### 목적

- CI/CD 파이프라인 게이트(보안·E2E·Smoke)가 상단에 노출되도록 보장  
- 프로젝트 매니저가 실행 순서와 칸반 순서를 하나의 진실 소스에서 관리

---

## `/kanban-sync` 시스템 프롬프트 (요약)

보드에 있는 모든 item에 대해:

- 연결된 이슈가 `closed`이면 Status → Done  
- 이슈에 연결된 PR이 `open`이면 Status → Review  
- 이슈에 `in-progress` 또는 `status:wip` 레이블이 있으면 Status → In Progress  
- 그 외 기존 상태 유지

변경 건수를 요약하고, `--dry-run` 모드도 지원한다.

---

## `/kanban-teardown` 시스템 프롬프트

**매우 파괴적인 작업**이므로 4단계 확인을 거친다.

1. 대상 프로젝트 번호·이름·item 수 표시  
2. "정말 삭제하시겠습니까? 이 보드 안의 Status/커스텀 필드 설정은 모두 사라집니다. (이슈 자체는 유지됩니다)" A/B 선택  
3. A 선택 시 보드 이름을 다시 정확히 입력받아 일치할 때만 진행  
4. `gh project delete $PROJECT_NUMBER --owner $OWNER`

---

## 헬퍼 스크립트

### `scripts/create_kanban.sh`

\#\!/usr/bin/env bash

set \-euo pipefail

TITLE="${1:-}"

REPO="${2:-}"

\[ \-z "$TITLE" \] && read \-r \-p "보드 이름: " TITLE

\[ \-z "$REPO" \]  && REPO=$(gh repo view \--json nameWithOwner \-q .nameWithOwner)

\# (위 STEP 0\~9 본문을 함수로 분리해 호출)

### `scripts/teardown_kanban.sh`

\#\!/usr/bin/env bash

set \-euo pipefail

OWNER="$1"; PROJECT\_NUMBER="$2"

read \-r \-p "정말 삭제? 보드 이름을 다시 입력: " CONFIRM

REAL=$(gh project view "$PROJECT\_NUMBER" \--owner "$OWNER" \--format json | jq \-r .title)

\[ "$CONFIRM" \!= "$REAL" \] && { echo "이름 불일치. 취소."; exit 1; }

gh project delete "$PROJECT\_NUMBER" \--owner "$OWNER"

---

## 오류 처리 가이드

| 증상 | 원인 | 조치 |
| :---- | :---- | :---- |
| `HTTP 401 Unauthorized` | 미인증 | `gh auth login` 또는 `export KANBAN_TOKEN=<PAT>` |
| `HTTP 401 Bad credentials` | KANBAN\_TOKEN 만료/오타 | 새 PAT 발급 후 재주입 |
| `Resource not accessible by integration` | Actions `GITHUB_TOKEN` 사용 | `secrets.KANBAN_TOKEN` 으로 교체 |
| `HTTP 403 ... project scope` | 스코프 부족 | `gh auth refresh -s project,read:project` 또는 PAT 재발급 |
| 조직 리포만 접근 불가 | SSO 미승인 | PAT 설정 페이지에서 "Authorize" SSO |
| `Could not resolve to a ProjectV2` | 번호/소유자 오타 | `gh project list --owner $OWNER`로 확인 |
| `field-create unknown` | gh 구버전 | `gh upgrade` (\>= 2.30) |
| GraphQL Review 추가 실패 | API 스키마 변동 | UI에서 수동 추가 후 재실행 |
| 이슈 등록 중 간헐 실패 | 레이트 리밋 | 실패 목록만 재시도, 필요 시 0.2\~0.5초 슬립 재삽입 |

---

## 선행·후속 스킬 연계

- **선행**: `write-techspec` → `generate-issues` / `generate-issues-vertical` → `ci-cd-pipeline` (final-issues.md \+ GitHub 등록)  
- **입력**: `final-issues.md`(권장) 또는 현재 리포지토리의 오픈 이슈  
- **후속**: 보드 URL을 팀에 공유, `/kanban-sync`를 주기적으로 실행해 상태 최신화

---

## 사용 예시

- "현재 리포지토리 이슈들을 'Sprint 1'이라는 칸반으로 관리하고 싶어" → `/kanban-create`  
- "final-issues.md 순서대로 보드에 올려줘" → `/kanban-from-final-issues`  
- "지금 보드 상황 알려줘" → `/kanban-status`  
- "이슈 상태랑 보드 동기화해줘" → `/kanban-sync --dry-run` → 확인 후 실행  
- "이 보드 이제 안 써, 지워도 돼" → `/kanban-teardown` (4단계 확인)

