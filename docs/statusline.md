# Claude Code 상태줄 (ccstatusline)

- 위젯 설정: [`dot_config/ccstatusline/settings.json`](../dot_config/ccstatusline/settings.json) (chezmoi 관리)
- git 위젯 스크립트: [`dot_local/bin/executable_git-status-bits`](../dot_local/bin/executable_git-status-bits)

## 설치

`~/.claude/settings.json` 은 **의도적으로 chezmoi 관리에서 제외했다.**
Claude Code 가 이 파일을 직접 쓰기 때문에 (테마 변경, 권한 추가 등) chezmoi 와 서로 덮어쓴다.
새 맥에서는 아래 블록을 직접 넣는다:

```json
{
  "statusLine": {
    "type": "command",
    "command": "$HOME/.local/share/mise/shims/bunx ccstatusline",
    "padding": 0,
    "refreshInterval": 10
  }
}
```

## 구성

```
Model: Opus 5 | Context: [████░░░░░░░░░░░░] 253k/1.0M (25%) ↻ 0 | Cache: 🟢 59:53
rogiry/dotfiles | ⎇ main ✓ | e8f440e | +0-0 | S:0 M:0 ?:0 | - | cwd: ~/.local/share/chezmoi
In: 570 (0.3 t/s) | Out: 367.1k (181.4 t/s) | Cached: 42.4M
Session: 24.0% (54m) | Weekly: 11.0% | Weekly Opus: 0.0%
```

| 줄 | 역할 |
|---|---|
| 1 | 모델 / 컨텍스트 사용량 + 컴팩션 횟수(`↻`) / 프롬프트 캐시 잔여 |
| 2 | 저장소 · 브랜치+동기화 · SHA · 변경량 · 파일 상태 · PR · CI / **cwd 는 항상 마지막** |
| 3 | 입력·출력 토큰과 각각의 속도 / 캐시 읽기 누적 |
| 4 | 세션 사용률(리셋까지) / 주간 / 주간 Opus |

`+5-1` 은 **줄 수** (staged + unstaged 합산), `S:1 M:1 ?:2` 는 **파일 개수**
(Staged / Modified-미스테이지 / 추적 안 됨). 두 축이 달라 둘 다 표시한다.

---

## git 구간은 자체 스크립트다

2번 줄의 브랜치·SHA·파일 상태는 내장 위젯이 아니라
`~/.local/bin/git-status-bits` 가 그린다. 모드는 네 가지다.

| 모드 | 출력 | 비고 |
|---|---|---|
| `branch` | `⎇ main ✓` / `⑂ feat ↑2↓3` / `⎇ main ⚠` | 브랜치 + 워크트리 + 동기화. `⑂` 는 연결된 워크트리 |
| `commit` | `e8f440e` | 짧은 SHA 만 |
| `sync` | `✓` / `↑2` / `↓3` / `↑2↓3` / `⚠` | 동기화 상태만 |
| `files` | `S:0 M:1 ?:2` | 색 포함 (staged 초록 / modified 노랑 / untracked 빨강) |
| `wt` | `⑂` 또는 빈 출력 | 워크트리 표시만 필요할 때 |

`✓` 동기화됨 · `↑` 푸시 필요 · `↓` 풀 필요 · `⚠` upstream 미설정.
**분리된 HEAD 에는 표시를 붙이지 않는다** — upstream 개념이 없어 항상 `⚠` 가 떠 노이즈가 된다.

### 왜 SHA 가 아니라 브랜치에 붙나

ahead/behind 는 **브랜치와 그 upstream 사이의 관계**지 커밋의 속성이 아니다.
SHA 옆에 두면 "이 커밋이 푸시됐나"처럼 읽히지만 실제 의미는 "이 브랜치가 원격보다
2개 앞섰다"이다. 그래서 `⎇ main ✓` 가 `e8f440e ✓` 보다 정확하다.

git 저장소가 아니면 어느 모드든 **아무것도 출력하지 않는다.**
상태줄에서 빈 출력은 위젯이 통째로 접히므로 구분자(`|`)가 남지 않는다.

### 내장 위젯으로 안 되는 이유

- **`git-ahead-behind` 는 ahead/behind 가 모두 0이면 무조건 `null` 을 반환한다.**
  즉 "동기화됨(✓)"을 표현할 방법이 없다.
- **`git-staged-files` 등 3개를 나란히 두면 `S:0M:1?:2` 처럼 붙어버린다.**
  `custom-text` 로 공백을 넣으면 그 공백이 **항상** 렌더돼서, git 저장소가
  아닐 때 `  |    | cwd: ~` 처럼 빈 구분자가 줄에 남는다.

### custom-command 를 쓸 때 걸리는 함정

