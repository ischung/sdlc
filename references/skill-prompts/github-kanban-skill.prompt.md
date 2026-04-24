# Prompt — `github-kanban-skill` SKILL.md 생성 요청

## 역할
당신은 Claude 스킬 작성자입니다. **`github-kanban-skill` SKILL.md (v2.0)** 한 개 파일을 만드세요. GitHub Projects v2 칸반 보드를 `gh` CLI로 자동 생성·구성하고 이슈를 안전하게 등록하는 스킬입니다.

## 산출물 요구사항

### Frontmatter
- `name`: `github-kanban-skill`
- `description`: GitHub Projects(v2) 기반 칸반 보드를 `gh` CLI로 자동 생성·구성하고, 현재 리포지토리(또는 사용자 지정)의 이슈를 정렬 규칙에 따라 Todo 컬럼에 일괄 등록. **Todo / In Progress / Review / Done 4단계** Status 컬럼 보장, 선택적으로 Priority/Size/Sprint 커스텀 필드 추가. 파괴적 작업 전 사용자 opt-in(A/B/C/D), 기존 프로젝트/이슈 재사용·중복 방지로 안전하게 재실행. ci-cd-pipeline의 `final-issues.md`와 연계해 `order:NNN`/`mandatory-gate`/`profile:` 레이블 인식하여 실행 순서대로 배치. 트리거: "칸반 보드 만들어줘", "GitHub 프로젝트 생성", "이슈 관리 보드", "프로젝트 보드 설정", "gh project", "이슈를 칸반에 등록", "티켓 보드", "스프린트 보드", "애자일 보드", "/kanban-create", "/kanban-add-issues", "/kanban-status", "/kanban-from-final-issues", "/kanban-sync", "/kanban-teardown", "final-issues 보드에 올려줘", "KANBAN_TOKEN", "PAT 설정", "GitHub Actions 프로젝트 토큰", "gh 인증". CI/CD·헤드리스 환경에서는 PAT를 `KANBAN_TOKEN`로 주입 안내. 프로젝트 이름 미제공 시 먼저 묻기.

### 본문 구조

1. 제목: `# GitHub Kanban 자동화 스킬 v2.0` + 한 단락 설명(숙련된 DevOps·PM 엔지니어 역할, `gh` CLI + GraphQL, opt-in 전제).
2. **슬래시 커맨드 표** 6개: `/kanban-create`, `/kanban-add-issues`, `/kanban-status`, `/kanban-from-final-issues`, `/kanban-sync`, `/kanban-teardown`. 커맨드 파일은 `.claude/commands/` 또는 `~/.claude/commands/`에 둔다는 안내.
3. **인증 토큰(KANBAN_TOKEN) 설정 가이드** (8개 하위 섹션):
   1. 어떤 토큰을 만들어야 하나 — Fine-grained PAT(권장) vs Classic PAT 표 + 최소권한(Issues R/W, Metadata R, Projects R/W, 만료 30~90일).
   2. 토큰 발급 절차(Fine-grained) 6단계.
   3. 로컬 셸 주입(`read -rs KANBAN_TOKEN && export KANBAN_TOKEN` 일회성 / `~/.zshrc` 영구 + `chmod 600` / `.env`·`.envrc`는 `.gitignore` 필수).
   4. GitHub Actions 사용 — `GH_TOKEN: ${{ secrets.KANBAN_TOKEN }}` 워크플로 예시. 기본 `GITHUB_TOKEN`은 Projects v2 권한 없음 강조.
   5. 컨테이너·서버(systemd EnvironmentFile / docker-compose env_file).
   6. 보안 원칙 6가지(로그·커밋·채팅 노출 금지, 실수 커밋 시 즉시 revoke, 팀 단위 GitHub App 검토, 만료 90일 이내, 1 토큰 1 용도, SSO 조직은 "Configure SSO → Authorize").
   7. 동작 확인 원라이너 3개(`gh auth status`, scopes grep, `gh project list`).
   8. 토큰 오류 표(401 Bad credentials, Resource not accessible by personal access token, by integration, project 스코프 누락, SSO 미인증).
4. **행동 원칙 6개**: 사용자 확인 우선, 멱등성, Fail-fast, 최소 권한·토큰 보호, 투명성, 복구 가능성.
5. **AI 시스템 프롬프트 — `/kanban-create`** 한 단락.
6. **STEP 0 — Pre-flight**(bash):
   - 0.1 `gh`/`jq` 미설치 확인
   - 0.2 gh ≥ 2.30 버전 검사
   - 0.3 인증 방식 결정 — (A) `gh auth login` (B) `KANBAN_TOKEN` → `GH_TOKEN` 승격. 우선순위 KANBAN_TOKEN.
   - 0.4 project 스코프 점검(`gh auth refresh -s project,read:project` 또는 새 PAT)
