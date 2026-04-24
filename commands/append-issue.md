---
description: 프로젝트 도중 새 이슈(버그/기능/운영)를 파일 → GitHub → 보드에 한번에 반영
argument-hint: [--type bug|feature|...] [--title "..."] [--priority P0-P3]
---

`append-issue` 스킬을 Skill 도구로 실행하세요. 프로젝트 진행 중 새로 발생한 이슈를 이슈 마크다운 파일에 표준 블록으로 append 하고, 곧바로 `register-issues-to-github` (STEP 9 보드 반영 포함) 까지 체인 실행합니다.

이슈 우선(Ticket-first) 원칙: **이슈 없이 구현 시작 금지.** 구현 요청 전에 이 커맨드를 먼저 실행하세요.

추가 컨텍스트: $ARGUMENTS