| 함정 | 결과 |
|---|---|
| `custom-command` 출력은 **`.trim()` 된다** | 앞뒤 공백으로 간격을 못 만든다. 그래서 `branch` 모드가 브랜치와 동기화 표시를 **함께** 출력한다 |
| `merge` 속성은 **공백을 넣어주지 않는다** | `defaultPaddingSide` 는 Powerline 전용. 간격이 필요하면 스크립트가 직접 출력해야 한다 |
| `merge: true` + 빈 위젯 = **구분자를 건너뛴다** | 옵셔널 위젯에 merge 를 걸면 값이 없을 때 앞뒤가 붙는다 (`⎇ main0afd20f✓`) |
| `custom-command` 의 cwd 는 **ccstatusline 프로세스의 cwd** | 표시 중인 디렉토리가 아니다. **반드시 stdin JSON 에서 읽는다** |
| **빈 값 위젯 옆에 `custom-text` 를 두지 말 것** | custom-text 는 항상 렌더된다 |

### 남아있는 내장 git 위젯

`git-origin-owner-repo`, `git-insertions`, `git-deletions`, `git-review`, `git-ci-status`
는 그대로 쓰되 **숨김 플래그가 걸려 있다.** 이게 없으면 git 저장소 밖에서
`(no git)` 이 반복되며 줄을 채우고 cwd 를 화면 밖으로 밀어낸다.

| 플래그 | 담당 |
|---|---|
| `hideNoGit` | git 저장소가 아닐 때 숨김 |
| `hideNoRemote` | `git-origin-owner-repo` 의 `no remote` 출력 억제 |
| `hideWhenEmpty` | `git-review` 의 `(no PR)` 출력 억제 |

---

## 알아둘 설정 (직접 파본 것들)

### `@latest` 를 붙이지 않는다

매 렌더링마다 npm 버전 확인을 해서 느려진다.

| 명령 | 렌더링 시간 |
|---|---|
| `bunx ccstatusline@latest` | ~0.42s |
| `bunx ccstatusline` | **~0.18s** |

업데이트는 `bun update -g` 대신 캐시를 비우거나 명시적으로
`bunx ccstatusline@latest` 를 한 번 실행하면 된다.

### `refreshInterval: 10`

이게 없으면 상태줄은 대화가 갱신될 때만 다시 그려진다.
즉 **유휴 상태에서 캐시 타이머가 멈춘다.** 캐시가 식기 전에 다음 메시지를 보낼지
판단하는 게 이 위젯의 존재 이유인데, 정작 그 순간에 멈춰 있으면 쓸모가 없다.
Claude Code >= 2.1.97 에서만 지원하며 1~60초를 넣을 수 있다.

### 캐시 TTL 은 `3600`(1시간)

위젯 기본값은 300초(5분)다. Claude Code 는 1시간 TTL 을 쓰므로 기본값 그대로 두면
5분만 지나도 `❄️ COLD` 라고 **거짓 보고**한다. 실측으로 확인했다:

```
ttlSeconds= 300  (마지막 응답 20분 전) → Cache: ❄️ COLD     ← 틀림
ttlSeconds=3600  (마지막 응답 20분 전) → Cache: 🟢 39:54    ← 맞음
```

단, 사용량 초과(overage) 상태에서는 실제 TTL 이 5분으로 떨어지므로 그때는 반대로 길게 표시된다.

### cwd 는 `flex-separator` 없이 그냥 마지막에 둔다

마지막에 두는 것만으로 "긴 경로가 다른 위젯을 밀어내지 않는다"는 목적은 달성된다.
flex 를 쓰면 줄 폭이 항상 터미널 전체로 고정되고, git 저장소 밖에서는
cwd 만 오른쪽 끝에 외따로 떨어져 읽기 나빠진다.

---

## 테스트

stdin 에 JSON 을 넣어 렌더한다:

```sh
PAYLOAD='{"session_id":"t","transcript_path":"/dev/null","cwd":"'"$PWD"'","current_dir":"'"$PWD"'","model":{"id":"claude-opus-5[1m]","display_name":"Opus 5"},"workspace":{"current_dir":"'"$PWD"'","project_dir":"'"$PWD"'"}}'
echo "$PAYLOAD" | ~/.local/share/mise/shims/bunx ccstatusline
```

- **모델 ID 는 반드시 `claude-opus-5[1m]` 처럼 실제 값**을 넣는다.
  `[1m]` 를 빼면 컨텍스트 창을 200k 로 계산해 퍼센트가 5배 틀리게 나온다.
- 상태줄은 **stdout**, bunx 잡음은 stderr 로 나간다.
- 위젯 렌더 비용은 전부 ~155-190ms 로 동일 (bunx 기동시간이 지배).
  **usage 계열은 첫 호출만 ~1.6s 콜드 페치** — 느리다고 판단하기 전에 재측정할 것.
- 값이 항상 비는 위젯: `session-cost`, `cache-read/write/hit-rate`, `extra-usage-*`

## 설정 변경

TUI 는 인터랙티브라 스크립트로 돌릴 수 없다:

```sh
bunx ccstatusline
chezmoi add ~/.config/ccstatusline/settings.json   # 바꾼 뒤 저장소에 반영
```
