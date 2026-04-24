#!/usr/bin/env bash
# SDLC Skill Pack — PostToolUse hook
# gh issue create가 성공한 직후 생성된 이슈를 GitHub Projects(v2) 보드에 자동 추가한다.
#
# 동작 원칙:
#   - fail-open: 실패 시 이슈 생성 자체를 막지 않고, Claude에게 상황을 알리는 컨텍스트만 주입.
#   - 보드 정보는 (1) .sdlc/kanban.json → (2) KANBAN_PROJECT_NUMBER+KANBAN_OWNER 환경변수 순으로 탐색.
#   - 둘 다 없으면 Claude에게 /kanban-create 또는 /kanban-add-issues 안내를 내보낸다.

set -u -o pipefail

INPUT=$(cat)

emit() {
  # emit <additionalContext> [systemMessage]
  local ctx="$1"
  local sys="${2:-}"
  if [ -n "$sys" ]; then
    jq -n --arg ctx "$ctx" --arg sys "$sys" \
      '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$ctx},systemMessage:$sys}'
  else
    jq -n --arg ctx "$ctx" \
      '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$ctx}}'
  fi
  exit 0
}

# 1) tool_response 블롭 전체에서 이슈 URL을 찾는다 (내부 필드명에 의존하지 않기 위함).
RESP_BLOB=$(printf '%s' "$INPUT" | jq -r '.tool_response | tostring' 2>/dev/null || echo "")
ISSUE_URL=$(printf '%s' "$RESP_BLOB" \
  | grep -oE 'https://github\.com/[^[:space:]"/]+/[^[:space:]"/]+/issues/[0-9]+' \
  | head -1 || true)

if [ -z "${ISSUE_URL:-}" ]; then
  emit "gh issue create가 성공했으나 이슈 URL을 출력에서 찾지 못해 Projects 보드 자동 추가를 건너뜁니다. 필요하면 github-kanban-skill의 /kanban-add-issues 를 실행하세요."
fi

# 2) URL 파싱
OWNER=$(printf '%s' "$ISSUE_URL" | sed -E 's|https://github\.com/([^/]+)/([^/]+)/issues/([0-9]+)|\1|')
REPO=$(printf '%s'  "$ISSUE_URL" | sed -E 's|https://github\.com/([^/]+)/([^/]+)/issues/([0-9]+)|\2|')
NUMBER=$(printf '%s' "$ISSUE_URL" | sed -E 's|https://github\.com/([^/]+)/([^/]+)/issues/([0-9]+)|\3|')

# 3) 보드 정보 조회 — .sdlc/kanban.json 우선
PROJECT_NUMBER=""
PROJECT_OWNER=""

for CANDIDATE in ".sdlc/kanban.json" ".claude/kanban.json"; do
  if [ -f "$CANDIDATE" ]; then
    PROJECT_NUMBER=$(jq -r '.projectNumber // empty' "$CANDIDATE" 2>/dev/null || echo "")
    PROJECT_OWNER=$(jq  -r '.owner // empty'         "$CANDIDATE" 2>/dev/null || echo "")
    if [ -n "$PROJECT_NUMBER" ] && [ -n "$PROJECT_OWNER" ]; then
      break
    fi
  fi
done

# 4) 환경변수 fallback
if [ -z "$PROJECT_NUMBER" ] || [ -z "$PROJECT_OWNER" ]; then
  if [ -n "${KANBAN_PROJECT_NUMBER:-}" ] && [ -n "${KANBAN_OWNER:-}" ]; then
    PROJECT_NUMBER="$KANBAN_PROJECT_NUMBER"
    PROJECT_OWNER="$KANBAN_OWNER"
  fi
fi

# 5) 보드 정보가 아예 없음 → Claude에게 위임
if [ -z "$PROJECT_NUMBER" ] || [ -z "$PROJECT_OWNER" ]; then
  emit "✅ 새 이슈 ${ISSUE_URL} 가 생성되었습니다. 다만 칸반 보드 정보(.sdlc/kanban.json 또는 KANBAN_PROJECT_NUMBER/KANBAN_OWNER 환경변수)가 없어 Projects v2 보드에 자동 추가하지 못했습니다. 아직 보드가 없다면 github-kanban-skill로 /kanban-create 를 실행하고, 이미 있다면 /kanban-add-issues 로 방금 생성된 이슈 #${NUMBER} (${OWNER}/${REPO}) 를 추가하세요. 한 번 보드를 만들면 이후부터는 자동 추가됩니다."
fi

# 6) KANBAN_TOKEN 우선 사용 (헤드리스/CI 호환)
if [ -n "${KANBAN_TOKEN:-}" ]; then
  export GH_TOKEN="$KANBAN_TOKEN"
fi

# 7) gh 존재 여부
if ! command -v gh >/dev/null 2>&1; then
  emit "새 이슈 ${ISSUE_URL} 가 생성되었으나 gh CLI가 설치되어 있지 않아 보드 자동 추가를 수행할 수 없습니다."
fi

# 8) 실제 보드 추가 — 실패해도 이슈 생성은 이미 끝났으므로 경고만.
if ADD_OUT=$(gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --url "$ISSUE_URL" 2>&1); then
  emit "✅ 새 이슈 #${NUMBER} (${OWNER}/${REPO}) 가 Projects v2 보드 ${PROJECT_OWNER} #${PROJECT_NUMBER} 에 자동 추가되었습니다 → ${ISSUE_URL}" \
       "🔷 SDLC: 이슈 #${NUMBER} 를 칸반 보드에 자동 추가함"
else
  emit "⚠️ 새 이슈 ${ISSUE_URL} 는 생성되었지만 Projects 보드(${PROJECT_OWNER} #${PROJECT_NUMBER}) 추가에 실패했습니다. gh 출력: ${ADD_OUT}. 수동으로 /kanban-add-issues 를 실행하거나 gh auth status / KANBAN_TOKEN 의 project 스코프를 확인하세요."
fi
