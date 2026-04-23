---
description: TechSpec을 계층별 분할 + CI/CD-first 전략으로 쪼개 issues-layered.md 생성
argument-hint: [TechSpec 파일 경로 (선택)]
---

`generate-issues-layered` 스킬을 Skill 도구로 실행하세요. 기본은 `techspec.md` 를 입력으로 사용하며, Layer 0 (CI) → Layer 2 (CD) → Layer 3+ (DB/Backend/Frontend/…) 순서로 `issues-layered.md` 를 생성합니다.

추가 입력: $ARGUMENTS
