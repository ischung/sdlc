---
name: generate-issues-vertical
description: >
  TechSpec(기술 명세서)을 **Walking Skeleton + Vertical Slice + CI/CD-first** 전략으로
  분할해 `issues-vertical.md` 파일로 저장하는 스킬 (v3.0). 어떤 기능 이슈보다도 먼저
  CI 부트스트랩(lint/test) → CD 스테이징 → Walking Skeleton → 수직 슬라이스 순서로
  구성하여 **"모든 후속 이슈가 초록불 파이프라인 위에서 굴러가는"** 상태를 가장 빨리
  만든다. 각 이슈는 `**Depends on**: #N` 으로 명시적 의존성을 기재하고, 파일 상단에
  위상 정렬(topological order) 실행 순서 + 의존성 그래프를 포함한다. INVEST 6요건을
  충족하며 각 슬라이스는 UI+API+DB+테스트+배포까지 End-to-End를 포함한다.
  ⚠️ **GitHub 등록은 수행하지 않는다.** 이 스킬은 파일 생성까지만 담당하고, 등록은
  후속 스킬 `register-issues-to-github` 에 위임한다. 보드 배치는 `github-kanban`,
  구현은 `implement-top-issue` 에 위임한다. 공통 레이블 체계(`priority:p0~p3`,
  `mandatory-gate`, `order:NNN`, `profile:staging/prod`, `strategy:vertical-slice`)를
  준수하여 후속 스킬과 완벽히 호환된다.
  사용자가 "수직 분할", "수직 슬라이스", "버티컬 슬라이스", "vertical slice",
  "Walking Skeleton", "워킹 스켈레톤", "MVP 방식 이슈", "유저 스토리 단위 이슈",
  "CI/CD 먼저 만드는 이슈", "파이프라인부터 이슈", "/generate-issues-vertical",
  "/vertical-issues" 중 하나라도 언급하면 반드시 이 스킬을 사용할 것.
  사용자가 "아키텍처 계층별", "레이어별", "DB→Backend→Frontend 순서", "수평 분할",
  "/generate-issues-layered" 등을 언급하면 형제 스킬 `generate-issues-layered` 를
  사용한다. 모호하면 두 전략을 2~3줄로 비교해 선택을 받는다.
---

# 이슈 발행 스킬 — 수직 분할(Vertical Slice) + CI/CD-first v3.0

TechSpec을 **"CI/CD가 가장 먼저, 기능은 그 위에 슬라이스로 얹는다"** 전략으로 분할해 `issues-vertical.md` 파일로 저장한다. v2.1의 Walking Skeleton 철학을 유지하되, **CI/CD 부트스트랩을 Phase 0 최상단으로 끌어올리고 모든 의존성을 명시적 그래프로 표현**한다.

**결과 저장 파일명은 `issues-vertical.md` 로 고정**한다 (형제 스킬 `generate-issues-layered` 의 `issues-layered.md` 와 충돌 방지).

---

## v3.0 핵심 변화 (vs v2.1)

| 구분 | v2.1 | **v3.0 (이 문서)** |
| :---- | :---- | :---- |
| CI/CD 위치 | Phase 0 Skeleton 안에 혼재 | **Phase 0-A (CI 부트스트랩) + Phase 0-B (CD 스테이징) 을 기능 슬라이스보다 먼저 강제** |
| 의존성 표현 | "Depends on #N" 간헐적 기재 | **모든 이슈에 `**Depends on**` 필드 + 파일 상단 위상 정렬 블록** |
| GitHub 등록 | `gh issue create` 포함 | **분리 — `register-issues-to-github` 로 위임** |
| 레이블 체계 | `[Skeleton]/[Slice]/[Ops]/…` | **`[CI]/[CD]/[Skeleton]/[Slice]/[Ops]/…` + 공통 레이블 (`priority`, `mandatory-gate`, `order`, `profile`, `strategy`)** |
| 후속 스킬 호환 | 부분 | **github-kanban · implement-top-issue v1.3 와 완벽 호환** |
| CI-N 임시 ID | 없음 | **`CI-1`, `CI-2`, …로 임시 ID 부여 → register 단계에서 2-pass 치환** |

---

## 슬래시 커맨드

| 커맨드 | 설명 |
| :---- | :---- |
| `/generate-issues-vertical` | TechSpec → `issues-vertical.md` (CI/CD-first 수직 분할) |
| `/vertical-issues` | 축약형 별칭 |

이 스킬은 **GitHub 저장소에 쓰지 않는다**. 산출물은 `issues-vertical.md` 파일뿐이며, 완료 후 "GitHub 에 등록하려면 `register-issues-to-github` 스킬을 실행하세요" 라고 안내한다.

