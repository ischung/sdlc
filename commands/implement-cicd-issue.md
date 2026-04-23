---
description: implement-top-issue가 CI/CD 이슈를 위임할 때 쓰는 내부 경로
argument-hint: <이슈 번호>
---

`ci-cd-pipeline` 스킬을 Skill 도구로 실행하세요. 이슈 #$ARGUMENTS 를 CI/CD 파이프라인으로 구현합니다.

이 커맨드는 `implement-top-issue` v1.3 의 하이브리드 모드가 CI/CD 카테고리 이슈를 감지했을 때 내부 위임 경로로 사용됩니다. 실행 결과(성공/실패/롤백)만 반환하고, 다음 이슈 픽업은 호출자(implement-top-issue)가 처리합니다 — 순환 금지.
