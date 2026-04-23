---
description: 칸반 보드의 최우선 이슈 1건을 GitHub Flow로 자동 구현 → PR 생성
argument-hint: [보드/리포지토리 지정 (선택)]
---

`implement-top-issue` 스킬을 Skill 도구로 실행하세요. GitHub Projects 보드의 'Todo' 컬럼에서 우선순위 캐스케이드(Priority 필드 → `priority:p*` 레이블 → 보드 순서 → 이슈 번호)에 따라 **이슈 1건**을 픽업하여 브랜치 생성 → AC 기반 구현 → 로컬 빌드/린트/테스트(UI는 Playwright) → PR 생성(`Closes #N`) → 보드 상태 전이까지 수행합니다.

핵심 약속:
- **한 번에 1건만**. 이슈를 새로 만들지 않음.
- CI/CD 이슈는 `ci-cd-pipeline` 으로 위임(하이브리드 모드).
- 보드가 비었으면 즉시 중단하고 선행 스킬(`generate-issues-*` → `register-issues-to-github` → `github-kanban-skill`) 안내.

추가 컨텍스트: $ARGUMENTS
