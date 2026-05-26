---
name: pr-review-followup
description: Use when a PR you previously reviewed has new commits or author responses to your findings, and you need to write the next review turn — verifying claims against the new code, deciding addressed/disputed/deferred, and posting a follow-up comment.
---

# PR Review Follow-up

리뷰는 한 번으로 끝나지 않는다. 작성자가 답변하고 코드를 푸시하면 **next turn**이 필요하다 — 주장을 코드로 검증하고, 각 finding에 대한 verdict를 결정하고, 후속 코멘트를 남기는 것. 이 스킬은 그 한 턴을 일관되게 수행하는 절차다.

## When to Use

**Use when:**
- 내가 (또는 내가 호출한 도구가) PR에 리뷰 코멘트를 남긴 뒤, 작성자가 새 커밋·답변 코멘트를 추가한 상황
- 같은 PR을 두 번째 이상 보고 있고, "어디까지가 신규 변경인지" 헷갈리는 상황
- 작성자가 일부 finding을 반박(disputed)하거나 후속(deferred) 처리하겠다고 답변한 상황
- 코드 리뷰가 여러 턴 오갈 가능성이 있는 협업 환경 일반

**Do NOT use:**
- 첫 리뷰 (그건 `/codex:review`·`/codex:adversarial-review` 또는 직접 리뷰)
- 단순한 PR 코멘트 답글 — finding을 추적·검증할 게 없는 잡담성 코멘트
- 리뷰어가 아닌 작성자 입장 — 이 스킬은 reviewer turn 전용

## Core Principle

**Verify before believing. Anchor before comparing. Structure before posting.**

작성자의 코멘트는 **주장**일 뿐이다. 코드에서 직접 확인되지 않은 주장은 verdict로 옮기지 마라. 그리고 "신규 변경"의 범위는 base가 아니라 **이전 리뷰가 본 commit**부터다 — 그 앵커를 먼저 박아야 한다.

## Procedure

다음 단계를 **순서대로** 수행하라. 각 단계는 다음 단계의 입력이다.

### 1. 이전 리뷰 위치 파악 (anchor)

- `gh pr view <num> --json comments,reviews,commits`로 전체 타임라인 수집
- 내가 남긴 **가장 최근 리뷰 코멘트**의 createdAt과, 그 코멘트가 평가한 commit SHA를 식별
  - 내 리뷰 본문의 footer 메타데이터(`base: <ref>`, commit SHA 등)에서 직접 추출
  - 없으면 코멘트 createdAt 직전의 HEAD commit을 앵커로 사용
- 이 SHA를 `PRIOR_SHA`로 명시적으로 기록 (이후 모든 "신규" 판단의 기준)
- **PRIOR review의 종류와 ID도 기록** (step 6 게시 방식 결정에 사용):
  - `gh pr view <num> --json reviews --jq '.reviews[]'` → PR Review가 있는지
  - `gh api /repos/<o>/<r>/pulls/<n>/comments --jq '.[] | select(.user.login=="<me>")'` → inline review comment 있는지
  - 둘 중 하나라도 있으면 **PATH_B** (threaded reply 가능)
  - 둘 다 없고 issue comment만 있으면 **PATH_C** (인용 fallback)

### 2. 신규 활동 수집 (delta)

- `git fetch origin <head-branch>`로 최신 상태 가져옴
- `git log PRIOR_SHA..origin/<head-branch> --oneline`로 신규 커밋
- `git diff PRIOR_SHA..origin/<head-branch>`로 신규 코드 diff
- `gh pr view <num> --json comments --jq '.comments[] | select(.createdAt > "<PRIOR_TIME>")'`로 신규 코멘트
- **diff에 `.github/workflows/*`가 포함되면 `gh run list --branch <head-branch> --limit 5` 필수.** 정적 inspect와는 별개 차원의 증거 — 워크플로우 PR은 "코드가 맞다"와 "실제로 돈다"가 서로 다른 검증. run 결과는 finding 매트릭스에 반영하거나, 실패 시 별도 finding으로 추가
- `.github/workflows/*`가 없으면 위 단계 생략 가능

### 3. Finding 매트릭스 작성 (verdict)

내 이전 리뷰의 **모든 finding**을 다음 5개 verdict 중 하나로 분류한다 — 다른 라벨 금지:

| Verdict | 조건 |
|---|---|
| **addressed** | 작성자 주장 + 코드 변경이 모두 확인됨, finding의 근본 원인이 해소됨 |
| **partial** | 일부만 고침. 남은 부분 명시 필요 |
| **disputed** | 작성자가 finding 자체를 반박. 재방어 또는 양보 결정 필요 |
| **deferred** | 작성자가 별도 작업/이슈로 빼겠다고 함. 후속 트래킹 필요 |
| **unverifiable** | 권한·환경 부족으로 검증 불가 (예: 외부 webhook end-to-end) |

