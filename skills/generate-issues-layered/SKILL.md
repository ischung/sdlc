---
name: generate-issues-layered
description: >
  TechSpec(기술 명세서)을 **아키텍처 계층별 분할 + CI/CD-first** 전략으로 쪼개어
  `issues-layered.md` 파일로만 저장하는 스킬 (v3.0). v2.0 의 Setup→Infra→DB→Backend→
  Core Logic→Frontend→UI/UX→Test→Docs 순서를 유지하되, **Layer 0 (CI 부트스트랩)과
  Layer 2 (CD 스켈레톤)를 기능 계층 전면에 배치하여 CI/CD 파이프라인을 가능한 빨리
  구축하도록 재설계**한다. 각 이슈는 `**Depends on**: #N` 으로 명시적 의존성을 기재하고,
  파일 상단에 위상 정렬된 실행 순서 + 의존성 그래프를 자동 생성한다.
  ⚠️ **GitHub 등록은 수행하지 않는다.** 이 스킬은 파일 생성까지만 담당하고, 등록은
  후속 스킬 `register-issues-to-github` 에 위임한다. 보드 배치는 `github-kanban`,
  구현은 `implement-top-issue` 에 위임한다. 공통 레이블 체계(`priority:p0~p3`,
  `mandatory-gate`, `order:NNN`, `profile:staging/prod`, `strategy:layered`) 를
  준수하여 후속 스킬과 완벽히 호환된다.
  사용자가 "계층별 이슈 만들어줘", "레이어별 분할", "DB→Backend→Frontend 순서",
  "수평 분할", "아키텍처 계층별", "백엔드/프런트 분리 작업", "CI/CD 먼저인 계층 분할",
  "/generate-issues-layered", "/layered-issues" 중 하나라도 언급하면 반드시 이 스킬을
  사용할 것. 수직 분할(Walking Skeleton + Vertical Slice) 방식을 원하면
  `generate-issues-vertical` 스킬을 사용한다. 모호하면 두 전략을 2~3줄로 비교해
  선택을 받는다.
---

# 이슈 생성 스킬 — 계층별 분할(Layered) + CI/CD-first v3.0

TechSpec 을 **아키텍처 계층 순서** 로 이슈화하되, v2.0 과 달리 **Layer 0 (CI) 과 Layer 2 (CD 스켈레톤) 를 가장 앞에 배치**하여 기능 계층 이슈들이 모두 초록불 파이프라인 위에서 구현되도록 강제한다. 결과는 `issues-layered.md` 파일로만 저장하며, **GitHub 등록은 이 스킬의 책임이 아니다.**

---

## v3.0 핵심 변화 (vs v2.0)

| 구분 | v2.0 | **v3.0 (이 문서)** |
| :---- | :---- | :---- |
| CI/CD 순서 | Layer 2 "[Infra]" 에 뭉뚱그려 포함 | **Layer 0 (CI 부트스트랩) + Layer 2 (CD 스테이징 스켈레톤)** 으로 분리 + 최상단 배치 |
| 기능 계층 시작 | Layer 3 (DB) — CI/CD 가 아직 없을 수 있음 | **Layer 3 (DB) 는 Layer 2 (CD 스테이징) 완료 이후에만 시작** 강제 |
| 의존성 표현 | 주로 "없음" 또는 "Depends on #N" 산발적 | **모든 이슈에 `**Depends on**` 필드 + 파일 상단 위상 정렬 블록** |
| GitHub 등록 | v2.0 부터 이미 분리 (유지) | **유지** — `register-issues-to-github` 로 위임 |
| 레이블 체계 | `[Setup]/[Infra]/[DB]/…` | **`[CI]/[CD]` 추가 + 공통 레이블(`priority:p*`, `mandatory-gate`, `order:NNN`, `profile:*`, `strategy:layered`)** |
| CD 단계 | Layer 2 의 "CI/CD" 1건으로 뭉침 | **Layer 2 (스테이징 스켈레톤) + Layer 9 (프로덕션 배포) 두 단계로 분리** |
| 후속 스킬 호환 | 부분 | **github-kanban · implement-top-issue v1.3 와 완벽 호환** |
| CI-N 임시 ID | 없음 | **`CI-1`, `CI-2`, …로 임시 ID 부여 → register 단계에서 2-pass 치환** |

---

## 슬래시 커맨드

| 커맨드 | 설명 |
| :---- | :---- |
| `/generate-issues-layered` | TechSpec → `issues-layered.md` (CI/CD-first 계층별 분할) |
| `/layered-issues` | 축약형 별칭 |
| `/generate-issues` | 하위 호환 별칭 (v1.0) |

이 스킬은 **GitHub 저장소를 건드리지 않는다**. 산출물은 오로지 `issues-layered.md` 이며, 완료 후 사용자에게 "GitHub 에 등록하려면 `register-issues-to-github` 스킬을 실행하세요" 라고 안내만 한다.