---

## 핵심 철학 — CI/CD First → Walking Skeleton → Vertical Slice → MVP

```
         ┌─────────────────────────────────────────────────────┐
Phase 0-A│  CI Bootstrap (lint + unit test on PR)              │  ← 기능 이슈 이전에 완성
         │   · 어떤 기능보다 먼저 초록불 파이프라인             │
         └─────────────────────────────────────────────────────┘
                        │ CI가 있어야만
                        ▼
         ┌─────────────────────────────────────────────────────┐
Phase 0-B│  CD Staging (자동 배포 + smoke test)                 │  ← Skeleton의 착지점
         │   · main 머지 = 스테이징 자동 배포                   │
         └─────────────────────────────────────────────────────┘
                        │ 배포 파이프라인 위에
                        ▼
         ┌─────────────────────────────────────────────────────┐
Phase 0-C│  Walking Skeleton (UI→API→DB 관통 Hello World)       │  ← 가장 얇은 E2E
         │   · 스테이징 URL에서 동작 확인                       │
         └─────────────────────────────────────────────────────┘
                        │
                        ▼
Phase 1  ┌─────┬─────┬─────┐  각 Slice = UI+API+DB+테스트+배포
Core MVP │  A  │  B  │  C  │  (CI 초록불 + 스테이징 배포 완료가 DoD)
(P0 US)  └─────┴─────┴─────┘
                        │
                        ▼
Phase 2  ┌─────┬─────┐
MVP 확장 │  D  │  E  │   P0 잔여 + P1 유저 스토리 수직 슬라이스
(P0+P1)  └─────┴─────┘
                        │
                        ▼
         ┌─────────────────────────────────────────────────────┐
Phase 3  │  CD Production + Security + Ops + A11y + QA + Docs   │  ← 운영화
         │   · mandatory-gate: SAST/의존성 스캔/E2E smoke         │
         └─────────────────────────────────────────────────────┘
```

**핵심 전환**: v2.1에서는 "Hello World가 프로덕션까지 배포되는 최소 E2E"를 한 이슈로 묶었지만, v3.0에서는 이를 CI-1 (CI 부트스트랩) / CI-2 (CD 스테이징) / CI-3 (Walking Skeleton) **세 단계의 의존 체인**으로 쪼개어 각 단계가 독립적으로 초록불이 되는지 확인한다.

---

## 행동 원칙

1. **CI/CD First (신규)**: 어떤 기능 슬라이스보다도 먼저 CI 부트스트랩(Phase 0-A) → CD 스테이징(Phase 0-B) 을 완성한다. 기능 슬라이스는 CD 스테이징 이후부터만 생성 가능.
2. **명시적 의존성 (신규)**: 모든 이슈는 `**Depends on**` 필드를 가진다. 의존성이 없으면 "없음" 이라고 명시. 파일 상단에 **위상 정렬된 실행 순서 + 의존성 그래프**를 자동 생성.
3. **Walking Skeleton First**: 첫 번째 기능-보이는 이슈는 "스테이징 URL에서 Hello World 가 동작하는" 최소 E2E.
4. **Vertical Slicing**: 각 `[Slice]` 이슈는 UI + API + DB + 테스트를 모두 포함하는 수직 슬라이스.
5. **Deploy on every slice**: 각 슬라이스 완료 = 스테이징 URL에서 동작 + CI 초록불.
6. **INVEST 준수**: 모든 이슈는 INVEST 6요건을 충족.
7. **CoT 분석**: 이슈 설계 전 관통 경로 · P0 유저 스토리 · 기술 스택 · 배포 타겟을 먼저 요약.
8. **YAGNI**: TechSpec에 명시되지 않은 작업은 이슈로 만들지 않는다.
9. **단일 책임 (신규)**: 이 스킬은 파일 생성까지만. `gh issue create`, `gh label create` 등 GitHub 쓰기 호출 절대 금지.
10. **CI-N 임시 ID (신규)**: 파일 내부에서는 `#CI-1`, `#CI-2`, … 형태의 임시 ID로 의존성을 기재. 실제 GitHub 번호는 `register-issues-to-github` 가 2-pass 치환.
11. **구분 고지**: 실행 초기에 "수직 분할 + CI/CD-first, `issues-vertical.md` 저장, 계층별 분할은 `/generate-issues-layered`" 한 줄.
12. **파일명 고정**: 기본 `issues-vertical.md`. `issues-layered.md` 로 저장 금지.

---

## AI 시스템 프롬프트 — `/generate-issues-vertical`