각 finding에 대해 **코드에서 직접 본 증거**(파일:라인)를 verdict 옆에 적어라. "확인했다"만으로는 부족하다.

### 4. 신규 결함 스캔 (regression)

신규 커밋이 새 결함을 도입했을 수 있다. **delta가 작아도** 다음을 수행:

- 신규 diff에 대해 `/codex:adversarial-review --base PRIOR_SHA --background` 또는 동급의 fresh 패스를 한 번 더 돌릴지 결정
  - delta가 한 파일·30줄 미만이면 직접 inspect로 대체 가능
  - 그 이상이면 fresh 패스 권장 — 수동 verify는 신규 결함을 못 잡는다
- 발견된 신규 issue는 finding 매트릭스에 **별도 섹션**으로 추가 ("New in this round")

### 5. Dispute / Deferred 처리 규칙

- **disputed (high+)**: 재방어 1회. 새 증거가 없으면 양보하고 명시. 재방어 → 양보 → 양보의 무한 루프 금지
- **disputed (medium 이하)**: 작성자 판단 존중. 코멘트에 양보 명시
- **deferred (high+)**: 후속 이슈 번호를 답변에 **필수** 요청. 번호 없이는 머지 차단 권장
- **deferred (medium 이하)**: 후속 이슈 권장. 번호 없어도 머지 진행 가능

### 5.5. 승인 / 차단 결정 (event 라벨)

step 6에서 PR Review를 만들 때 `event` 필드는 다음 표대로 결정한다. **reviewer(=스킬 호출자)의 명시적 결정이 최우선** — 자동 판단 금지. 호출자가 결정을 명시 안 했으면 표에 따라 추천만 하고 확인을 받아라.

| 매트릭스 상태 | 추천 event | 의미 |
|---|---|---|
| 모든 finding이 addressed | **APPROVE** | 머지 가능 |
| addressed 위주 + medium 이하 open(deferred/disputed)만 남음 | **APPROVE** | 작은 미해소는 양보 |
| high+ open이 남음, reviewer가 **양보 명시**(예: "후속 이슈로 OK") | **APPROVE** | reviewer 권한으로 양보 가능 — 단 양보 사실과 후속 요건을 본문에 명시 |
| high+ open이 남음, reviewer 양보 없음 | **REQUEST_CHANGES** | 머지 차단 |
| 신규 결함(New in this round) high+ 발견 | **REQUEST_CHANGES** | regression은 항상 차단 |
| 어느 경우에도 해당 안 됨 / 결정 보류 | **COMMENT** | 중립, 머지 영향 없음 |

**Reviewer 양보 (override) 룰**
- reviewer는 critical을 포함한 어떤 severity든 양보할 수 있다 (권한)
- 양보할 때는 본문에 **명시적으로** 적는다: "[critical] X는 후속 이슈로 양보합니다" 형태
- 양보 + APPROVE 조합일 때는 follow-up 요건(이슈 번호, 마감 시점 등)을 반드시 같은 코멘트에 적는다 — 머지 후 잊혀짐 방지
- "묵시적 양보" 금지: 본문에 빠뜨리고 APPROVE만 누르지 마라

**Event별 명령어**
```bash
gh pr review <num> --approve --body-file body.md         # APPROVE
gh pr review <num> --request-changes --body-file body.md # REQUEST_CHANGES
gh pr review <num> --comment --body-file body.md         # COMMENT (중립)
```
PATH_B에서 `gh api ... /reviews`를 직접 쓰는 경우 `-f event=APPROVED|CHANGES_REQUESTED|COMMENT`.

### 6. 후속 코멘트 작성 (post)

step 1에서 결정한 PATH에 따라 게시 방식이 다르다.

#### Common: 종합 본문 템플릿 (두 경로 모두 사용)

```markdown
# Follow-up Review

**Anchor**: `<PRIOR_SHA>` → `<HEAD_SHA>` (신규 커밋 N개, +X/-Y, M파일)

## Verdicts

| Finding | Severity | Verdict | 증거 |
|---|---|---|---|
| <원 finding 제목> | critical | deferred | author 답변 + 후속 이슈 #NN |
| ... | ... | ... | ... |

## Addressed
- [finding] 어떻게 고쳐졌는지 한 줄 + 파일:라인

## Disputed / Deferred
- [finding] verdict 결정과 이유, 작성자에게 요청할 것

## New in this round (regression scan)
- [finding] (없으면 "신규 결함 없음")

## Open requirements
- 머지 전 반드시 처리되어야 할 항목 (없으면 생략)

---
_Follow-up by pr-review-followup skill. Anchor: <PRIOR_SHA>_
```

footer 메타데이터의 anchor는 **다음 follow-up turn이 PRIOR_SHA로 쓸 값**이다. 빼먹지 마라.

