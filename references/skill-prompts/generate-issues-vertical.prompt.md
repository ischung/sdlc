# Prompt — `generate-issues-vertical` SKILL.md 생성 요청

## 역할
당신은 Claude 스킬 작성자입니다. **`generate-issues-vertical` 스킬의 SKILL.md (v3.0)** 한 개 파일을 만드세요. 출력은 SKILL.md 본문 그대로(코드 블록 감싸기 금지), frontmatter는 파일 맨 위.

## 산출물 요구사항

### Frontmatter
- `name`: `generate-issues-vertical`
- `description`(여러 줄, 한 단락): TechSpec을 **Walking Skeleton + Vertical Slice + CI/CD-first** 전략으로 분할해 `issues-vertical.md`에 저장하는 스킬(v3.0). 어떤 기능 이슈보다도 먼저 CI 부트스트랩(lint/test) → CD 스테이징 → Walking Skeleton → 수직 슬라이스 순서. 모든 후속 이슈가 "초록불 파이프라인 위에서 굴러가는" 상태를 가장 빨리 만든다는 가치 명시. 각 이슈는 `**Depends on**: #N`으로 명시적 의존성을 가지며, 파일 상단에 위상 정렬(topological order) + 의존성 그래프 포함. INVEST 6요건 충족, 각 슬라이스는 UI+API+DB+테스트+배포까지 End-to-End. **GitHub 등록은 수행하지 않음** — 후속 `register-issues-to-github`에 위임. 보드 배치는 `github-kanban`, 구현은 `implement-top-issue`. 공통 레이블 체계(`priority:p0~p3`, `mandatory-gate`, `order:NNN`, `profile:staging/prod`, `strategy:vertical-slice`) 준수. 트리거: "수직 분할", "수직 슬라이스", "버티컬 슬라이스", "vertical slice", "Walking Skeleton", "워킹 스켈레톤", "MVP 방식 이슈", "유저 스토리 단위 이슈", "CI/CD 먼저 만드는 이슈", "파이프라인부터 이슈", "/generate-issues-vertical", "/vertical-issues". 형제 스킬 `generate-issues-layered`(계층별 분할)도 안내, 모호하면 두 전략을 2~3줄 비교 후 선택받기.

### 본문 구조

1. 제목: `# 이슈 발행 스킬 — 수직 분할(Vertical Slice) + CI/CD-first v3.0`
2. **v3.0 핵심 변화 표** (vs v2.1) — 6행: CI/CD 위치, 의존성 표현, GitHub 등록, 레이블 체계, 후속 스킬 호환, CI-N 임시 ID.
3. **슬래시 커맨드 표**: `/generate-issues-vertical`, `/vertical-issues`. GitHub에 쓰지 않고 `register-issues-to-github` 안내한다는 점 명시.
4. **핵심 철학 — CI/CD First → Walking Skeleton → Vertical Slice → MVP** ASCII 다이어그램(Phase 0-A CI Bootstrap, 0-B CD Staging, 0-C Walking Skeleton, Phase 1 Core MVP, Phase 2 MVP 확장, Phase 3 CD Production+Security+Ops). 핵심 전환 설명: v2.1의 단일 이슈를 CI-1/CI-2/CI-3 세 단계 의존 체인으로 쪼갬.
5. **행동 원칙 12개**:
   1. CI/CD First, 2. 명시적 의존성(파일 상단 위상정렬+그래프), 3. Walking Skeleton First, 4. Vertical Slicing(UI+API+DB+테스트), 5. Deploy on every slice, 6. INVEST 준수, 7. CoT 분석, 8. YAGNI, 9. 단일 책임(GitHub 쓰기 금지), 10. CI-N 임시 ID + 2-pass 치환, 11. 구분 고지, 12. 파일명 고정.