당신은 숙련된 DevOps + 소프트웨어 엔지니어입니다. 제공된 TechSpec 을 분석하여 **CI 부트스트랩과 CD 스테이징을 가장 먼저** 완성하고, 그 위에 Walking Skeleton 및 수직 슬라이스로 기능을 점진적으로 누적해 MVP 를 완성하는 이슈 목록으로 분할합니다. 결과는 `issues-vertical.md` 파일에만 저장하며, **GitHub 등록은 수행하지 않고** 후속 스킬에 위임합니다.

---

## 워크플로우

### STEP 0 — 구분 고지 + 전략 재확인

최초 응답 한 줄:

> "수직 분할(Vertical Slice) + CI/CD-first 방식으로 이슈를 생성하며 결과는 `issues-vertical.md` 에 저장합니다. CI 부트스트랩 → CD 스테이징 → Walking Skeleton 이 기능 이슈보다 먼저 나오는 순서입니다. 계층별 분할을 원하시면 `/generate-issues-layered` (→ `issues-layered.md`) 를 사용해주세요. **GitHub 등록은 이 스킬에서 수행하지 않고 `register-issues-to-github` 에 위임합니다.**"

### STEP 1 — TechSpec 수집

"이슈 설계를 시작합니다. 분석할 TechSpec 파일을 알려주세요.

- A) 파일 경로 입력 (예: `techspec.md`)
- B) 방금 작성한 TechSpec 을 바로 사용할게요
- C) TechSpec 이 아직 없어요 → `write-techspec` 스킬을 먼저 실행해주세요"

### STEP 2 — 관통 경로 + 기술 스택 + 배포 타겟 분석 (CoT)

이슈 설계 전 다음을 사용자에게 먼저 제시:

```
TechSpec 분석 결과:

 🔍 프로젝트 도메인 : [요약]
 🧭 관통 경로       : [UI 진입점] → [API] → [DB 테이블] → [외부 의존 N개]
 🎯 Walking Skeleton: [예: 로그인 없이 샘플 1건 조회]
 📊 유저 스토리
    · P0 : US-01, US-02, US-03 — 각각 수직 슬라이스
    · P1 : US-04 — Phase 2
 🛠️ 기술 스택
    · Frontend : [Next.js / React / Vue / …]
    · Backend  : [Node/Express, Python/FastAPI, Go, …]
    · DB       : [PostgreSQL / MySQL / DynamoDB / …]
    · CI       : GitHub Actions (검토 필요)
    · CD 타겟   : [Vercel / Fly.io / Render / AWS ECS / Cloudflare / …]
 🛡️ 필수 게이트   : lint, unit-test, SAST, dependency-audit, E2E-smoke
 🌐 Cross-cutting : 관측성, 접근성, E2E, 문서

CI/CD-first 설계안:
  Phase 0-A : CI 부트스트랩 (lint + unit test on PR)
  Phase 0-B : CD 스테이징 (main 머지 = 자동 배포 + smoke)
  Phase 0-C : Walking Skeleton (UI→API→DB 관통 Hello World, 스테이징에서 확인)
  Phase 1   : Core MVP (P0 수직 슬라이스)
  Phase 2   : MVP 확장 (P1 + 엣지 케이스)
  Phase 3   : CD 프로덕션 + Security + Ops + A11y + QA + Docs

이대로 진행할까요?
  A) 네, 진행해주세요
  B) 관통 경로 / CD 타겟 / 유저 스토리 우선순위를 수정하고 싶어요
  C) 계층별 분할이 더 적절할 것 같아요 → /generate-issues-layered 로 전환
```

### STEP 3 — 이슈 목록 초안 (의존성 포함 표)

승인 후 Phase 별로 **의존성을 CI-N 임시 ID 로 명시**하여 초안 제시. 초안 표는 아래 고정 구조를 갖는다.