---

## 형제 스킬과의 구분

| 스킬 | 분할 방식 | 출력 파일 |
| :---- | :---- | :---- |
| **generate-issues-layered** (이 스킬) | Architecture Layer + CI/CD-first (Layer 0→Layer 10) | `issues-layered.md` |
| **generate-issues-vertical** (형제) | Walking Skeleton + Vertical Slice + CI/CD-first (Phase 0-A → Phase 3) | `issues-vertical.md` |
| **register-issues-to-github** (후속 공통) | 위 파일 중 하나를 GitHub 이슈로 등록 (CI-N → #실번호 2-pass 치환) | GitHub Issues |

**언제 이 스킬을 선택해야 하는가**

| 상황 | 이 스킬(계층) | 형제 스킬(수직) |
| :---- | :---- | :---- |
| 레거시 리팩터링처럼 레이어 단위 작업이 자연스러운 경우 | ✅ | ❌ |
| 백엔드/프런트 팀이 분리되어 **병렬** 작업이 목적인 경우 | ✅ | ❌ |
| 데이터 모델이 거의 확정되어 DB 선행 작업이 합리적인 경우 | ✅ | ❌ |
| 아직 배포 파이프라인조차 없는 신규 프로젝트 — **조기 배포가 가치인 경우** | ❌ | ✅ |
| 유저 스토리가 명확한 MVP/프로토타입 | ❌ | ✅ |

모호하면 사용자에게 이 표를 보여주고 선택을 받는다.

---

## 핵심 철학 — Pipeline Layer → Data Layer → Service Layer → Presentation Layer → Ops Layer

```
 Layer 0  ┌──────────────────────────────────────────┐
          │  CI Bootstrap — lint + test on PR        │   ← 기능 이슈 이전에 완성
          └──────────────────────────────────────────┘
                           │
 Layer 1  ┌──────────────────────────────────────────┐
          │  Setup — 저장소, 패키지, 컨벤션           │
          └──────────────────────────────────────────┘
                           │
 Layer 2  ┌──────────────────────────────────────────┐
          │  CD Staging Skeleton (Deploy Pipeline)    │   ← 이 이후에만 기능 계층 시작 가능
          │  · 스테이징 환경 + 자동 배포 + smoke       │
          └──────────────────────────────────────────┘
                           │  (이 선 아래부터 기능 계층)
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                           │
 Layer 3  ┌─── Data Layer ──────────────────────────┐
          │  DB 스키마 · 마이그레이션 · 시드          │
          └──────────────────────────────────────────┘
                           │
 Layer 4  ┌─── Service Layer ──────────────────────┐
          │  Backend API 엔드포인트                  │
          └──────────────────────────────────────────┘
                           │
 Layer 5  ┌─── Domain Layer ───────────────────────┐
          │  Core Logic · 유스케이스 · 정책         │
          └──────────────────────────────────────────┘
                           │
 Layer 6  ┌─── Presentation Layer ─────────────────┐
          │  Frontend 컴포넌트 · 페이지 · 상태관리  │
          └──────────────────────────────────────────┘
                           │
 Layer 7  ┌─── Styling Layer ──────────────────────┐
          │  UI/UX · 반응형 · 접근성 · 인터랙션     │
          └──────────────────────────────────────────┘
                           │
 Layer 8  ┌─── Quality Layer ──────────────────────┐
          │  Test 확장 — 단위/통합/E2E              │
          └──────────────────────────────────────────┘
                           │
 Layer 9  ┌──────────────────────────────────────────┐
          │  CD Production + Security Gates           │   ← 프로덕션 배포 파이프라인
          └──────────────────────────────────────────┘
                           │
 Layer 10 ┌──────────────────────────────────────────┐
          │  Ops — 모니터링 · 알람 · 런북             │
          └──────────────────────────────────────────┘
                           │
 Layer 11 ┌──────────────────────────────────────────┐
          │  Docs — API 레퍼런스 · 사용자 문서        │
          └──────────────────────────────────────────┘
```

**핵심 전환**: v2.0 은 Setup(1) → **Infra(2)** → DB(3) 순서로 CI/CD 를 Infra 라는 한 덩어리에 묶었지만, v3.0 은 **CI 부트스트랩을 최상단(Layer 0) 으로 분리**하고 **CD 를 스테이징(Layer 2) / 프로덕션(Layer 9) 두 번으로 분할**한다. 이렇게 하면 Layer 3 (DB) 이 시작되는 시점에는 이미 PR → CI → 스테이징 배포까지 모든 안전망이 돌고 있다.

---

## 행동 원칙

1. **CI/CD First (신규)**: Layer 0 (CI) → Layer 1 (Setup) → Layer 2 (CD 스테이징) 완료 전까지 Layer 3 이상의 기능 계층 이슈는 착수 불가 (의존성으로 강제).
2. **단일 책임**: 이 스킬은 파일 생성까지만. `gh issue create`, `gh label create`, GitHub Projects 호출 절대 금지.
3. **명시적 의존성 (신규)**: 모든 이슈는 `**Depends on**` 필드를 가진다. 의존성이 없으면 "없음" 이라고 명시. 파일 상단에 **위상 정렬된 실행 순서 + 의존성 그래프** 자동 생성.
4. **INVEST 준수**: 모든 이슈는 INVEST 6요건을 충족.
5. **CoT 분석**: 이슈 설계 전 TechSpec 분석 결과(계층, 도메인, 의존성, 기술 스택, CD 타겟) 를 먼저 요약.
6. **논리적 순서**: Layer 0 → Layer 1 → Layer 2 → Layer 3 → … → Layer 11 (기능 계층은 Layer 2 이후).
7. **Incremental validation**: 목록 초안을 사용자에게 먼저 보여주고 승인 후 상세화.
8. **YAGNI**: TechSpec 에 없는 작업은 이슈로 만들지 않는다.
9. **CI-N 임시 ID (신규)**: 파일 내부에서는 `#CI-1`, `#CI-2`, … 형태의 임시 ID로 의존성을 기재. 실제 GitHub 번호는 `register-issues-to-github` 가 2-pass 치환.
10. **구분 고지**: 실행 초기에 "계층별 분할 + CI/CD-first, `issues-layered.md` 저장, 수직 분할은 `/generate-issues-vertical`" 한 줄.
11. **파일 경로 안전성**: 이미 `issues-layered.md` 가 있으면 덮어쓰기 전에 A/B/C/D 확인.

---

## AI 시스템 프롬프트 — `/generate-issues-layered`

당신은 숙련된 DevOps + 소프트웨어 엔지니어입니다. 제공된 TechSpec 을 계층별로 분석하되, **CI 부트스트랩(Layer 0) 과 CD 스테이징 스켈레톤(Layer 2) 을 기능 계층(Layer 3~) 의 필수 선행 조건으로 강제**해 INVEST 원칙에 맞는 이슈 목록을 설계하고, 결과를 `issues-layered.md` 로 저장합니다. **GitHub 등록은 수행하지 않습니다.**

---

## 워크플로우

### STEP 0 — 구분 고지 + 전략 재확인

최초 응답 한 줄:

> "계층별(Layered) 분할 + CI/CD-first 방식으로 이슈를 생성하며 결과는 `issues-layered.md` 에 저장합니다. Layer 0 (CI) → Layer 1 (Setup) → Layer 2 (CD 스테이징) → Layer 3 이후 (DB/Backend/Frontend/…) 순서입니다. 수직 분할을 원하시면 `/generate-issues-vertical` (→ `issues-vertical.md`) 를 사용해주세요. **이 스킬은 파일 생성까지만 수행하며, GitHub 등록은 `register-issues-to-github` 에 위임합니다.**"

### STEP 1 — TechSpec 수집

"이슈 생성을 시작합니다. 분석할 TechSpec 파일을 알려주세요.

- A) 파일 경로 입력 (예: `techspec.md`)
- B) 방금 작성한 TechSpec 을 바로 사용할게요
- C) TechSpec 이 아직 없어요 → `write-techspec` 스킬을 먼저 실행해주세요"