#### PATH_B (preferred) — PR Review + inline thread reply

전제: PRIOR가 PR Review거나 inline review comment를 포함.

1. **종합 본문**은 새 PR Review의 `body`로 게시:
   ```bash
   gh api -X POST /repos/<o>/<r>/pulls/<n>/reviews \
     -f event=COMMENT \
     -f body="$(cat followup-body.md)"
   ```
   `event`: COMMENT(중립) / APPROVE(승인) / REQUEST_CHANGES(차단). disputed/deferred high+ 있으면 COMMENT 또는 REQUEST_CHANGES.
2. **finding별 답글**은 PRIOR의 inline thread에 `replies` 엔드포인트로:
   ```bash
   gh api -X POST /repos/<o>/<r>/pulls/<n>/comments/<prior_inline_id>/replies \
     -f body="<addressed/disputed 문구 + 파일:라인 증거>"
   ```
3. **새로 발견한 신규 결함**(step 4 result)은 새 inline review comment로:
   ```bash
   gh api -X POST /repos/<o>/<r>/pulls/<n>/comments \
     -f body="..." -f commit_id="<HEAD_SHA>" \
     -f path="<file>" -F line=<n> -f side=RIGHT
   ```

#### PATH_C (fallback) — issue comment + 인용

전제: PRIOR가 issue comment뿐 (threaded reply 불가).

1. 종합 본문 첫 줄에 인용 추가:
   ```markdown
   > Re: [PRIOR review](<comment_html_url>) — anchor `<PRIOR_SHA>`
   ```
2. `gh pr comment <num> --body-file followup-body.md`로 게시
3. 진짜 thread는 아니고 시각적 묶임만 — 다음 PR부터 PATH_B로 전환 권장

#### 첫 리뷰 게시 시 권장 (다음 PR turn을 위한 prerequisite)

이 스킬은 follow-up 전용이지만, **첫 리뷰를 어떻게 게시했는지가 다음 turn의 PATH를 결정**한다. 가능하면 첫 리뷰부터:

- finding이 코드 라인에 anchorable → PR Review로 inline + body로 게시 → 다음 follow-up은 PATH_B
- finding이 모두 design-level (특정 라인에 못 박음) → issue comment로 게시 → 다음 follow-up은 PATH_C
- 혼합 → PR Review의 body에 종합 + 가능한 finding만 inline

### 7. 게시 전 자체 검증

게시 직전 다음 체크리스트를 통과시켜라 — 하나라도 안 맞으면 게시 보류:

- [ ] 모든 원 finding이 매트릭스에 한 번씩 등장
- [ ] verdict가 5개 라벨 중 하나
- [ ] 각 verdict에 코드 증거 (파일:라인) 또는 명시적 unverifiable 사유
- [ ] base 또는 dev 상태에 대한 주장은 실제로 `git show`로 확인됨
- [ ] disputed/deferred high+ 항목에 처리 요건 명시
- [ ] footer에 PRIOR_SHA·HEAD_SHA 기록
- [ ] PATH 결정됨 (B 또는 C). PATH_B면 PRIOR inline comment id 확보
- [ ] PATH_C면 종합 본문 첫 줄에 `> Re: [PRIOR review](url) — anchor SHA` 인용 포함
- [ ] event 결정됨 (APPROVE / REQUEST_CHANGES / COMMENT). high+ open 양보 시 본문에 양보 사실 + 후속 요건 명시 확인

## Voice / Tone

이 스킬을 호출한 사람의 말투에 맞춰 작성한다. 기본값은 다음과 같다 — 프로젝트별 CLAUDE.md에 다른 규칙이 있으면 그쪽 우선.

### 기본 톤
- **한국어**, 간결, 직접
- 자연스러운 구어체: "~수정됐네요", "이 부분은 ~", "~해주세요"
- 표는 그대로 (verdict 매트릭스·증거는 구조화 유지)
- prose 섹션은 짧게 — 한 항목 2~3문장 안

### 금지 표현
| 금지 | 이유 | 대체 |
|---|---|---|
| "좋은 지적이네요!" / "Good catch!" | AI 정형 격려 — 사람이 안 씀 | 그냥 verdict로 넘어감 |
| "훌륭한 수정입니다" / "Great work!" | 마찬가지 | "확인했습니다" / 생략 |
| "감사합니다" 남발 | 리뷰어가 감사할 일 아님 | 생략 |
| "혹시 시간 되실 때 ~" | 과도하게 조심스러움 | "~해주세요" 직접 |
| "다음과 같이 정리됩니다:" 류 메타 서론 | 군더더기 | 바로 본문 |
| "결론적으로", "정리하자면" | 같은 이유 | 생략하거나 마지막 줄 한 줄로 |
| 이모지 (사용자 요청 없으면) | AI 흔적 | 사용 안 함 |

### 표본 (before / after)

