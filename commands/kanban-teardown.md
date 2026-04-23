---
description: 칸반 보드 삭제 (파괴적 작업 — 반드시 opt-in 확인)
argument-hint: <프로젝트 번호/URL>
---

`github-kanban-skill` 스킬을 Skill 도구로 실행하세요. **action=teardown** — 칸반 보드를 삭제합니다. **파괴적 작업**이므로 다음을 반드시 준수하세요.

1. 대상 프로젝트의 요약(이름, 이슈 수, 커스텀 필드)을 먼저 출력.
2. 사용자로부터 A/B/C/D opt-in 확인을 받은 후에만 삭제 실행.
3. 이슈 자체는 삭제하지 말고 보드 연결만 해제.

대상 프로젝트: $ARGUMENTS