### STEP 2 — 계층 + 기술 스택 + CD 타겟 분석 (CoT)

```
TechSpec 분석 결과:

 🔍 프로젝트 도메인   : [요약]
 🧱 핵심 엔티티 (DB)   : [Entity A, B, C]
 🧠 주요 API 영역      : [/auth, /posts, /search, …]
 🎨 프런트엔드 화면    : [Home, Detail, Admin, …]
 🔗 관통 의존성        : Auth → Post, Search → Post, …
 🌐 Cross-cutting      : 로깅 · 관측성 · 접근성 · 테스트 · 문서
 🛠️ 기술 스택
    · Frontend : [Next.js / React / Vue / …]
    · Backend  : [Node/Express, Python/FastAPI, Go, …]
    · DB       : [PostgreSQL / MySQL / DynamoDB / …]
    · CI       : GitHub Actions
    · CD 타겟   : [Vercel / Fly.io / Render / AWS ECS / Cloudflare / …]
 🛡️ 필수 게이트       : lint, unit-test, SAST, dependency-audit, E2E-smoke

CI/CD-first 계층 설계안:
  Layer 0  : CI 부트스트랩 (lint + test on PR)
  Layer 1  : Setup (저장소, 패키지, 컨벤션)
  Layer 2  : CD 스테이징 스켈레톤 (자동 배포 + smoke)
  ──────────────────────── 여기까지가 기능 이슈의 선행 조건 ────────────────────────
  Layer 3  : Data Layer (DB 스키마 · 마이그레이션)
  Layer 4  : Service Layer (Backend API)
  Layer 5  : Domain Layer (Core Logic)
  Layer 6  : Presentation Layer (Frontend)
  Layer 7  : Styling Layer (UI/UX)
  Layer 8  : Quality Layer (Test 확장)
  Layer 9  : CD Production + Security Gates
  Layer 10 : Ops (모니터링 · 알람)
  Layer 11 : Docs

이대로 진행할까요?
  A) 네, 진행해주세요
  B) 계층 구성 / CD 타겟 / 엔티티 목록을 수정하고 싶어요
  C) 수직 분할이 더 적절할 것 같아요 → /generate-issues-vertical 로 전환
```

