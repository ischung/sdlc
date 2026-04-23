---
description: CI/CD 파이프라인(워크플로/Dockerfile/배포 스크립트) 구현·검증·배포
argument-hint: --issue <N> [--dry-run]
---

`ci-cd-pipeline` 스킬을 Skill 도구로 실행하세요. `[CI]` / `[CD]` / `[Security]` / `[Infra]` 카테고리 이슈 #N 을 받아 워크플로 파일 작성 → 로컬 검증(yamllint/actionlint/shellcheck/act) → PR 생성 → 머지 후 실제 실행 모니터링까지 완결합니다.

- `--issue N` 으로 대상 이슈 지정 (지정되지 않으면 먼저 물어볼 것)
- `--dry-run` 이 포함되면 STEP 8~10(실제 PR/실행)을 스킵
- 이슈의 `profile:staging` / `profile:prod` 레이블로 타겟 프로필 결정

인자: $ARGUMENTS
