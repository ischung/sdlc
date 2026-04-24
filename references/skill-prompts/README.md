# Skill 생성 프롬프트 모음

이 폴더에는 `sdlc/skills/` 아래의 **9개 SKILL.md 파일**을 다시 생성하기 위한 **프롬프트** 가 들어 있습니다. 각 프롬프트는 LLM(Claude 등)에게 그대로 전달하면 해당 스킬의 SKILL.md 한 개 파일이 산출되도록 설계되었습니다.

## 파일 목록

| # | 프롬프트 | 생성 대상 SKILL.md |
| :- | :--- | :--- |
| 1 | `write-prd.prompt.md` | `skills/write-prd/SKILL.md` (PRD 작성, v2.2) |
| 2 | `write-techspec.prompt.md` | `skills/write-techspec/SKILL.md` (TechSpec 작성, v1.0) |
| 3 | `generate-issues-vertical.prompt.md` | `skills/generate-issues-vertical/SKILL.md` (v3.0, Walking Skeleton + Vertical Slice + CI/CD-first) |
| 4 | `generate-issues-layered.prompt.md` | `skills/generate-issues-layered/SKILL.md` (v3.0, Architecture Layer + CI/CD-first) |
| 5 | `ci-cd-pipeline.prompt.md` | `skills/ci-cd-pipeline/SKILL.md` (v1.1, CI/CD 파이프라인 실제 구현) |
| 6 | `github-kanban-skill.prompt.md` | `skills/github-kanban-skill/SKILL.md` (v2.0, GitHub Projects v2 칸반 자동화) |
| 7 | `append-issue.prompt.md` | `skills/append-issue/SKILL.md` (v1.0, 런타임 이슈 append) |
| 8 | `implement-top-issue.prompt.md` | `skills/implement-top-issue/SKILL.md` (v1.4, 우선순위 이슈 픽업·구현·PR) |
| 9 | `register-issues-to-github.prompt.md` | `skills/register-issues-to-github/SKILL.md` (v1.1, 파일 → GitHub Issues → 칸반 보드) |

## SDLC 파이프라인에서의 위치

```
[기획]                  [설계]                 [이슈 분할]                            [등록·보드]                       [구현]
write-prd  ──►  write-techspec  ──►  generate-issues-vertical   ──►  register-issues-to-github  ──►  implement-top-issue
                                  or generate-issues-layered          (STEP 9: github-kanban 호출)        (CI/CD 이슈는 ci-cd-pipeline 위임)
                                  +  ci-cd-pipeline (CI/CD 실구현)
                                                                                                          ▲
[런타임 신규]                                                                                              │
append-issue  ─────────────────────────────────────────────────────────────────────────────────────────────┘
```

## 사용법

### A) 단일 스킬 재생성
1. 필요한 프롬프트 파일을 통째로 복사한다 (예: `write-prd.prompt.md`).
2. Claude에게 "다음 프롬프트의 지시를 따라 SKILL.md를 생성해줘"라고 붙여 전달.
3. 결과를 `sdlc/skills/<skill-name>/SKILL.md`에 저장한다.

### B) 일괄 재생성 / 마이그레이션
- 9개 프롬프트를 순차적으로 처리.
- 각 프롬프트 끝의 **검증** 체크리스트로 산출물을 점검(트리거 키워드 누락, 누락된 STEP, 표 행 수 등).

### C) 스킬 신규 작성 시 템플릿으로 활용
- 9개 프롬프트의 **공통 패턴**을 따르면 일관된 스킬 작성이 가능:
  1. Frontmatter (`name`, `description` — 트리거 키워드 한국어 명시 포함)
  2. 슬래시 커맨드 표
  3. 행동 원칙(번호 매김)
  4. AI 시스템 프롬프트 (역할 부여, 한 단락)
  5. STEP 0 ~ STEP N 워크플로우 (Pre-flight → 입력 → 실행 → 저장 → 보고)
  6. 안전장치(Safety Guards)
  7. 실패/예외 처리 표
  8. 다른 스킬과의 관계 (ASCII 다이어그램 + 표)
  9. 사용 예시
  10. Changelog

## 일관성 규칙 (모든 스킬 공통)

- **언어**: 한국어 본문 + bash/jq/markdown 코드블록.
- **opt-in 원칙**: 파괴적 작업(파일 쓰기, GitHub API 쓰기, 보드 변경) 직전에는 반드시 A/B/C/D 사용자 선택 받기.
- **이슈 우선(Ticket-first)**: 구현 스킬은 `**GitHub Issue**: #N` 메타가 있는 이슈만 픽업. 메타 없으면 `append-issue` → `register-issues-to-github` 안내 후 종료.
- **레이블 체계**: `priority:p0~p3`, `mandatory-gate`, `order:NNN`, `profile:staging|prod`, `strategy:layered|vertical-slice|cicd`. 후속 스킬은 이 레이블을 소비.
- **CI/CD-first**: 이슈 분할 스킬(vertical/layered)은 CI 부트스트랩 → CD 스테이징 → 기능 슬라이스/계층 순서를 강제.
- **단일 책임**: 이슈 생성 / 등록 / 보드 / 구현 / CI·CD 구현 / 머지·릴리스가 각기 다른 스킬로 분리. 순환 호출 금지(특히 `ci-cd-pipeline ↛ implement-top-issue`).

## 참고

- 원본 SKILL.md: `sdlc/skills/<skill-name>/SKILL.md`
- 관련 템플릿/문서: `sdlc/references/`의 `prd-template.md`, `techspec-template.md`, `frontend-design.md`, `issue-splitting-comparison.md`