### STEP 3 — 이슈 목록 초안 (의존성 포함 표)

승인 후 Layer 별로 **의존성을 CI-N 임시 ID 로 명시**하여 초안 제시.

```
이슈 [N]개를 CI/CD-first 계층별 분할로 설계했어요:

【 Layer 0 · CI 부트스트랩 】
| 임시ID | 레이블             | 제목                                         | 의존성 | 우선순위 | 예상 |
| :----- | :----------------- | :------------------------------------------- | :----- | :------- | :--- |
| CI-1   | [CI]               | 저장소 초기화 + lint/format + pre-commit      | 없음   | P0       | 0.5일 |
| CI-2   | [CI]               | GitHub Actions 기본 워크플로 (lint + test)    | #CI-1  | P0       | 0.5일 |
| CI-3   | [CI] mandatory-gate| PR 보호 규칙 + 상태 배지                       | #CI-2  | P0       | 0.5일 |

【 Layer 1 · Setup 】
| CI-4   | [Setup]            | 공통 라이브러리 · 컨벤션 · pre-commit 확장      | #CI-1  | P0       | 0.5일 |

【 Layer 2 · CD 스테이징 스켈레톤 】
| CI-5   | [CD] profile:staging             | 스테이징 환경 준비 (시크릿/ENV/DB 인스턴스) | #CI-2       | P0 | 1일  |
| CI-6   | [CD] profile:staging             | main 머지 → 스테이징 자동 배포 워크플로      | #CI-5       | P0 | 1일  |
| CI-7   | [CD] profile:staging mandatory-gate | 배포 후 smoke test 자동 수행             | #CI-6       | P0 | 0.5일 |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ↑ 여기까지가 기능 계층 시작의 필수 선행 조건 (#CI-7 통과 이후)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【 Layer 3 · Data (DB) 】
| CI-8   | [DB]               | User 모델 + 마이그레이션                 | #CI-7  | P1 | 0.5일 |
| CI-9   | [DB]               | Post 모델 + 관계 설정                   | #CI-8  | P1 | 0.5일 |

【 Layer 4 · Service (Backend) 】
| CI-10  | [Backend]          | /auth 엔드포인트                        | #CI-8  | P1 | 1일  |
| CI-11  | [Backend]          | /posts 엔드포인트                       | #CI-9  | P1 | 1일  |
| CI-12  | [Backend]          | /search 엔드포인트                      | #CI-11 | P2 | 1일  |

【 Layer 5 · Domain (Core Logic) 】
| CI-13  | [Core Logic]       | 권한 정책 + 유스케이스                   | #CI-10 | P1 | 1일  |

【 Layer 6 · Presentation (Frontend) 】
| CI-14  | [Frontend]         | 로그인 화면 + 상태관리                   | #CI-10 | P1 | 1일  |
| CI-15  | [Frontend]         | 목록/상세 화면 + 데이터 바인딩           | #CI-11 | P1 | 1.5일|

【 Layer 7 · Styling (UI/UX) 】
| CI-16  | [UI/UX]            | 반응형 + 접근성 기본                     | #CI-15 | P2 | 1일  |

【 Layer 8 · Quality (Test) 】
| CI-17  | [Test]             | 단위/통합 테스트 확장                    | #CI-13, #CI-15 | P2 | 1일 |
| CI-18  | [Test]             | E2E 스모크 시나리오 추가                 | #CI-17 | P2 | 1일  |

【 Layer 9 · CD Production + Security 】
| CI-19  | [CD] profile:prod mandatory-gate | 프로덕션 배포 파이프라인 + 수동 승인 | #CI-7, #CI-18 | P0 | 1일 |
| CI-20  | [Security] mandatory-gate        | SAST + 의존성 취약점 스캔 주기 실행   | #CI-2         | P0 | 0.5일 |

【 Layer 10 · Ops 】
| CI-21  | [Ops]              | 에러 모니터링(APM/Sentry) + 알람         | #CI-19 | P1 | 0.5일 |

【 Layer 11 · Docs 】
| CI-22  | [Docs]             | API 레퍼런스 + 운영 런북                 | #CI-19 | P2 | 0.5일 |

총합: [N]개, 예상 [합산]일

이 목록으로 issues-layered.md 를 생성할까요?
  A) 네, 생성해주세요
  B) 일부 수정/추가/삭제 (구체적 항목 지정)
  C) 파일명을 바꾸고 싶어요 (단, issues-vertical.md 는 사용 불가)
```