7. **STEP 1 — 리포·Owner 식별 + Owner 타입 감지**(bash) — User vs Organization, URL_PREFIX 결정.
8. **STEP 2 — 프로젝트 이름 확인 + opt-in** — A/B/C/D 선택지 (전부 생성 / 보드만 / Dry-run / 취소).
9. **STEP 3 — 프로젝트 생성 또는 재사용(멱등)** — 기존 프로젝트 확인 → 없으면 `gh project create --format json`로 번호·ID 즉시 취득.
10. **STEP 4 — Status 컬럼 보강** — 기본 Todo/In Progress/Done에 "Review" 옵션이 없을 때만 추가. 기존 옵션·ID 보존. GraphQL `updateProjectV2Field` 호출 예시. 실패 시 UI 수동 추가 안내.
11. **STEP 5 — (선택) Priority/Size/Sprint 커스텀 필드 생성** — `gh project field-create`로 SINGLE_SELECT (P0~P3, XS~XL) + ITERATION.
12. **STEP 6 — 이슈 수집·필터·정렬** — `gh issue list --limit 1000`, `INCLUDE_LABELS`/`EXCLUDE_LABELS`, `order:NNN` 캡처해 정렬 + 번호 폴백.
13. **STEP 7 — 중복 제외 + 등록(진행률)** — `comm -23` 차집합, `gh project item-add` 순차 등록, 실패 누적.
14. **STEP 8 — Status 일괄 설정(Todo)** — Status가 비어있는 신규 item만 Todo 옵션 ID로 설정(`gh project item-edit`).
15. **STEP 9 — 최종 요약** — 프로젝트/URL/Owner/Repo/상태별 이슈 수/커스텀 필드/실패/다음 단계 안내(WIP Limit UI 수동, kanban-sync, kanban-from-final-issues).
16. **`/kanban-add-issues` 시스템 프롬프트(요약)** — pre-flight 동일, 프로젝트 선택, STEP 6~8 실행.
17. **`/kanban-status` 시스템 프롬프트(요약)** — `gh project item-list` + jq 그룹화. 컬럼별 이슈 수 + 상위 3개 제목 + 총합 + WIP Limit 경고.
18. **`/kanban-from-final-issues` 시스템 프롬프트** — final-issues.md 입력. `**GitHub Issue**: #NNN` 메타 추출, 메타 부재 시 `register-final-issues` 안내. order:NNN 또는 파일 등장 순서를 권위로. STEP 2 opt-in → STEP 3/4 → STEP 7에서 파일 순서대로 item-add. mandatory-gate → Priority=P0 자동 설정. profile:* 레이블 → Sprint=Deploy.
19. **`/kanban-sync` 시스템 프롬프트(요약)** — closed → Done, PR open → Review, in-progress 레이블 → In Progress, 그 외 유지. 변경 건수 요약 + `--dry-run`.
20. **`/kanban-teardown` 시스템 프롬프트** — 4단계 확인(대상 표시 → opt-in A/B → 보드 이름 정확히 다시 입력 → `gh project delete`).
21. **헬퍼 스크립트** — `scripts/create_kanban.sh`, `scripts/teardown_kanban.sh` 골격.
22. **오류 처리 가이드** 표(401 Unauthorized, 401 Bad credentials, integration 권한 부족, 403 project scope 부족, SSO 미승인, ProjectV2 미해소, gh 구버전 field-create unknown, Review 추가 실패, 레이트 리밋).
23. **선행·후속 스킬 연계** — write-techspec → generate-issues-* → ci-cd-pipeline → final-issues.md → 본 스킬 → kanban-sync.
24. **사용 예시** 5건.

## 톤 / 스타일
- 한국어 + bash 코드블록.
- gh 명령은 실제로 동작하는 형태(예: `gh project list --owner $OWNER --format json`).

## 검증
- 트리거 키워드(15개 이상) 모두 포함?
- 6개 슬래시 커맨드 모두 정의?
- KANBAN_TOKEN 가이드 8개 하위 섹션 모두 있음?
- STEP 0~9 + 보조 커맨드 5개의 시스템 프롬프트 모두 있음?
- Review 옵션 추가 GraphQL 예시 있음?
- 오류 처리 표에 SSO 미승인, GITHUB_TOKEN integration 권한 부족이 포함?