**Before (AI스러움)**
> 정말 좋은 수정입니다! `event.requested_reviewer.login`을 사용하도록 변경하신 점, 훌륭한 접근이라고 생각합니다. 감사합니다! 🎉

**After (사용자 voice)**
> `event.requested_reviewer.login`으로 바뀐 거 확인. 이번 이벤트에서 요청된 사람만 정확히 타깃됩니다.

### Disputed 응답 톤
- 재방어 1회는 **사실/근거 중심**으로. 감정적 표현·재차 권유 금지
- "제가 본 근거는 X입니다. 그래도 의도된 거라면 fold하겠습니다." 형태
- 양보할 때: "OK, 그쪽 판단 존중하겠습니다" 한 줄로

## Common Mistakes

| 실수 | 왜 일어나는지 | 대응 |
|---|---|---|
| base branch 상태를 가정으로 진술 | "dev에도 없으니 의도된 삭제겠지" 식의 추론 | step 1·2에서 항상 `git show origin/<base>:<path>`로 확인 |
| verdict를 ✅/❌ 같은 ad-hoc 라벨로 작성 | 빠르게 쓰려는 유혹 | 5개 라벨 고정. 표 형식 강제 |
| 워크플로우 PR인데 `gh run list` 안 봄 | 정적 inspect로 충분하다고 자기합리화 | step 2 룰: `.github/workflows/*` diff면 run list 필수 |
| AI 정형 표현 ("좋은 지적이네요" 등) 삽입 | 친절하게 보이려는 본능 | Voice/Tone 섹션 금지 리스트 참조 |
| 작성자 답변을 그대로 신뢰 | "수정했다" 텍스트만 보고 verdict 결정 | 답변과 별개로 diff 확인. 텍스트는 주장, diff가 증거 |
| 신규 결함 스캔 생략 | delta가 작아 보임 | 30줄 기준선. 그 이상이면 fresh 패스 |
| disputed 무한 루프 | 재방어와 양보를 반복 | 재방어 1회 룰. 양보 후 fold |
| anchor SHA 빼먹음 | 코멘트 footer 부주의 | step 7 체크리스트 |

## Red Flags — 이거 보이면 STOP

- "확인했습니다"만 적고 파일:라인이 없는 verdict
- finding 5개 중 4개만 verdict가 있고 1개가 누락 — 빠뜨린 것
- base 브랜치 상태를 fetch 없이 단언 — hallucination 가능
- disputed에 대해 "그러면 다음 PR에서..."로 양보했는데 후속 이슈 번호 없음
- high+ open 있는데 본문에 양보 명시 없이 APPROVE — "묵시적 양보" 금지
- 코멘트 본문에 footer 메타데이터 누락 — 다음 turn이 anchor를 못 잡음
- 워크플로우 디렉터리 변경 PR인데 GitHub Actions run 결과 안 봄
- prose에 "좋은 지적이네요" / "감사합니다" / 이모지 / 메타 서론 들어감 → Voice 섹션 다시 보기

위 중 하나라도 발견되면 **게시 전 step 7로 돌아가라.**

## Quick Reference

```bash
# 1. anchor 파악
gh pr view <num> --json comments,reviews,commits

# 2. delta
PRIOR_SHA=<from step 1>
git fetch origin <head-branch>
git log $PRIOR_SHA..origin/<head-branch> --oneline
git diff $PRIOR_SHA..origin/<head-branch> --stat
gh pr view <num> --json comments --jq ".comments[] | select(.createdAt > \"<PRIOR_TIME>\")"
gh run list --branch <head-branch> --limit 5

# 4. regression scan (delta가 클 때)
git checkout <head-branch>
# /codex:adversarial-review --base $PRIOR_SHA --background

# 6. post — PATH_B (PR Review + inline reply)
gh api -X POST /repos/<o>/<r>/pulls/<n>/reviews -f event=COMMENT -f body="$(cat followup-body.md)"
gh api -X POST /repos/<o>/<r>/pulls/<n>/comments/<prior_inline_id>/replies -f body="..."

# 6. post — PATH_C (issue comment + 인용 fallback)
gh pr comment <num> --body-file followup.md   # 본문 첫 줄에 '> Re: [...](url) — anchor SHA'
```

## Tools that Pair Well

- `/codex:adversarial-review` — step 4 regression scan에 사용
- `gh pr view --json comments,reviews,commits` — step 1·2 데이터 소스
- `gh run list --branch` — GitHub Actions 워크플로우 PR일 때 step 2에서 실제 실행 결과 확인

## When This Skill Doesn't Apply

- PR을 첫 리뷰하는 상황 → 다른 도구
- 작성자 입장에서 리뷰 코멘트에 답변하는 상황 → 다른 도구
- finding 추적이 필요 없는 단순 잡담성 코멘트 → 직접 답변
