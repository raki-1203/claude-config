# /team - 에이전트 팀 하네스

YAML 템플릿 기반으로 에이전트 팀을 자동 구성하고 TDD 워크플로우를 실행합니다.

## 사용법

```
/team [template] [task description]
```

## 예시

```
/team explore-first 결제 시스템 리팩토링
/team python-backend JWT 기반 사용자 인증 구현
/team fullstack Redis 검색 기능 추가
/team minimal 로그인 버그 수정 (#42)
/team                                    # 자동 감지 + 인터랙티브
```

## 사용 가능한 템플릿

| 템플릿 | 팀원 | 단계 | 용도 |
|--------|------|------|------|
| `explore-first` | Explorer x2 + Librarian + Oracle + Plan-Reviewer + Developer + Tester + Claude-Reviewer + Codex x3 (12명) | 10단계 | **탐색 우선** - 먼저 조사 후 TDD + 크로스 리뷰 |
| `python-backend` | 리더 + 개발자 + 테스터 + 리뷰어 (4명) | 6단계 | Python 백엔드 |
| `fullstack` | 리더 + 개발자 + 테스터 + 리뷰어 + UI/UX + 문서 (6명) | 7단계 | 풀스택 |
| `minimal` | 리더 + 개발자-테스터 (2명) | 3단계 | 빠른 수정 |

## 실행 지시

`$ARGUMENTS`를 전달받아 team-harness 스킬을 실행합니다.

1. **team-harness 스킬을 로드하여 실행합니다.** SKILL.md의 절차를 따릅니다.
2. 인자: `$ARGUMENTS`

### 상세 절차

1. `$ARGUMENTS`에서 템플릿 이름과 작업 설명을 분리합니다
   - 첫 단어가 `explore-first`, `python-backend`, `fullstack`, `minimal`, 또는 `~/.claude/team-templates/`에 있는 YAML 파일명이면 → 템플릿 이름
   - 아니면 → 전체를 작업 설명으로 사용, 템플릿은 자동 감지

2. 템플릿을 찾아 Read 도구로 읽습니다 (검색 순서):
   - `./.claude/team.yaml`
   - `./.claude/team-templates/{name}.yaml`
   - `~/.claude/team-templates/{name}.yaml`

3. 자동 감지 (템플릿 미지정 시):
   - `pyproject.toml` / `setup.py` / `requirements.txt` → `python-backend`
   - `package.json` + `src/app` or `app/` → `fullstack`
   - 기타 → `minimal`

4. `./CLAUDE.md`를 읽어 프로젝트 컨텍스트를 파악합니다

5. TeamCreate로 팀을 생성합니다

6. YAML의 phases에 따라 TaskCreate로 태스크를 생성하고 의존성(addBlockedBy)을 설정합니다

7. YAML의 leader와 members에 따라 Task 도구로 에이전트를 스폰합니다 (run_in_background=true, team_name 지정)

8. 첫 번째 태스크(plan)를 리더에게 배정합니다

9. 메시지를 모니터링하며 태스크 완료 시 다음 태스크를 배정합니다

10. 모든 태스크 완료 → shutdown_request → TeamDelete → 최종 보고
