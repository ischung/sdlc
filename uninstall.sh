#!/usr/bin/env bash
# SDLC Skill Pack — 제거 스크립트
# 사용법: ./uninstall.sh [--global] [--all] [--skill <name>] [--yes]

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

# ── 이 팩에 포함된 스킬 이름 목록 ───────────────────────
pack_skills() {
  [[ -d "$SKILLS_ROOT" ]] || return 0
  find "$SKILLS_ROOT" -maxdepth 2 -name "SKILL.md" \
    | sed "s|/SKILL.md||" \
    | while IFS= read -r p; do basename "$p"; done \
    | sort
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
사용법: ./uninstall.sh [옵션]

옵션:
  --global          전역 제거 (~/.claude/skills/)
  --all             모든 스킬 제거
  --skill <name>    특정 스킬만 제거
  --yes, -y         확인 없이 자동 제거
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

# ── 설치된 스킬 중 이 팩에 속한 것만 탐색 ───────────────
find_installed() {
  local target_dir="$1"
  while IFS= read -r skill; do
    [[ -f "$target_dir/$skill/SKILL.md" ]] && echo "$skill"
  done < <(pack_skills)
}

# ── 대화형 선택: 결과를 전역 변수 SELECTED_SKILLS에 저장 ─
SELECTED_SKILLS=""

select_skills_interactive() {
  local target_dir="$1"
  local installed
  installed="$(find_installed "$target_dir")"

  if [[ -z "$installed" ]]; then
    warn "제거할 설치된 스킬이 없습니다. (위치: $target_dir)"
    exit 0
  fi

  header "설치된 스킬 목록"
  local i=1
  while IFS= read -r skill; do
    printf "  ${CYAN}%2d)${RESET} %s\n" "$i" "$skill"
    i=$((i+1))
  done <<< "$installed"
  echo ""
  echo -e "  ${CYAN} a)${RESET} 모든 스킬 제거"
  echo -e "  ${CYAN} q)${RESET} 취소"
  echo ""

  local input
  read -rp "제거할 스킬 번호를 입력하세요 (공백으로 구분): " input

  case "$input" in
    q) info "제거를 취소했습니다."; exit 0 ;;
    a) SELECTED_SKILLS="$installed"; return ;;
  esac

  local count
  count="$(echo "$installed" | wc -l | tr -d ' ')"
  local chosen=""
  for num in $input; do
    if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= count )); then
      local picked
      picked="$(echo "$installed" | sed -n "${num}p")"
      chosen="${chosen}${picked}"$'\n'
    else
      warn "유효하지 않은 번호: $num (무시됨)"
    fi
  done
  SELECTED_SKILLS="$(echo "$chosen" | sed '/^$/d')"
}

# ── 단일 스킬 제거 ───────────────────────────────────────
remove_skill() {
  local skill_name="$1"
  local target_dir="$2"
  local dst="$target_dir/$skill_name"

  if [[ ! -d "$dst" ]]; then
    warn "$skill_name 는 설치되어 있지 않습니다. (건너뜀)"
    return 0
  fi

  rm -rf "$dst"
  success "$skill_name 제거 완료 ($dst)"
}

# ── 메인 ────────────────────────────────────────────────
main() {
  header "SDLC Skill Pack 제거 관리자"
  echo ""

  # 제거 스코프 결정
  if ! $OPT_GLOBAL && ! $OPT_YES; then
    echo "제거 위치를 선택하세요:"
    echo "  1) 프로젝트 레벨 (.claude/skills/)"
    echo "  2) 전역 (~/.claude/skills/)"
    echo ""
    local scope_input
    read -rp "선택 [1/2]: " scope_input
    [[ "$scope_input" == "2" ]] && OPT_GLOBAL=true
  fi

  local target_dir
  target_dir="$(resolve_target_dir)"

  # 제거할 스킬 목록 결정
  if [[ -n "$OPT_SKILL" ]]; then
    SELECTED_SKILLS="$OPT_SKILL"
  elif $OPT_ALL; then
    SELECTED_SKILLS="$(find_installed "$target_dir")"
    if [[ -z "$SELECTED_SKILLS" ]]; then
      warn "제거할 스킬이 없습니다."; exit 0
    fi
  else
    select_skills_interactive "$target_dir"
  fi

  if [[ -z "$SELECTED_SKILLS" ]]; then
    warn "선택된 스킬이 없습니다."; exit 0
  fi

  # 확인
  echo ""
  warn "제거 위치: ${BOLD}$target_dir${RESET}"
  warn "제거할 스킬:"
  while IFS= read -r s; do
    echo "    - $s"
  done <<< "$SELECTED_SKILLS"
  echo ""

  if ! $OPT_YES; then
    local confirm
    read -rp "정말 제거하시겠습니까? 이 작업은 되돌릴 수 없습니다. [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { info "취소되었습니다."; exit 0; }
  fi

  # 제거 실행
  echo ""
  while IFS= read -r skill; do
    remove_skill "$skill" "$target_dir"
  done <<< "$SELECTED_SKILLS"

  echo ""
  success "제거 완료!"
}

main "$@"