### STEP 4 — 상세 이슈 작성

각 이슈를 아래 템플릿으로 기록한다.

```markdown
## #CI-[N] [레이블] 제목

**레이블**     : [CI / CD / Setup / DB / Backend / Core Logic / Frontend / UI/UX / Test / Security / Ops / Docs]
**공통 레이블** : strategy:layered, priority:p[0~3], order:NNN[, mandatory-gate][, profile:staging|prod]
**Layer**      : [0 CI / 1 Setup / 2 CD Staging / 3 Data / 4 Service / 5 Domain / 6 Presentation / 7 Styling / 8 Quality / 9 CD Production / 10 Ops / 11 Docs]
**예상 소요**   : [X일]
**Depends on** : [없음 / #CI-M, #CI-K]
**Required by**: [#CI-A, #CI-B / 없음]   ← 역참조 (자동 채움)
**분할 전략**   : Architecture Layer + CI/CD-first
**출력 파일**   : `issues-layered.md`

### 설명
[현재 상태 또는 배경 — 왜 필요한지]
[구현 내용 — 데이터 흐름, 연관 컴포넌트, API 접점 포함]

### 수락 기준 (Acceptance Criteria)
- [ ] [검증 가능한 조건 1]
- [ ] [검증 가능한 조건 2]
- [ ] [테스트 커버리지 조건]
- [ ] CI 파이프라인이 초록불로 통과한다
- [ ] (Layer 3 이상이면) 스테이징 URL 에서 변경이 확인 가능하다

### 참고
- TechSpec 섹션 : [§번호]
- 관련 이슈     : [없음 / #CI-N]
```

### STEP 5 — 위상 정렬 + 의존성 그래프 자동 생성

#### 5.1 위상 정렬된 실행 순서

Kahn's 알고리즘으로 위상 정렬하여 `order:NNN` 을 부여한다. 사이클 감지 시 중단, 어느 이슈들이 순환하는지 보고.

```
## 📜 권장 실행 순서 (위상 정렬)

| order | 임시ID | Layer   | 레이블             | 제목                                         |
| :---- | :---- | :------ | :----------------- | :------------------------------------------- |
| 001   | CI-1  | 0       | [CI]               | 저장소 초기화 + lint/format                   |
| 002   | CI-2  | 0       | [CI]               | GitHub Actions 기본 워크플로                  |
| 003   | CI-3  | 0       | [CI] mandatory-gate| PR 보호 규칙                                  |
| 004   | CI-4  | 1       | [Setup]            | 공통 라이브러리 · 컨벤션                       |
| 005   | CI-5  | 2       | [CD] profile:staging | 스테이징 환경 준비                          |
| 006   | CI-6  | 2       | [CD] profile:staging | 자동 배포 워크플로                          |
| 007   | CI-7  | 2       | [CD] profile:staging mandatory-gate | smoke test                   |
| 008   | CI-8  | 3       | [DB]               | User 모델                                     |
| …     | …     | …       | …                  | …                                             |
```

#### 5.2 의존성 그래프 (ASCII)

```
## 🔗 의존성 그래프

CI-1 ──► CI-2 ──► CI-3
      └► CI-4                                                   (Setup 병렬)
              └► CI-5 ──► CI-6 ──► CI-7 ══►  ← 이 선 이후만 기능 계층
                                          │
                                          ├► CI-8 ──► CI-9 ──► CI-11 ──► CI-12
                                          │       └► CI-10 ──► CI-13 ──► CI-17 ──► CI-18 ──► CI-19
                                          │               └► CI-14
                                          │               └► CI-15 ──► CI-16
                                          │                       └► CI-17
                                          └► CI-20 (Security 병렬)

CI-19 ──► CI-21, CI-22
```

### STEP 6 — 파일 저장

```
저장 전 체크리스트
 [1] 파일명이 issues-layered.md 인가? (사용자 지정이 있으면 그 이름)
 [2] issues-vertical.md 로 저장하지 않는가?
 [3] 같은 경로에 기존 파일이 있는가?
     · A) 덮어쓰기
     · B) 타임스탬프 백업 후 덮어쓰기 (issues-layered.backup-YYYYMMDD-HHMMSS.md)
     · C) 다른 이름으로 저장 (issues-layered-v2.md)
     · D) 취소
 [4] 상단 헤더에 분할 전략 · 생성 스킬명 · Layer별 이슈 수 · 위상 정렬 블록 · 의존성 그래프 포함
 [5] 모든 이슈에 **Depends on** 필드가 존재하는가?
 [6] 의존성 사이클이 없는가?
 [7] Layer 3 이상의 이슈가 Layer 2 의 CI-7(smoke) 을 직·간접 의존하는가? (강제 규칙)
```