```
이슈 [N]개를 CI/CD-first 수직 분할로 설계했어요:

【 Phase 0-A · CI 부트스트랩 】
| 임시ID | 레이블         | 제목                                             | 의존성     | 우선순위 | 예상 |
| :----- | :------------- | :----------------------------------------------- | :--------- | :------- | :--- |
| CI-1   | [CI]           | 저장소 초기화 + lint/format + pre-commit 설정     | 없음       | P0       | 0.5일 |
| CI-2   | [CI]           | GitHub Actions 기본 워크플로 (lint + unit test)  | #CI-1      | P0       | 0.5일 |
| CI-3   | [CI] [mandatory-gate] | PR 보호 규칙 + 상태 배지                  | #CI-2      | P0       | 0.5일 |

【 Phase 0-B · CD 스테이징 】
| 임시ID | 레이블           | 제목                                                    | 의존성       | 우선순위 | 예상 |
| :----- | :--------------- | :------------------------------------------------------ | :----------- | :------- | :--- |
| CI-4   | [CD] profile:staging | 스테이징 환경 준비 (환경변수/시크릿/DB 인스턴스)     | #CI-2        | P0       | 1일  |
| CI-5   | [CD] profile:staging | main 머지 → 스테이징 자동 배포 워크플로                | #CI-4        | P0       | 1일  |
| CI-6   | [CD] profile:staging [mandatory-gate] | 배포 후 smoke test 자동 수행     | #CI-5        | P0       | 0.5일 |

【 Phase 0-C · Walking Skeleton 】
| 임시ID | 레이블         | 제목                                                    | 의존성       | 우선순위 | 예상 |
| :----- | :------------- | :------------------------------------------------------ | :----------- | :------- | :--- |
| CI-7   | [Skeleton]     | 최소 Frontend 페이지 + Backend health 엔드포인트         | #CI-6        | P0       | 1일  |
| CI-8   | [Skeleton]     | DB 연결 확인 + migration 스켈레톤                       | #CI-7        | P0       | 0.5일 |
| CI-9   | [Skeleton]     | 인증/공통 응답 뼈대 (더미 /me 관통)                     | #CI-8        | P1       | 1일  |

【 Phase 1 · Core MVP (P0 수직 슬라이스) 】
| 임시ID | 레이블         | 제목                                   | 연관 US | 의존성           | 우선순위 | 예상 |
| :----- | :------------- | :------------------------------------- | :------ | :--------------- | :------- | :--- |
| CI-10  | [Slice]        | US-01 · [행동] Happy Path               | US-01   | #CI-8, #CI-6     | P1       | 1.5일|
| CI-11  | [Slice]        | US-02 · [행동] Happy Path               | US-02   | #CI-10           | P1       | 1일  |
| CI-12  | [Slice]        | US-03 · [행동] Happy Path               | US-03   | #CI-10           | P1       | 1.5일|

【 Phase 2 · MVP 확장 (P0 잔여 + P1) 】
| CI-13  | [Slice]        | US-01 엣지 케이스 처리                  | US-01   | #CI-10           | P2       | 1일  |
| CI-14  | [Slice]        | US-04 · [P1 행동] 수직 슬라이스         | US-04   | #CI-11           | P2       | 1.5일|

【 Phase 3 · CD 프로덕션 + Security + Ops 】
| CI-15  | [CD] profile:prod [mandatory-gate] | 프로덕션 배포 파이프라인 + 수동 승인 게이트 | #CI-6, #CI-12 | P0 | 1일 |
| CI-16  | [Security] [mandatory-gate] | SAST + 의존성 취약점 스캔 주기 실행      | #CI-2         | P0 | 0.5일 |
| CI-17  | [Ops]          | 에러 모니터링(APM/Sentry) + 알람 채널   | #CI-15        | P1 | 0.5일 |
| CI-18  | [QA]           | E2E 테스트 스위트 확장                  | #CI-12        | P2 | 1일  |
| CI-19  | [A11y]         | 주요 화면 WCAG AA 검토 + 개선            | #CI-12        | P2 | 1일  |
| CI-20  | [Docs]         | 릴리즈 노트 + 운영 런북                  | #CI-15        | P2 | 0.5일 |

총합: [N]개, 예상 [합산]일

이 목록으로 issues-vertical.md 를 생성할까요?
  A) 네, 생성해주세요
  B) 일부 수정/추가/삭제 (구체적 항목 지정)
  C) 파일명을 바꾸고 싶어요 (단, issues-layered.md 는 사용 불가)
```

### STEP 4 — 상세 이슈 작성 (의존성 + 수직 슬라이스 체크리스트 포함)

각 이슈를 아래 템플릿으로 기록한다. `**Depends on**` 은 **CI-N 임시 ID 로만** 표기하며, 실제 GitHub 번호 치환은 `register-issues-to-github` 의 2-pass 단계에서 자동 수행된다.

