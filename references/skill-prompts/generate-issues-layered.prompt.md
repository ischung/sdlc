# Prompt — `generate-issues-layered` SKILL.md 생성 요청

## 역할
당신은 Claude 스킬 작성자입니다. **`generate-issues-layered` 스킬의 SKILL.md (v3.0)** 한 개 파일을 만드세요. `generate-issues-vertical`의 형제 스킬로, 동일한 품질·구조의 결과물을 **계층(Layer) 분할** 관점으로 작성합니다.

## 산출물 요구사항

### Frontmatter
- `name`: `generate-issues-layered`
- `description`: TechSpec을 **아키텍처 계층별 분할 + CI/CD-first** 전략으로 쪼개어 `issues-layered.md`로만 저장(v3.0). v2.0의 Setup→Infra→DB→Backend→Core Logic→Frontend→UI/UX→Test→Docs 순서를 유지하되, **Layer 0(CI 부트스트랩)**과 **Layer 2(CD 스켈레톤)**를 기능 계층 전면에 배치. 각 이슈는 `**Depends on**: #N`으로 명시적 의존성, 파일 상단 위상 정렬 + 의존성 그래프 자동 생성. **GitHub 등록은 하지 않음** — `register-issues-to-github`에 위임. 보드는 `github-kanban`, 구현은 `implement-top-issue`. 공통 레이블 체계(`priority:p0~p3`, `mandatory-gate`, `order:NNN`, `profile:staging/prod`, `strategy:layered`) 준수. 트리거: "계층별 이슈 만들어줘", "레이어별 분할", "DB→Backend→Frontend 순서", "수평 분할", "아키텍처 계층별", "백엔드/프런트 분리 작업", "CI/CD 먼저인 계층 분할", "/generate-issues-layered", "/layered-issues". 수직 분할 원하면 `generate-issues-vertical` 안내, 모호하면 비교.

### 본문 구조

1. 제목: `# 이슈 생성 스킬 — 계층별 분할(Layered) + CI/CD-first v3.0`
2. **v3.0 핵심 변화 표** (vs v2.0): CI/CD 순서, 기능 계층 시작, 의존성 표현, GitHub 등록(분리 유지), 레이블 체계, CD 단계, 후속 스킬 호환, CI-N 임시 ID.
3. **슬래시 커맨드 표**: `/generate-issues-layered`, `/layered-issues`, `/generate-issues` (하위 호환 별칭).
4. **형제 스킬과의 구분 표** (이 스킬 vs generate-issues-vertical vs register-issues-to-github) + **언제 이 스킬을 선택해야 하는가** 표 5행(레거시 리팩터링/팀 분리 병렬/DB 선행/조기 배포/MVP 프로토타입).
5. **핵심 철학** ASCII 다이어그램(Layer 0~Layer 11): Layer 0 CI Bootstrap, Layer 1 Setup, Layer 2 CD Staging Skeleton, "이 선 아래부터 기능 계층" 구분선, Layer 3 Data, Layer 4 Service, Layer 5 Domain, Layer 6 Presentation, Layer 7 Styling, Layer 8 Quality, Layer 9 CD Production+Security, Layer 10 Ops, Layer 11 Docs. 핵심 전환 설명: v2.0 [Infra]를 [CI]/[CD]로 분해, CD를 스테이징/프로덕션 두 번으로 분할.
6. **행동 원칙 11개**: CI/CD First, 단일 책임, 명시적 의존성, INVEST, CoT, 논리적 순서, Incremental validation, YAGNI, CI-N 임시 ID, 구분 고지, 파일 경로 안전성.
7. **AI 시스템 프롬프트 — `/generate-issues-layered`** 한 단락.
8. **워크플로우** STEP 0 ~ STEP 7:
   - STEP 0 — 구분 고지 (한 줄 안내문 인용 — Layer 0~Layer 3 순서 설명).
   - STEP 1 — TechSpec 수집 (A/B/C 옵션).
   - STEP 2 — 계층 + 기술 스택 + CD 타겟 분석(CoT) 블록 — 도메인/엔티티/API 영역/프런트 화면/관통 의존성/Cross-cutting/기술 스택/필수 게이트 + Layer 0~11 설계안. A/B/C 진행 선택.
   - STEP 3 — 이슈 목록 초안(의존성 표) — Layer 0~11 각각의 표 예시. "━ 여기까지가 기능 계층 시작의 필수 선행 조건 (#CI-7 통과 이후) ━" 구분선 포함. 마지막 A/B/C 옵션.
   - STEP 4 — 상세 이슈 작성 템플릿 (`## #CI-[N] [레이블] 제목` + 메타 + 설명 + AC + 참고). AC에 "스테이징 URL에서 변경 확인 가능"(Layer 3 이상) 항목.
   - STEP 5 — 위상 정렬 + 의존성 그래프 (5.1 표 5.2 ASCII).
   - STEP 6 — 파일 저장 체크리스트 7항 (특히 7번: Layer 3+ 이슈가 Layer 2 CI-7에 직·간접 의존).
   - STEP 7 — 완료 메시지 + 후속 체인.
9. **이슈 레이블 체계 (v3.0 정식)** — 카테고리 레이블 12종 표(`[CI]`/`[CD]`/`[Setup]`/`[DB]`/`[Backend]`/`[Core Logic]`/`[Frontend]`/`[UI/UX]`/`[Test]`/`[Security]`/`[Ops]`/`[Docs]` + 각 Layer 매핑) + v2.0 `[Infra]` 폐지 안내 + 공통 레이블 6종 + 레이블 자동 부여 규칙 4개.
10. **의존성 규칙 13개** — 이 스킬 핵심: **규칙 4번 = 모든 Layer 3 [DB]는 Layer 2 CD 스테이징 smoke(CI-7 등)에 직·간접 의존 — CI/CD-first의 핵심 강제 조건**. 그 외 Layer 1~Layer 11 의존 규칙, 사이클 금지.
11. **`issues-layered.md` 출력 형식** — 헤더 메타 + 위상정렬 + 의존성 그래프 + Layer 0~11 본문. "── 기능 계층 시작 (Layer 2 완료 이후) ──" 구분선 포함.
12. **형제·후속 스킬 연계** — ASCII 다이어그램 + 표.
13. **안전장치(Safety Guards) 11개** — 특히 4번 CI/CD-first 강제(Layer 3+ 모두 CI-7 의존), 5번 Layer 역행 금지, 11번 `[Infra]` 레거시 감지.
14. **실패/예외 처리 표** — `[Infra]` 발견 시 [CI]/[CD] 분해 제안, Layer 3 이슈가 CI-7 무의존 시 자동 의존성 추가 제안 등.
15. **사용 예시** 4건.
16. **Changelog** — v3.0 / v2.0 / v1.0.

## 톤 / 스타일
- 한국어, 표·코드·ASCII 적극 활용. `generate-issues-vertical.prompt.md`와 자매 톤 유지하되 "Layer" 어휘 통일.

## 검증
- frontmatter 트리거 키워드 모두 포함?
- Layer 0~11 12개 계층이 핵심 철학 다이어그램·STEP 3 초안·출력 형식에 일관 사용?
- v2.0 `[Infra]` → v3.0 `[CI]`/`[CD]` 분해 안내 명시?
- 의존성 규칙 4번(Layer 3+ → CI-7 직·간접 의존)이 본문에 강조됐는가?
- 레이블 체계 12종 + 공통 6종이 표로 정리됐는가?