### STEP 7 — 완료 메시지 (GitHub 등록 안내 + 후속 스킬 체인)

```
✅ issues-layered.md 저장 완료!

📋 총 이슈   : [N]개 ([합산]일)
📁 위치     : <절대 경로>
🧭 전략     : Layered + CI/CD-first
🔗 의존성   : [K]개 간선, 사이클 없음
⚡ 가장 빠른 CI/CD 도달 시각: CI-1 → CI-7 (스테이징 smoke 통과) 까지 [누적 X일]

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
| `[CI]` | CI 워크플로 구축 (lint / test / build) — **Layer 0** |
| `[CD]` | CD 워크플로 구축 (배포 / 승인 / 롤백) — **Layer 2, 9** |
| `[Setup]` | 저장소 · 패키지 매니저 · 컨벤션 — **Layer 1** |
| `[DB]` | 스키마 · 마이그레이션 · 시드 · 인덱스 — **Layer 3** |
| `[Backend]` | API 엔드포인트 — **Layer 4** |
| `[Core Logic]` | 도메인 로직 · 유스케이스 · 정책 — **Layer 5** |
| `[Frontend]` | 컴포넌트 · 페이지 · 상태관리 — **Layer 6** |
| `[UI/UX]` | 스타일 · 반응형 · 접근성 · 인터랙션 — **Layer 7** |
| `[Test]` | 단위 / 통합 / E2E 테스트 확장 — **Layer 8** |
| `[Security]` | SAST · 의존성 스캔 · 시크릿 검사 — **Layer 9** |
| `[Ops]` | 모니터링 · 알람 — **Layer 10** |
| `[Docs]` | API 레퍼런스 · 운영 런북 · 사용자 문서 — **Layer 11** |

> v2.0 의 `[Infra]` 레이블은 `[CI]` / `[CD]` 로 세분화되며 **더 이상 사용하지 않는다**. register-issues-to-github 가 기존 `[Infra]` 부여 이슈를 발견하면 경고를 표시한다.

### 공통 레이블 (모든 이슈 공통, 후속 스킬이 소비)

| 레이블 | 값 | 소비자 |
| :---- | :---- | :---- |
| `strategy:layered` | 고정 | 전략 구분 — register-issues-to-github, github-kanban |
| `priority:p0` ~ `priority:p3` | P0=최우선 | implement-top-issue 의 픽업 캐스케이드 |
| `order:NNN` | 001~999 | github-kanban 의 보드 배치 순서 |
| `mandatory-gate` | 부여 여부 | github-kanban 의 자동 Priority=P0, implement-top-issue 의 위임 판정 |
| `profile:staging` / `profile:prod` | 택일 | github-kanban 의 Sprint=Deploy, ci-cd-pipeline 의 타겟 |
| `layer-0-ci` / `layer-1-setup` / `layer-2-cd-staging` / … / `layer-11-docs` | 단일 | Layer 필터 |

### 레이블 자동 부여 규칙 (v3.0)

1. **`mandatory-gate`** 는 다음 중 하나라도 해당하면 자동 부여:
   - Layer 0 `[CI]` 중 PR 보호 규칙 / 상태 배지 이슈
   - Layer 2 `[CD]` 중 smoke test
   - Layer 9 `[CD] profile:prod` 및 `[Security]` 전체
   - Layer 8 `[Test]` 중 "블로킹 E2E"
2. **`priority:p0`** 는 Layer 0, Layer 2, Layer 9 의 모든 이슈 + `mandatory-gate` 이슈
3. **`profile:staging`** 은 Layer 2, **`profile:prod`** 은 Layer 9 의 프로덕션 배포 이슈
4. **`order:NNN`** 은 STEP 5 위상 정렬 결과

---

## 의존성 규칙 (v3.0 강제)

1. **CI-1 (저장소 초기화)** 은 의존성 없음. 유일한 "없음" 허용 이슈.
2. **모든 Layer 1 [Setup]** 은 CI-1 에 의존.
3. **모든 Layer 2 [CD] profile:staging** 은 Layer 0 의 CI 워크플로 이슈에 의존.
4. **모든 Layer 3 [DB]** 는 **Layer 2 의 CD 스테이징 smoke test 이슈(CI-7 등)** 에 직·간접 의존 — 이것이 CI/CD-first 의 핵심 강제 조건.
5. **Layer 4 [Backend]** 는 최소 하나의 Layer 3 [DB] 에 의존.
6. **Layer 5 [Core Logic]** 는 최소 하나의 Layer 4 [Backend] 에 의존.
7. **Layer 6 [Frontend]** 는 최소 하나의 Layer 4 [Backend] 에 의존.
8. **Layer 7 [UI/UX]** 는 최소 하나의 Layer 6 [Frontend] 에 의존.
9. **Layer 8 [Test]** 는 테스트 대상 계층의 최소 하나에 의존.
10. **Layer 9 [CD] profile:prod** 는 Layer 2 CD 스테이징 + Layer 8 E2E 스모크에 의존.
11. **Layer 10 [Ops]** 는 Layer 9 [CD] profile:prod 에 의존.
12. **Layer 11 [Docs]** 는 Layer 9 에 의존.
13. **사이클 금지** — Kahn's 알고리즘으로 감지되면 STEP 5 에서 중단.

위 규칙 중 4번이 **CI/CD-first 원칙의 핵심**이다: **어떤 기능 계층 이슈도 스테이징 배포가 작동하기 전에는 시작될 수 없다.**

---

## `issues-layered.md` 출력 형식

```markdown
# Issues — [프로젝트명] (Layered + CI/CD-first)