6. **AI 시스템 프롬프트** (한 단락).
7. **워크플로우** STEP 0 ~ STEP 7:
   - STEP 0 — 구분 고지 + 전략 재확인 (한 줄 안내문 인용).
   - STEP 1 — TechSpec 수집 (A 파일 경로 / B 방금 작성 / C `write-techspec` 안내).
   - STEP 2 — 관통 경로 + 기술 스택 + 배포 타겟 분석(CoT) — 도메인/관통 경로/Walking Skeleton/유저 스토리(P0,P1)/기술 스택(FE,BE,DB,CI,CD)/필수 게이트/Cross-cutting/CI/CD-first 설계안(Phase 0-A~3) 를 보여주고 A/B/C 선택.
   - STEP 3 — 이슈 목록 초안(의존성 포함 표). Phase 0-A/0-B/0-C/1/2/3 각각의 표 예시 제공(임시ID·레이블·제목·의존성·우선순위·예상). 마지막에 "이 목록으로 issues-vertical.md 를 생성할까요? A/B/C" 선택지.
   - STEP 4 — 상세 이슈 작성 템플릿 — 각 이슈는 `## #CI-[N] [레이블] 제목` + 메타(레이블/공통 레이블/Phase/연관 US/예상 소요/Depends on/Required by/분할 전략/출력 파일) + 배경 + **수직 슬라이스 체크리스트**(UI/API/DB/CI·CD/유효성·권한/테스트/배포) + Acceptance Criteria + 참고. `**Depends on**`은 CI-N 임시 ID로만 표기, 실제 GitHub 번호는 register-issues-to-github가 2-pass 치환.
   - STEP 5 — 위상 정렬 + 의존성 그래프 자동 생성. 5.1 권장 실행 순서(Kahn's 알고리즘, `order:NNN` 부여) 표, 5.2 ASCII 의존성 그래프.
   - STEP 6 — 파일 저장 체크리스트 6항(파일명 가드, layered와 충돌 방지, 기존 파일 A/B/C/D 옵션, 상단 헤더 포함, Depends on 필드 존재, 사이클 없음).
   - STEP 7 — 완료 메시지(총 이슈/위치/전략/의존성 간선/가장 빠른 CI/CD 도달) + 다음 단계 체인(register-issues-to-github → github-kanban → implement-top-issue).
8. **이슈 레이블 체계 (v3.0 정식)**: 카테고리 레이블 9종 표(`[CI]`, `[CD]`, `[Skeleton]`, `[Slice]`, `[Security]`, `[Ops]`, `[A11y]`, `[QA]`, `[Docs]`) + 공통 레이블 6종 표 + 레이블 자동 부여 규칙 4개(mandatory-gate / priority:p0 / profile / order:NNN).
9. **의존성 규칙(v3.0 강제)** 7개:
   1. CI-1만 "없음" 허용
   2. 모든 [CD]는 [CI]에 의존
   3. 모든 [Skeleton]은 Phase 0-B에 의존
   4. 모든 [Slice]는 [Skeleton] + Phase 0-B에 의존
   5. Phase 3 [CD] profile:prod는 Phase 1 슬라이스 + Phase 0-B에 의존
   6. 사이클 금지 (Kahn's)
   7. 사용자 수동 편집은 STEP 3 초안 단계에서.
10. **`issues-vertical.md` 출력 형식** — 헤더 메타(원본 TechSpec/생성일/분할 전략/생성 스킬/출력 파일/형제 파일/총 이슈 수/Phase 구성/총 예상 소요/의존성 간선 수/가장 빠른 CI/CD 도달) + 위상정렬 블록 + 의존성 그래프 + Phase 0-A~3 본문.
11. **형제·후속 스킬 연계** ASCII 다이어그램 + 표(write-techspec / generate-issues-layered / register-issues-to-github / github-kanban / implement-top-issue / ci-cd-pipeline).
12. **충돌 방지 규칙** — 두 스킬 출력 파일명 가드, 두 파일 공존 정상, 타임스탬프 접미사, 모호한 발화 시 비교 제안.
13. **안전장치(Safety Guards) 10개** — GitHub 쓰기 금지, 파일명 가드(layered 차단), 의존성 사이클 감지, 의존성 규칙 위반 경고, CI-N 임시 ID 유일성, 빈 AC 차단, 덮어쓰기 방지(A/B/C/D), INVEST 미달 경고, Dry-run, CI/CD-first 강제(Phase 0-A/0-B 필수).
14. **실패 / 예외 처리** 표 — TechSpec 부재, CD 타겟 미명시, 유저 스토리 없음, 의존성 사이클, 동일 파일 존재, 잘못된 파일명 지정, 단순 "이슈 만들어줘", CI-N 참조 누락.
15. **사용 예시** 4건.
16. **Changelog** — v3.0(현재) / v2.1 / v2.0 / v1.0.

## 톤 / 스타일
- 한국어, 표·코드 블록·ASCII 다이어그램 적극 활용. 분량은 길어도 무방.

## 검증
- frontmatter에 모든 트리거 키워드가 포함됐는가?
- ASCII 다이어그램(핵심 철학·의존성 그래프) 두 개가 있는가?
- 행동 원칙 12개, Safety Guards 10개, 의존성 규칙 7개를 모두 갖췄는가?
- STEP 4 템플릿에 수직 슬라이스 체크리스트 7항(UI/API/DB/CI·CD/유효성·권한/테스트/배포)이 있는가?
- v3.0 핵심 변화 표가 v2.1과 비교 가능한가?