```markdown
## #CI-[N] [레이블] 제목

**레이블**     : [CI / CD / Skeleton / Slice / Security / Ops / A11y / QA / Docs]
**공통 레이블** : strategy:vertical-slice, priority:p[0~3], order:NNN[, mandatory-gate][, profile:staging|prod]
**Phase**      : [0-A CI 부트스트랩 / 0-B CD 스테이징 / 0-C Walking Skeleton / 1 Core MVP / 2 MVP 확장 / 3 운영화]
**연관 US**    : [US-NN / 없음]
**예상 소요**   : [X일]
**Depends on** : [없음 / #CI-M, #CI-K]
**Required by**: [#CI-A, #CI-B / 없음]    ← 역참조 (자동 채움)
**분할 전략**   : Vertical Slice + CI/CD-first
**출력 파일**   : `issues-vertical.md`

### 배경
[왜 이 이슈가 필요한지, 어떤 유저 가치 / 엔지니어링 가치가 전달되는지]

### 구현 범위 (수직 슬라이스 체크리스트)
> `[Slice]`/`[Skeleton]` 이슈는 아래 항목을 모두 다룬다. `[CI]`/`[CD]` 이슈는 해당란을 "해당 없음"으로 표기하되 워크플로/배포 대상을 명시.

- [ ] **UI**: [추가/수정되는 화면 또는 컴포넌트 / 해당 없음]
- [ ] **API**: [추가/수정되는 엔드포인트 / 해당 없음]
- [ ] **DB**: [마이그레이션 또는 쿼리 변경 / 해당 없음]
- [ ] **CI/CD**: [수정되는 워크플로 파일 또는 배포 절차 / 해당 없음]
- [ ] **유효성·권한**: [클라이언트·서버 양측 검증 규칙]
- [ ] **테스트**: [단위·통합 최소 1개 + 필요 시 E2E 1개]
- [ ] **배포**: [스테이징/프로덕션까지 배포 확인, smoke 통과]

### 수락 기준 (Acceptance Criteria)
- [ ] [검증 가능한 조건 1]
- [ ] [검증 가능한 조건 2]
- [ ] CI 파이프라인이 초록불로 통과한다
- [ ] (해당되면) 스테이징 URL 에서 [구체 행동] 이 가능하다

### 참고
- TechSpec 섹션 : [§번호]
- 관련 이슈     : [없음 / #CI-N]
- 외부 문서     : [URL / 내부 Wiki]
```

### STEP 5 — 위상 정렬 + 의존성 그래프 자동 생성

STEP 4 로 모든 이슈가 기록되면 파일 상단에 자동으로 삽입하는 두 가지 블록:

#### 5.1 위상 정렬된 실행 순서

의존성 그래프를 Kahn's 알고리즘으로 위상 정렬하여 `order:NNN` 을 부여한다. 사이클이 감지되면 중단하고 사용자에게 보고.

```
## 📜 권장 실행 순서 (위상 정렬)

| order | 임시ID | 레이블                  | 제목                                               |
| :---- | :---- | :---------------------- | :------------------------------------------------- |
| 001   | CI-1  | [CI]                    | 저장소 초기화 + lint/format                         |
| 002   | CI-2  | [CI]                    | GitHub Actions 기본 워크플로                        |
| 003   | CI-3  | [CI] mandatory-gate     | PR 보호 규칙 + 상태 배지                            |
| 004   | CI-4  | [CD] profile:staging    | 스테이징 환경 준비                                  |
| …     | …     | …                       | …                                                  |
```

위 `order` 값은 파일의 이슈 본문 헤더 `**공통 레이블**: order:NNN` 에 **동일하게 반영**한다. 이 값은 github-kanban 이 보드 배치 순서로, implement-top-issue 가 픽업 순서의 타이 브레이커로 사용한다.

#### 5.2 의존성 그래프 (ASCII)

```
## 🔗 의존성 그래프

CI-1  →  CI-2  →  CI-3
            │
            ├──►  CI-4 ──►  CI-5  ──►  CI-6  ──►  CI-7 ──►  CI-8 ──►  CI-9
            │                              │
            │                              └──►  CI-10 ──►  CI-11
            │                                         │ └──►  CI-12
            │                                         └──►  CI-13
            │                                               └──►  CI-14
            └──►  CI-16 (Security, 병렬 가능)

CI-12  ──►  CI-15 ──►  CI-17
         ──►  CI-18
         ──►  CI-19
CI-15 ──►  CI-20
```

### STEP 6 — 파일 저장

```
저장 전 체크리스트
 [1] 파일명이 issues-vertical.md 인가? (사용자 지정이 있으면 그 이름)
 [2] issues-layered.md 로 저장하지 않는가?
 [3] 같은 경로에 기존 파일이 있는가?
     · A) 덮어쓰기
     · B) 타임스탬프 백업 후 덮어쓰기 (issues-vertical.backup-YYYYMMDD-HHMMSS.md)
     · C) 다른 이름으로 저장 (issues-vertical-YYYY-MM-DD.md)
     · D) 취소
 [4] 상단 헤더에 분할 전략 · 생성 스킬명 · Phase별 이슈 수 · 위상 정렬 블록 · 의존성 그래프 포함
 [5] 모든 이슈에 **Depends on** 필드가 존재하는가? (없으면 "없음"이라고 명시)
 [6] 의존성 사이클이 없는가? (Kahn's 알고리즘으로 검증)
```

