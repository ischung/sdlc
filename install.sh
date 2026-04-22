#!/usr/bin/env bash
# SDLC Skill Pack — 설치 스크립트
# 사용법: ./install.sh [--global] [--all] [--skill <name>] [--yes]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$SCRIPT_DIR/skills"

# ── 색상 ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}ℹ ${RESET}$*"; }
success() { echo -e "${GREEN}✓ ${RESET}$*"; }
warn()    { echo -e "${YELLOW}⚠ ${RESET}$*"; }
error()   { echo -e "${RED}✗ ${RESET}$*" >&2; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

# ── 스킬 목록 자동 검색 (파일로 반환) ────────────────────
SKILLS_CACHE=""
discover_skills() {
  if [[ -z "$SKILLS_CACHE" ]]; then
    if [[ ! -d "$SKILLS_ROOT" ]]; then
      SKILLS_CACHE=""
      return
    fi
    SKILLS_CACHE="$(find "$SKILLS_ROOT" -maxdepth 2 -name "SKILL.md" \
      | sed "s|/SKILL.md||" \
      | while IFS= read -r p; do basename "$p"; done \
      | sort)"
  fi
  echo "$SKILLS_CACHE"
}

# ── SKILL.md에서 description 첫 줄 추출 ─────────────────
skill_description() {
  local skill_dir="$SKILLS_ROOT/$1"
  grep -A2 '^description:' "$skill_dir/SKILL.md" 2>/dev/null \
    | tail -1 | sed 's/^[[:space:]]*//' | cut -c1-60 || echo "(설명 없음)"
}

# ── 인자 파싱 ────────────────────────────────────────────
OPT_GLOBAL=false
OPT_ALL=false
OPT_YES=false
OPT_SKILL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --global)   OPT_GLOBAL=true ;;
    --all)      OPT_ALL=true ;;
    --yes|-y)   OPT_YES=true ;;
    --skill)    OPT_SKILL="$2"; shift ;;
    --help|-h)
      cat <<EOF
사용법: ./install.sh [옵션]

옵션:
  --global          전역 설치 (~/.claude/skills/)
  --all             모든 스킬 설치
  --skill <name>    특정 스킬만 설치
  --yes, -y         확인 없이 자동 설치
  --help, -h        이 도움말 출력
EOF
      exit 0 ;;
    *) error "알 수 없는 옵션: $1"; exit 1 ;;
  esac
  shift
done

# ── 대상 디렉토리 결정 ───────────────────────────────────
resolve_target_dir() {
  if $OPT_GLOBAL; then
    echo "$HOME/.claude/skills"
    return
  fi
  local cwd
  cwd="$(pwd)"
  while [[ "$cwd" != "/" ]]; do
    if [[ -d "$cwd/.claude" || -f "$cwd/CLAUDE.md" || -d "$cwd/.git" ]]; then
      echo "$cwd/.claude/skills"
      return
    fi
    cwd="$(dirname "$cwd")"
  done
  echo "$(pwd)/.claude/skills"
}

# ── 대화형 선택: 선택 결과를 전역 변수 SELECTED_SKILLS에 저장 ──
SELECTED_SKILLS=""

select_skills_interactive() {
  local available
  available="$(discover_skills)"

  if [[ -z "$available" ]]; then
    error "설치 가능한 스킬을 찾을 수 없습니다."
    exit 1
  fi

  header "사용 가능한 스킬 목록"
  local i=1
  while IFS= read -r skill; do
    local desc
    desc="$(skill_description "$skill")"
    printf "  ${CYAN}%2d)${RESET} %-35s %s\n" "$i" "$skill" "$desc"
    i=$((i+1))
  done <<< "$available"
  echo ""
  echo -e "  ${CYAN} a)${RESET} 모든 스킬 설치"
  echo -e "  ${CYAN} q)${RESET} 취소"
  echo ""

  local input
  read -rp "설치할 스킬 번호를 입력하세요 (공백으로 구분, 예: 1 3 5): " input

  case "$input" in
    q) info "설치를 취소했습니다."; exit 0 ;;
    a) SELECTED_SKILLS="$available"; return ;;
  esac

  local count
  count="$(echo "$available" | wc -l | tr -d ' ')"
  local chosen=""
  for num in $input; do
    if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= count )); then
      local picked
      picked="$(echo "$available" | sed -n "${num}p")"
      chosen="${chosen}${picked}"$'\n'
    else
      warn "유효하지 않은 번호: $num (무시됨)"
    fi
  done
  SELECTED_SKILLS="$(echo "$chosen" | sed '/^$/d')"
}

# ── 단일 스킬 설치 ───────────────────────────────────────
install_skill() {
  local skill_name="$1"
  local target_dir="$2"
  local src="$SKILLS_ROOT/$skill_name"
  local dst="$target_dir/$skill_name"

  if [[ ! -f "$src/SKILL.md" ]]; then
    error "스킬을 찾을 수 없습니다: $skill_name"
    return 1
  fi

  mkdir -p "$dst"

  if [[ -f "$dst/SKILL.md" ]]; then
    warn "$skill_name 이미 설치되어 있습니다. 덮어씁니다..."
  fi

  cp -r "$src/." "$dst/"
  success "$skill_name → $dst"
}

# ── 메인 ────────────────────────────────────────────────
main() {
  header "SDLC Skill Pack 설치 관리자"
  echo ""

  # 설치 스코프 결정
  if ! $OPT_GLOBAL && ! $OPT_YES; then
    echo "설치 위치를 선택하세요:"
    echo "  1) 프로젝트 레벨 (.claude/skills/) — 현재 프로젝트에서만 사용"
    echo "  2) 전역 (~/.claude/skills/)         — 모든 프로젝트에서 사용"
    echo ""
    local scope_input
    read -rp "선택 [1/2]: " scope_input
    [[ "$scope_input" == "2" ]] && OPT_GLOBAL=true
  fi

  local target_dir
  target_dir="$(resolve_target_dir)"

  # 설치할 스킬 목록 결정
  if [[ -n "$OPT_SKILL" ]]; then
    SELECTED_SKILLS="$OPT_SKILL"
  elif $OPT_ALL; then
    SELECTED_SKILLS="$(discover_skills)"
  else
    select_skills_interactive
  fi

  if [[ -z "$SELECTED_SKILLS" ]]; then
    warn "선택된 스킬이 없습니다."
    exit 0
  fi

  # 확인
  echo ""
  info "설치 위치: ${BOLD}$target_dir${RESET}"
  info "설치할 스킬:"
  while IFS= read -r s; do
    echo "    - $s"
  done <<< "$SELECTED_SKILLS"
  echo ""

  if ! $OPT_YES; then
    local confirm
    read -rp "계속 진행하시겠습니까? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { info "취소되었습니다."; exit 0; }
  fi

  # 설치 실행
  echo ""
  local failed=0
  local total=0
  while IFS= read -r skill; do
    total=$((total+1))
    install_skill "$skill" "$target_dir" || failed=$((failed+1))
  done <<< "$SELECTED_SKILLS"

  echo ""
  if [[ $failed -eq 0 ]]; then
    success "${total}개 스킬 설치 완료!"
    echo ""
    info "Claude Code를 재시작하거나 새 세션을 열면 스킬이 활성화됩니다."
  else
    error "${failed}개 스킬 설치 실패. 위 오류 메시지를 확인하세요."
    exit 1
  fi
}

main "$@"
