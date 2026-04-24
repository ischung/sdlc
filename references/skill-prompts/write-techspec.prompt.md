# Prompt — `write-techspec` SKILL.md 생성 요청

## 역할
당신은 Claude 스킬 작성자입니다. 아래 명세에 따라 **`write-techspec` 스킬의 SKILL.md 한 개 파일**을 생성하세요. 출력은 SKILL.md 본문 그대로(코드 블록 없이)이며, 파일 맨 위에 YAML frontmatter가 와야 합니다.

## 산출물 요구사항

### Frontmatter
- `name`: `write-techspec`
- `description`(한 단락): "PRD(제품 요구사항 문서)를 분석하여 TechSpec(기술 명세서)을 단계적으로 작성하는 스킬"이라는 핵심을 담고, 다음 작업 순서를 나열할 것 — 아키텍처 패턴 결정 → 기술 스택 선정 → 데이터 모델 → API 명세 → 기능 명세 → UI 가이드 → 마일스톤. **섹션별 승인 루프**로 진행하고 최종 마크다운 파일로 저장한다는 점 강조.
- 트리거 키워드: "techspec 작성", "기술 명세서 만들어줘", "TechSpec 써줘", "PRD로 techspec", "tech spec 초안", "/write-techspec". 이슈 발행은 별도 스킬(`generate-issues`) 책임임을 명시.

### 본문 구조 (반드시 이 순서)

1. **제목**: `# TechSpec 작성 스킬 v1.0` + 한 줄 설명("PRD를 분석하여 개발팀이 바로 구현에 착수할 수 있는 TechSpec(기술 명세서)을 작성한다.")
2. **슬래시 커맨드 표**: `/write-techspec`. 작성 후 `generate-issues` 이어가기 옵션 안내.
3. **행동 원칙** 5가지:
   1. 설계 우선 (코드 생성 전 구조·아키텍처)
   2. CoT (분석 근거 한 줄 먼저)
   3. Separation of Concerns (레이어별 책임)
   4. Incremental validation (섹션별 승인)
   5. YAGNI
4. **AI 시스템 프롬프트 — `/write-techspec`**: "당신은 숙련된 시니어 소프트웨어 아키텍트입니다…"
5. **시작 조건**: PRD 파일 경로/내용 요청 → 분석 → 섹션별 작성 → 저장 → `generate-issues` 호출 여부 질문.
6. **TechSpec 작성 절차**:
   - **STEP 0 — PRD 수집**: A) 파일 경로 / B) 직접 붙여넣기 / C) GitHub Issue URL
   - **STEP 1 — PRD 분석 요약(CoT)**: 핵심 기능, 대상 사용자, 기술적 제약, 추천 아키텍처 패턴(+근거), 추천 기술 스택을 표/리스트로 보여주고 진행 승인 받기 (A 진행 / B 변경)
   - **STEP 2 — 섹션별 작성(승인 루프)**: 8개 섹션 순서로 진행 — ① 문서 정보(메타데이터), ② 시스템 아키텍처(패턴, Mermaid 컴포넌트 다이어그램, 배포 환경), ③ 기술 스택(표 + 선정 이유), ④ 데이터 모델(엔티티 정의, ERD, DB 스키마), ⑤ API 명세(공통 응답 형식, 엔드포인트 목록·상세), ⑥ 상세 기능 명세(Frontend 컴포넌트 트리 / Backend 레이어 책임), ⑦ UI/UX 스타일 가이드(디자인 토큰, 타이포, 공통 컴포넌트), ⑧ 개발 마일스톤(Phase 1~4). 각 섹션 작성 후 "[섹션명] 초안을 작성했어요. 확인 후 승인해주세요. 수정이 없으면 '다음'이라고 말씀해주세요." 안내.
   - **STEP 3 — 파일 저장**: 파일명 옵션 A(`techspec.md`) / B(`[project-slug]-techspec.md`) / C(직접 입력) → 저장 후 후속 `generate-issues` 호출 여부 질문(A/B).
7. **TechSpec 출력 형식** — 다음 구조의 마크다운 템플릿을 ```markdown 블록으로 제공:
   - `# Tech Spec: [기능/프로젝트명]`
   - 1. 문서 정보(작성일/상태/버전/원문 PRD 표)
   - 2. 시스템 아키텍처 (2-1 패턴 표, 2-2 Mermaid `graph LR` 다이어그램, 2-3 배포 환경 표 — Frontend/Backend/Database/CI·CD)
   - 3. 기술 스택 표 (분류·기술·버전·선정 이유)
   - 4. 데이터 모델 (TypeScript interface + Mermaid `erDiagram`)
   - 5. API 명세 (RESTful 엔드포인트 목록 + 상세 요청/응답 예시)
   - 6. 상세 기능 명세 (6-1 Frontend, 6-2 Backend)
   - 7. UI/UX 스타일 가이드
   - 8. 개발 마일스톤 — Phase 1 기반 구축 / Phase 2 핵심 기능 / Phase 3 보조 기능·UI / Phase 4 안정화·배포
   - 부록 A 용어 정의 / B 미결 사항(Open Questions) / C 변경 이력
8. **후속 스킬 연계** 섹션 — 저장 완료 시 `generate-issues` 안내 ("INVEST 원칙 기반 티켓으로 분할하고 issues.md 및 GitHub 이슈로 등록").

## 톤 / 스타일
- 한국어, 반말 금지.
- 한국 개발팀에 익숙한 어휘로 작성. 단, 약어(PRD, TechSpec, ERD, INVEST, API, RESTful)는 영문 그대로.

## 검증
- frontmatter `name=write-techspec` 인가?
- 트리거 키워드 6개 모두 포함됐는가?
- STEP 0~3 흐름과 8개 섹션 순서가 정확한가?
- 출력 템플릿에 Mermaid `graph LR`와 `erDiagram` 두 개가 있는가?
- 마지막에 `generate-issues` 후속 스킬 연계 안내가 있는가?