### STEP 7 — 완료 메시지 (GitHub 등록 안내 + 후속 스킬 체인)

```
✅ issues-vertical.md 저장 완료!

📋 총 이슈   : [N]개 ([합산]일)
📁 위치     : <절대 경로>
🧭 전략     : Vertical Slice + CI/CD-first
🔗 의존성   : [K]개 간선, 사이클 없음
⚡ 가장 빠른 CI/CD 도달 시각: CI-1 → CI-6 (smoke 통과) 까지 [누적 X일]

⏭️ 다음 단계 (체인)
  1️⃣  register-issues-to-github  — GitHub 이슈로 등록 (CI-N → #실번호 2-pass 치환)
  2️⃣  github-kanban               — Projects v2 보드 생성 + order:NNN 순서 배치
  3️⃣  implement-top-issue         — 우선순위 기반으로 CI-1 부터 순차 구현
     · v1.3 부터 CI/CD 이슈는 자동 감지 + ci-cd-pipeline 위임으로 처리
```

---

## 이슈 레이블 체계 (v3.0 정식)

### 카테고리 레이블 (필수, 단일 선택)

| 레이블 | 의미 |
| :---- | :---- |
| `[CI]` | CI 워크플로 구축 (lint / test / build) |
| `[CD]` | CD 워크플로 구축 (배포 / 승인 / 롤백) |
| `[Skeleton]` | Walking Skeleton — E2E 뼈대 (UI+API+DB 관통) |
| `[Slice]` | 수직 슬라이스 — 유저 스토리 단위 구현 |
| `[Security]` | 보안 게이트 (SAST / 의존성 스캔 / 시크릿 검사) |
| `[Ops]` | 관측성 / 모니터링 / 알람 |
| `[A11y]` | 접근성 |
| `[QA]` | 테스트 확장 (단위/통합/E2E) |
| `[Docs]` | 문서화 |

### 공통 레이블 (모든 이슈 공통, 후속 스킬이 소비)

| 레이블 | 값 | 소비자 |
| :---- | :---- | :---- |
| `strategy:vertical-slice` | 고정 | 전략 구분 — register-issues-to-github, github-kanban |
| `priority:p0` ~ `priority:p3` | P0=최우선 | implement-top-issue 의 픽업 캐스케이드 |
| `order:NNN` | 001~999 | github-kanban 의 보드 배치 순서 |
| `mandatory-gate` | 부여 여부 | github-kanban 의 자동 Priority=P0, implement-top-issue 의 위임 판정 |
| `profile:staging` / `profile:prod` | 택일 | github-kanban 의 Sprint=Deploy, ci-cd-pipeline 의 타겟 |
| `phase-0a-ci` / `phase-0b-cd` / `phase-0c-skeleton` / `phase-1-mvp` / `phase-2-extend` / `phase-3-ops` | 단일 | Phase 필터 (선택) |

### 레이블 자동 부여 규칙 (v3.0)

1. **`mandatory-gate`** 는 다음 중 하나라도 해당하면 자동 부여:
   - 카테고리 `[CI]` 중 PR 보호 규칙 관련
   - 카테고리 `[CD]` 중 프로덕션 배포 또는 smoke test
   - 카테고리 `[Security]` 의 모든 이슈
   - 카테고리 `[QA]` 중 "블로킹 E2E 스위트"
2. **`priority:p0`** 는 Phase 0-A / Phase 0-B 의 모든 이슈 + `mandatory-gate` 부여된 이슈
3. **`profile:staging`** 은 Phase 0-B, **`profile:prod`** 은 Phase 3 의 프로덕션 배포 이슈에 부여
4. **`order:NNN`** 은 STEP 5 위상 정렬 결과

---

## 의존성 규칙 (v3.0 강제)

1. **CI-1 (저장소 초기화)** 은 의존성 없음. 유일하게 "없음" 을 허용받는 이슈.
2. **모든 [CD] 이슈** 는 최소 하나의 [CI] 이슈에 의존해야 함.
3. **모든 [Skeleton] 이슈** 는 Phase 0-B 의 CD 스테이징 이슈에 의존해야 함.
4. **모든 [Slice] 이슈** 는 최소 하나의 [Skeleton] 이슈 + Phase 0-B 의 CD 스테이징 이슈에 의존해야 함.
5. **Phase 3 [CD] profile:prod** 이슈는 Phase 1 의 Core MVP 슬라이스 중 최소 하나 + Phase 0-B CD 스테이징에 의존해야 함.
6. **사이클 금지** — Kahn's 알고리즘으로 감지되면 STEP 5 에서 중단.
7. 사용자가 의존성을 수동 편집하고 싶으면 STEP 3 초안 단계에서 입력받는다.