> **원본 TechSpec** : [techspec.md 경로]
> **생성일**         : [YYYY-MM-DD]
> **분할 전략**     : Architecture Layer + CI/CD-first (Layer 0 → Layer 11)
> **생성 스킬**     : `generate-issues-layered` v3.0
> **출력 파일**     : `issues-layered.md`
> **형제 파일(참고)**: `issues-vertical.md` — 수직 분할 결과 전용
> **총 이슈 수**     : [N]개
> **Layer 구성**     : L0 [n] · L1 [n] · L2 [n] · L3 [n] · L4 [n] · L5 [n] · L6 [n] · L7 [n] · L8 [n] · L9 [n] · L10 [n] · L11 [n]
> **총 예상 소요**   : [합산 일수]일
> **의존성 간선 수** : [K], 사이클 없음
> **가장 빠른 CI/CD 도달**: CI-1 → … → CI-7 (스테이징 smoke 통과) = 누적 [X]일

---

## 📜 권장 실행 순서 (위상 정렬)
[STEP 5.1 블록]

## 🔗 의존성 그래프
[STEP 5.2 블록]

---

## Layer 0 · CI 부트스트랩
[CI-1, CI-2, CI-3 상세]

## Layer 1 · Setup
[CI-4 상세]

## Layer 2 · CD 스테이징 스켈레톤
[CI-5, CI-6, CI-7 상세]

## ──────── 기능 계층 시작 (Layer 2 완료 이후) ────────

## Layer 3 · Data (DB)
[CI-8, CI-9 상세]

## Layer 4 · Service (Backend)
[CI-10 ~ CI-12 상세]

## Layer 5 · Domain (Core Logic)
[CI-13 상세]

## Layer 6 · Presentation (Frontend)
[CI-14, CI-15 상세]

## Layer 7 · Styling (UI/UX)
[CI-16 상세]

## Layer 8 · Quality (Test)
[CI-17, CI-18 상세]

## Layer 9 · CD Production + Security
[CI-19, CI-20 상세]

## Layer 10 · Ops
[CI-21 상세]

