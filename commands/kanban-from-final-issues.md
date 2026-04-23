---
description: final-issues.md 의 order:NNN 레이블을 읽어 이슈를 실행 순서대로 보드에 배치
argument-hint: [final-issues.md 경로 (선택, 기본: ./final-issues.md)]
---

`github-kanban-skill` 스킬을 Skill 도구로 실행하세요. **action=from-final-issues** — `final-issues.md` 를 파싱해 `order:NNN` · `mandatory-gate` · `profile:staging/prod` 레이블을 인식하고 이슈를 실행 순서대로 Todo 컬럼에 배치합니다.

입력 파일: $ARGUMENTS