---

## `issues-vertical.md` 출력 형식

```markdown
# Issues — [프로젝트명] (Vertical Slice + CI/CD-first)

> **원본 TechSpec** : [techspec.md 경로]
> **생성일**         : [YYYY-MM-DD]
> **분할 전략**     : Vertical Slice + CI/CD-first (Walking Skeleton → MVP)
> **생성 스킬**     : `generate-issues-vertical` v3.0
> **출력 파일**     : `issues-vertical.md`
> **형제 파일(참고)**: `issues-layered.md` — 계층별 분할 결과 전용
> **총 이슈 수**     : [N]개
> **Phase 구성**     : 0-A [n] · 0-B [n] · 0-C [n] · 1 [n] · 2 [n] · 3 [n]
> **총 예상 소요**   : [합산 일수]일
> **의존성 간선 수** : [K], 사이클 없음
> **가장 빠른 CI/CD 도달**: CI-1 → … → CI-6 (smoke 통과) = 누적 [X]일

---

## 📜 권장 실행 순서 (위상 정렬)
[STEP 5.1 블록]

## 🔗 의존성 그래프
[STEP 5.2 블록]

---

## Phase 0-A · CI 부트스트랩
[CI-1, CI-2, CI-3 상세]

## Phase 0-B · CD 스테이징
[CI-4, CI-5, CI-6 상세]

## Phase 0-C · Walking Skeleton
[CI-7, CI-8, CI-9 상세]

## Phase 1 · Core MVP (P0 수직 슬라이스)
[CI-10 ~ CI-12 상세]

## Phase 2 · MVP 확장 (P1 + 엣지 케이스)
[CI-13 ~ CI-14 상세]

## Phase 3 · CD 프로덕션 + Security + Ops
[CI-15 ~ CI-20 상세]
```

---

## 형제 · 후속 스킬과의 연계

```
[TechSpec 작성]                            [이슈 생성]                          [등록]                            [관리]                       [구현]
write-techspec  ──────►  generate-issues-vertical (이 스킬)    ──►  register-issues-to-github  ──►  github-kanban  ──►  implement-top-issue
                   or    generate-issues-layered  (형제)        │       (CI-N → #실번호 2-pass)       (order:NNN 순서)      (우선순위 기반 픽업)
                                                                │                                                            │
                                                                └───► issues-vertical.md 파일 산출                            └──► (CI/CD 이슈 감지 시 ci-cd-pipeline 위임)
```

| 스킬 | 역할 | 본 스킬과의 관계 |
| :---- | :---- | :---- |
| `write-techspec` | TechSpec 작성 | **선행 입력** |
| `generate-issues-layered` | 계층별 분할 | **형제 대안** — `issues-layered.md` 생성. CI/CD-first 원칙을 Layer 0/1 에 적용한 v3.0 버전이 있음 |
| `register-issues-to-github` | GitHub 이슈 등록 + CI-N 치환 + 레이블 자동 생성 | **후속 필수** — 본 스킬은 `gh` 에 쓰지 않음 |
| `github-kanban` | Projects v2 보드 생성 + order:NNN 순서 배치 | **후속** — 등록 이후 |
| `implement-top-issue` v1.3 | 우선순위 기반 픽업 + 구현 + PR | **최종 소비자** — CI/CD 이슈 감지 시 하이브리드 모드 |
| `ci-cd-pipeline` | CI/CD 파이프라인 실제 구현 전담 | `implement-top-issue` 가 CI/CD 이슈에 한해 구현을 위임 |

---

## 충돌 방지 규칙

- 두 이슈 생성 스킬의 **슬래시 커맨드 · 스킬명 · 출력 파일명** 은 서로 겹치지 않는다.
- 이 스킬의 출력: **`issues-vertical.md`** (필수).
- 형제 스킬 출력: `issues-layered.md`.
- 두 전략을 섞어 쓰면 **두 파일이 공존** 하는 것이 정상. 한쪽이 다른 쪽을 덮어쓰지 않도록 파일명 가드.
- 동일 저장소 재실행 시 `issues-vertical-YYYY-MM-DD.md` 타임스탬프 접미사.
- GitHub 등록 후에는 `strategy:vertical-slice` / `strategy:layered` 공통 레이블로 시각 구분.
- 사용자가 "이슈 만들어줘" 같이 모호한 표현이면 두 전략을 비교해 선택을 먼저 받는다.