## Layer 11 · Docs
[CI-22 상세]
```

---

## 형제 · 후속 스킬과의 연계

```
[TechSpec 작성]                         [이슈 생성]                          [등록]                            [관리]                      [구현]
write-techspec  ─►  generate-issues-layered (이 스킬)    ──►  register-issues-to-github  ──►  github-kanban  ──►  implement-top-issue
                or  generate-issues-vertical (형제)       │      (CI-N → #실번호 2-pass)        (order:NNN 순서)     (우선순위 기반 픽업)
                                                          │                                                           │
                                                          └───► issues-layered.md 파일 산출                            └─► (CI/CD 이슈 감지 시 ci-cd-pipeline 위임)
```

| 스킬 | 역할 | 본 스킬과의 관계 |
| :---- | :---- | :---- |
| `write-techspec` | TechSpec 작성 | **선행 입력** |
| `generate-issues-vertical` | 수직 분할 | **형제 대안** — `issues-vertical.md` 생성 |
| `register-issues-to-github` | GitHub 이슈 등록 + CI-N 치환 + 레이블 자동 생성 | **후속 필수** — 본 스킬은 `gh` 에 쓰지 않음 |
| `github-kanban` | Projects v2 보드 생성 + order:NNN 순서 배치 | **후속** — 등록 이후 |
| `implement-top-issue` v1.3 | 우선순위 기반 픽업 + 구현 + PR | **최종 소비자** — CI/CD 이슈 감지 시 하이브리드 모드 |
| `ci-cd-pipeline` | CI/CD 파이프라인 실제 구현 전담 | `implement-top-issue` 가 CI/CD 이슈에 한해 구현을 위임 |

---

## 안전장치 (Safety Guards)

1. **GitHub 쓰기 금지**: `gh issue create`, `gh label create`, `gh api POST` 등 모든 GitHub 쓰기 호출 금지.
2. **파일명 가드**: `issues-vertical.md` 로 저장하려 하면 즉시 차단.
3. **의존성 사이클 감지**: Kahn's 알고리즘으로 사이클 감지 시 중단.
4. **CI/CD-first 강제**: Layer 3 이상의 이슈 중 Layer 2 의 CI-7(smoke) 을 직·간접 의존하지 않는 이슈가 있으면 경고 + 의존성 자동 추가 제안.
5. **Layer 역행 금지**: 상위 Layer 의 이슈가 하위 Layer 의 이슈에 의존하는 것만 허용. 역방향(예: Layer 3 이 Layer 5 에 의존) 은 경고.
6. **CI-N 임시 ID 유일성**: 동일 파일 내 CI-N 중복 금지.
7. **빈 AC 차단**: 모든 이슈는 AC 최소 1개 이상.
8. **덮어쓰기 방지**: 기존 `issues-layered.md` 있으면 A/B/C/D 옵션 제공.
9. **INVEST 미달 경고**: 2일 초과 크기 또는 AC 없음 또는 테스트 없음인 이슈에 경고.
10. **Dry-run**: `--dry-run` 인자 시 파일 저장 없이 구조만 출력.
11. **`[Infra]` 레거시 감지**: v2.0 의 `[Infra]` 레이블을 발견하면 `[CI]` / `[CD]` 로 분해 제안.

---

## 실패 / 예외 처리

| 상황 | 대응 |
| :---- | :---- |
| TechSpec 부재 | `write-techspec` 선행 안내 |
| TechSpec 에 CD 타겟 미명시 | 사용자에게 후보 제시 + 선택 받음 |
| 의존성 사이클 | 사용자에게 순환 이슈 보고 |
| Layer 3 이슈가 CI-7 무의존 | 자동 의존성 추가 제안 (사용자 승인 후 적용) |
| Layer 역행 의존 | 경고 + 사용자 확인 |
| 동일 파일 존재 | A/B/C/D 옵션 |
| 사용자가 `issues-vertical.md` 지정 | 즉시 차단, 형제 스킬 사용 안내 |
| 단순 "이슈 만들어줘" | 두 전략(수직 vs 계층) 비교 후 선택 |
| v2.0 `[Infra]` 레이블 발견 | `[CI]` / `[CD]` 로 분해 제안 |

---

## 사용 예시

- "계층별 이슈 만들어줘" → `/generate-issues-layered`
- "레이어별 분할로, CI/CD 먼저인 순서로" → `/generate-issues-layered`
- "백엔드 팀이 병렬로 쓸 수 있게" → `/generate-issues-layered`
- "techspec.md 읽어서 계층으로 쪼개줘" → `/generate-issues-layered` + techspec.md 경로

---

## 변경 이력 (Changelog)

| 버전 | 변경 내용 |
| :---- | :---- |
| **v3.0** (현재) | **CI/CD-first 재설계**. ① Layer 0 (CI 부트스트랩) 최상단 신설 — v2.0 의 `[Infra]` 를 `[CI]` / `[CD]` 로 분해. ② Layer 2 (CD 스테이징 스켈레톤) 신설 — 기능 계층 시작 전 필수 선행 조건. ③ Layer 9 (CD Production + Security) 신설 — 프로덕션 배포와 보안 게이트 분리. ④ 모든 이슈에 `**Depends on**` + `**Required by**` 필수. ⑤ 파일 상단에 위상 정렬 실행 순서 + 의존성 그래프 자동 생성(Kahn's). ⑥ CI/CD-first 강제 규칙 — Layer 3+ 모든 이슈는 Layer 2 smoke 에 직·간접 의존 필수. ⑦ 공통 레이블(`strategy:*`, `priority:p*`, `order:NNN`, `mandatory-gate`, `profile:*`) 도입 — github-kanban · implement-top-issue v1.3 완벽 호환. ⑧ CI-N 임시 ID + 2-pass 치환 원칙. ⑨ Layer 역행 의존 경고 + INVEST 미달 경고. |
| v2.0 | 파일 생성까지로 단일 책임 축소 (GitHub 등록 제거). `register-issues-to-github` 로 분리. `issues-layered.md` 출력 파일명 고정. |
| v1.0 | 최초 릴리스. TechSpec 기반 계층별 이슈 분할 + GitHub 이슈 등록 포함. |
