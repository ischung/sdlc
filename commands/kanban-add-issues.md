---
description: 현재 저장소의 이슈를 정렬 규칙에 따라 칸반 Todo 컬럼에 일괄 등록
argument-hint: [프로젝트 번호/URL (선택)]
---

`github-kanban-skill` 스킬을 Skill 도구로 실행하세요. **action=add-issues** — 이슈 전체를 정렬 규칙(Priority 필드 / `priority:p*` 레이블 / 이슈 번호)에 따라 Todo 컬럼에 일괄 등록합니다. 중복 방지 로직으로 안전하게 재실행 가능합니다.

대상 프로젝트: $ARGUMENTS