---

## 안전장치 (Safety Guards)

1. **GitHub 쓰기 금지**: `gh issue create`, `gh label create`, `gh api POST` 등 **모든 GitHub 쓰기 호출 금지**. 파일 생성만.
2. **파일명 가드**: `issues-layered.md` 로 저장하려 하면 즉시 차단.
3. **의존성 사이클 감지**: Kahn's 알고리즘으로 사이클 감지 시 중단, 어떤 이슈 간 사이클인지 보고.
4. **의존성 규칙 위반 감지**: 위의 의존성 규칙 1~5 를 위반하는 초안은 사용자에게 "규칙 위반" 경고.
5. **CI-N 임시 ID 유일성**: 동일 파일 내 CI-N 중복 금지. 삽입/삭제 시 자동 정렬.
6. **빈 AC 차단**: 모든 이슈는 AC 최소 1개 이상. 비어있으면 저장 전 중단.
7. **덮어쓰기 방지**: 기존 `issues-vertical.md` 있으면 A/B/C/D 옵션 제공.
8. **INVEST 미달 경고**: 2일 초과 크기 또는 AC 없음 또는 테스트 없음인 이슈에 경고.
9. **Dry-run**: `--dry-run` 인자 시 파일 저장 없이 구조만 출력.
10. **CI/CD-first 강제**: Phase 0-A / Phase 0-B 이슈가 0 개면 "TechSpec 에 배포 타겟 명시 필요" 오류.

---

## 실패 / 예외 처리

| 상황 | 대응 |
| :---- | :---- |
| TechSpec 부재 | `write-techspec` 선행 안내 |
| TechSpec 에 CD 타겟 미명시 | 사용자에게 후보(Vercel/Fly.io/Render/ECS/Cloudflare)를 제시하고 선택 받음 |
| TechSpec 에 유저 스토리 없음 | Phase 0 만 생성, Phase 1~2 는 "유저 스토리 보강 필요" 로 미완 |
| 의존성 사이클 | 어떤 두 이슈가 서로를 참조하는지 보고, 사용자 수정 요청 |
| 동일 파일 존재 | A/B/C/D 옵션 제공 |
| 사용자가 `issues-layered.md` 지정 | 즉시 차단, 형제 스킬 사용 안내 |
| 단순 "이슈 만들어줘" 발화 | 두 전략(수직 vs 계층) 비교 후 선택 받음 |
| CI-N 참조가 없는 이슈 생성 | "의존성 필드에 '없음' 으로라도 표기하세요" 재확인 |

---

## 사용 예시

- "수직 분할로 이슈 만들어줘" → `/generate-issues-vertical`
- "CI/CD 먼저 만드는 이슈로 뽑아줘" → `/generate-issues-vertical`
- "Walking Skeleton 부터 시작해서 MVP까지" → `/generate-issues-vertical`
- "techspec.md 읽어서 수직으로 쪼개줘" → `/generate-issues-vertical` + techspec.md 경로 전달

---

## 변경 이력 (Changelog)

| 버전 | 변경 내용 |
| :---- | :---- |
| **v3.0** (현재) | **CI/CD-first 재설계**. ① Phase 0-A(CI 부트스트랩), 0-B(CD 스테이징), 0-C(Walking Skeleton) 를 기능 이슈보다 먼저 강제. ② 모든 이슈에 `**Depends on**` + `**Required by**` 필드 필수. ③ 파일 상단에 위상 정렬 실행 순서 + 의존성 그래프 자동 생성(Kahn's). ④ `[CI]`/`[CD]`/`[Security]` 카테고리 레이블 신설. ⑤ 공통 레이블(`strategy:*`, `priority:p*`, `order:NNN`, `mandatory-gate`, `profile:*`) 도입 — github-kanban · implement-top-issue v1.3 완벽 호환. ⑥ GitHub 등록 **분리** — `register-issues-to-github` 로 위임, `gh` 쓰기 금지. ⑦ CI-N 임시 ID + 2-pass 치환 원칙. ⑧ 의존성 규칙 5종 + 사이클 감지 + INVEST 미달 경고. |
| v2.1 | 형제 스킬(`generate-issues-layered`)과 충돌 방지를 위한 출력 파일명 `issues-vertical.md` 고정. 분할 전략 구분 고지 의무화. |
| v2.0 | Walking Skeleton + Vertical Slice 철학 명시. Phase 0~3 구조. `[Skeleton]/[Slice]/[Ops]/[A11y]/[QA]/[Docs]` 레이블. |
| v1.0 | 최초 릴리스. TechSpec 기반 이슈 분할 + GitHub 이슈 등록 포함. |
