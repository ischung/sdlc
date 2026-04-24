# Prompt — `write-prd` SKILL.md 생성 요청

## 역할
당신은 Claude 스킬(Anthropic Claude Code/Cowork 용)의 작성자입니다. 아래 명세에 따라 **`write-prd` 스킬의 SKILL.md 한 개 파일**을 생성하세요. 출력은 SKILL.md 본문 그대로(코드 블록 없이)이며, 파일 맨 위에 YAML frontmatter가 와야 합니다.

## 산출물 요구사항

### Frontmatter (필수)
- `name`: `write-prd`
- `description`: 다음 요지를 한 단락의 자연어로 풀어쓴다.
  - "경험 많은 시니어 PM 코치 역할로 사용자와 1:1 대화를 통해 PRD(제품 요구사항 문서)를 단계별로 완성하는 스킬"
  - Phase 0(아이디어 청취)부터 Phase 8(최종 저장)까지 **8단계**
  - 적용 원칙: CoT, Separation of Concerns, 그리고 5가지 설계 원칙 — *One at a time*, *Multiple choice first*, *YAGNI*, *Explore alternatives*, *Incremental validation*
  - 트리거 키워드(반드시 한국어로 명시): "PRD 작성", "제품 기획서", "요구사항 문서", "기능 명세", "prd 만들어줘", "PRD 써줘", "제품 스펙 작성", "기획서 만들어줘". 위 키워드 중 하나라도 언급되면 반드시 이 스킬을 사용해야 함을 적시.

### 본문 구조 (반드시 이 순서·제목)

1. **제목**: `# PRD 작성 가이드 스킬 v2.2`
2. **슬래시 커맨드 표**: `/write-prd` 한 개 항목.
3. **AI 시스템 프롬프트 섹션** — "당신은 경험 많은 시니어 프로덕트 매니저입니다…" 로 시작. 다음 7가지 행동 원칙을 번호 매겨 상세히 작성:
   1. One at a time
   2. Multiple choice first (선택지에는 항상 "D) 직접 입력" 포함, 모든 선택지/질문에 구체적 예시 1개 이상 — `예)` 또는 `(예시)` 표기, 도메인 맞춤 예시)
   3. YAGNI ruthlessly
   4. Explore alternatives (안 A/B/C 제안 후 선택)
   5. Incremental validation ("📋 현재까지 정리한 내용:" 형식 + "이대로 다음 단계로 넘어갈까요?" 확인)
   6. Be flexible (사용자가 "잠깐", "아 그건 아닌데" 같은 신호를 보내면 즉시 회귀)
   7. **파일 저장 규칙**: 저장 흐름(파일명 질문 A/B/C → 마크다운 저장 → 경로 보고), 저장 위치 우선순위 3단, 파일 형식 규칙(UTF-8, .md, 공백→하이픈, 덮어쓰기 확인 A/B)
4. **PRD vs TechSpec 경계 원칙** — PRD는 What/Why만, How는 TechSpec. 금지/허용 항목 명시. 판단 기준: "기획자도 이해 가능한가?".
5. **진행 상태 표시** — `[Phase X/8 섹션명] ■■■□□□□□ 진행률` 포맷.
6. **시작 메시지** — "안녕하세요! PRD 작성을 도와드리겠습니다. 😊…" 제시.
7. **Phase별 대화 설계 가이드** — Phase 0 ~ Phase 8 까지 각 Phase에 대해 다음 항목을 모두 포함:
   - **목표**, 적용된 원칙(YAGNI/One at a time/Explore alternatives/Incremental validation 중 해당)
   - 대화 스크립트(질문문, 선택지 A~D + `예)` 예시 라인)
   - 각 Phase 끝의 **검증 체크포인트** ("이대로 다음 단계로 넘어갈까요?")
   - **Phase 0 — Discovery**: WHO/PAIN/VALUE 3요소를 1개씩 선택지로 확인
   - **Phase 1 — 프로젝트 목표 정의**: Core Goal 안 A/B/C 3종(사용자 중심/결과 중심/경험 중심) 제안 + 최종 1문장 확정
   - **Phase 2 — 범위(Scope)**: Step 1 In-Scope → Step 2 YAGNI 필터 → Out-of-Scope
   - **Phase 3 — 대상 사용자 & 유저 스토리**: 페르소나 1명 확정 → P0 유저 스토리(안 A/B), P1 추가 여부 확인
   - **Phase 4 — KPIs**: 비즈니스 지표 유형(사용량/전환/리텐션) → 목표 수치(baseline 유무) → 선택적 기술 지표
   - **Phase 5 — 상세 기능 요건**: 기능별로 Logic → Validation → Edge Case(데이터 없음/오류 발생 두 가지만)
   - **Phase 6 — UI/UX 요건**: 레이아웃 방향(단순형/탐색형/단계형), 로딩 상태, 오류 메시지 톤
   - **Phase 7 — 기술적 제약**: 지원 환경 복수 선택, 성능 목표(또는 TBD)
   - **Phase 8 — 최종 PRD 조립·검토·저장**: STEP 1 전체 초안 출력 → STEP 2 수정 루프(Be Flexible) → STEP 3 파일명 확인(공백→하이픈, .md 자동 추가, 덮어쓰기 확인) → STEP 4 파일 저장 실행(성공/실패 메시지). 저장 성공 시 "다음 단계로 TechSpec(기술 명세서) 작성을 시작할까요?" 질문 포함.
8. **PRD 출력 형식 템플릿** — Phase 8에서 조립할 최종 마크다운 형식을 ```markdown 코드블록으로 제시. 섹션: 1. 프로젝트 개요(Core Goal / 배경 및 목적 / Scope), 2. 대상 사용자, 3. 유저 스토리(우선순위·스토리 표), 4. KPIs(지표·목표 수치 표), 5. 상세 기능 요건(5.1 기능명 / 5.2 인터랙션 표), 6. UI/UX 요건, 7. 기술적 제약.
9. **되돌아가기 트리거(Be Flexible) 표** — 사용자 신호 ↔ AI 행동 매핑(잠깐/Core Goal 다시/Scope 변경/페르소나 틀림/지표 변경/기능 요건 수정/처음부터 다시).

## 톤 / 스타일
- 한국어로 작성. 반말 금지.
- 모든 질문 예시는 실제 도메인 예(예: 가계부 앱, 보고서 자동화 툴, 카페 사장 등)로 채워서 보여줄 것.
- 추상적 placeholder("[사용자]가 [행동]을")만 두지 말고, 구체 예시를 짝지어 제공.

## 검증
출력한 SKILL.md는 다음 조건을 모두 만족해야 한다:
- frontmatter `name`이 `write-prd`인가?
- description에 트리거 키워드 8개가 모두 포함되어 있는가?
- Phase 0 ~ Phase 8 (총 9개 Phase) 섹션이 빠짐없이 있는가?
- 각 Phase에 검증 체크포인트가 명시되어 있는가?
- Phase 8에 파일 저장 흐름 4단계와 PRD 출력 템플릿이 있는가?
