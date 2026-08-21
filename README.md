# dotfiles

macOS 개발 환경 — chezmoi 로 관리.

- **셸**: zsh + starship + fzf-tab + autosuggestions + syntax-highlighting
- **런타임**: mise (bun, node)
- **터미널**: Ghostty + MesloLGS Nerd Font
- **시스템**: Dock / 키보드 / 트랙패드 제스처 설정 스크립트

---

## 새 맥에 설치

```sh
curl -fsSL https://raw.githubusercontent.com/rogiry/dotfiles/main/bootstrap.sh | bash
```

또는 수동으로:

```sh
brew install chezmoi
chezmoi init --apply rogiry/dotfiles
bash "$(chezmoi source-path)/macos/defaults.sh"   # 시스템 설정은 별도 실행
```

설치 후 남는 수동 작업:

1. **Ghostty 재시작** — Nerd Font 반영
2. **로그아웃 또는 재시작** — 트랙패드 제스처 완전 반영
3. **`bunx ccstatusline@latest`** — Claude Code 상태줄 설정 (아래 참고)

---

## 구조

```
.
├── bootstrap.sh                 새 맥 부트스트랩
├── Brewfile                     brew 패키지 목록
├── .chezmoidata.toml            템플릿 변수 (이름/이메일)
├── .chezmoiignore               저장소에만 두고 홈에 안 뿌릴 것
├── .chezmoiscripts/
│   ├── run_onchange_before_10-brew.sh.tmpl    Brewfile 변경 시 brew bundle
│   ├── run_onchange_after_20-mise.sh.tmpl     mise 설정 변경 시 런타임 설치
│   └── run_once_after_30-completions.sh       완성 정의 설치 (최초 1회)
├── dot_zshrc                    →  ~/.zshrc
├── dot_zprofile                 →  ~/.zprofile
├── dot_gitconfig.tmpl           →  ~/.gitconfig  (템플릿)
├── dot_config/
│   ├── starship.toml            →  ~/.config/starship.toml
│   ├── ghostty/config           →  ~/.config/ghostty/config
│   ├── mise/config.toml         →  ~/.config/mise/config.toml
│   └── bat/config               →  ~/.config/bat/config
└── macos/
    ├── defaults.sh              Dock / 키보드 / 트랙패드 설정 적용
    └── capture.sh               현재 맥 상태 덤프 (drift 확인용)
```

---

## 일상 사용

| 명령 | 하는 일 | alias |
|---|---|---|
| `chezmoi edit ~/.zshrc` | 소스 파일 편집 | `cme` |
| `chezmoi diff` | 적용 전 변경 미리보기 | `cmd` |
| `chezmoi apply` | 홈 디렉토리에 반영 | `cma` |
| `chezmoi cd` | 소스 저장소로 이동 | `cmcd` |
| `chezmoi update` | 원격 pull + apply | |
| `chezmoi add ~/.foo` | 새 파일을 관리 대상에 추가 | |

⚠ **`~/.zshrc` 를 직접 고치지 말 것.** 다음 `chezmoi apply` 에 덮어써진다.
`chezmoi edit ~/.zshrc` 를 쓰거나 소스 파일을 직접 편집한다.

---

## mise 백엔드 정책: core > aqua > (asdf/vfox 차단)

`dot_config/mise/config.toml` 에 `disable_backends = ["asdf", "vfox"]` 가 설정돼 있다.

mise 레지스트리는 이미 이 우선순위를 반영한다:

```
bun     -> core:bun                                       core 가 있으면 core 만
node    -> core:node
jq      -> aqua:jqlang/jq        asdf:mise-plugins/asdf-jq  core 없으면 aqua 가 1순위
lazygit -> aqua:jesseduffield/lazygit   asdf:...
```

- **core** — mise 내장 구현. 언어별 특수사항 처리 (`lts` 별칭, `.node-version` 인식,
  `npm`/`npx`/`corepack` 심 생성, 소스 빌드).
- **aqua** — 체크섬·서명이 검증되는 범용 바이너리 레지스트리. core 가 없는 툴의 1순위.
- **asdf/vfox** — 임의 코드를 실행하는 플러그인 백엔드. 꺼둔다.

`node` 는 반드시 core 여야 한다. `aqua:nodejs/node` 는 `lts` 별칭을 해석하지 못하고
(빈 결과) 노출 버전도 100개뿐이다 (core 는 860개).

---

## `.zshrc` 로드 순서

순서를 바꾸면 조용히 깨진다:

`dot_zshrc` 의 번호는 아래 순서를 그대로 따른다.

```
   brew shellenv          (.zprofile — 로그인 셸에서만)
0. brew shellenv 폴백     ($HOMEBREW_PREFIX 가 비었을 때만. 아래 설명)
1. mise activate          (PATH 를 바꾸므로 compinit 보다 먼저)
2. 히스토리 옵션
3. 디렉토리 / 일반 옵션
4. FPATH + compinit + zstyle
5. fzf-tab                (compinit 다음 & 위젯 래핑 플러그인들보다 먼저)
6. fzf 키바인딩
7. zoxide
8. zsh-autosuggestions
9. 시크릿 (키체인 조회)   ← 순서 무관. 편의상 여기
10. alias
11. starship init
12. zsh-syntax-highlighting   ← 반드시 맨 마지막
```

순서가 실제로 중요한 건 **0 → 1 → 4 → 5 → 6·7·8 → 11 → 12** 구간이다.
2·3·9·10 은 어디에 있어도 되지만, 번호를 유지해야 diff 가 읽기 쉽다.

### 0번(Homebrew 폴백)이 왜 필요한가

`.zprofile` 은 **로그인 셸에서만** 실행된다. 부모 환경을 물려받지 못한
차가운 비로그인 셸(cron, `ssh host zsh -i`, 일부 터미널 설정)에서는
`$HOMEBREW_PREFIX` 가 비고, 그러면 아래 플러그인 로드가 **에러 없이 전부 건너뛰어진다.**

실측한 증상:

```
비로그인 셸 (폴백 전):  HOMEBREW_PREFIX=[]  fzf-tab=0 autosuggest=0 syntax-hl=0 starship=INACTIVE
비로그인 셸 (폴백 후):  HOMEBREW_PREFIX=[/opt/homebrew]  fzf-tab=1 autosuggest=1 syntax-hl=1 starship=active
```

---

## alias 정책: 원본 명령을 덮어쓰지 않는다

`cat`/`grep`/`top` 은 **일부러 alias 하지 않는다.** 대체 도구가 드롭인이 아니라서
원본 플래그가 깨지거나, 더 나쁘게는 **에러 없이 결과가 달라진다.**

실측한 것:

| 명령 | `bat`/`rg`/`btop` 로 alias 했을 때 |
|---|---|
| `cat -v`, `cat -e` | ✗ `error: unexpected argument` |
| `grep -E "a\|b"` | ✗ rg 는 기본이 정규식이라 `-E` 없음 |
| `grep "a\\|b"` (BRE) | ✗ rg 는 POSIX BRE 아님 |
| `top -l 1` | ✗ btop 에 `-l` 없음 |

**가장 위험한 건 조용한 오작동이다.** `rg` 는 `.gitignore` 와 숨김 파일을 건너뛴다:

```
같은 패턴이 4개 파일에 존재 (2개는 .gitignore, 1개는 숨김 파일)
  /usr/bin/grep -r  →  4개 발견
  rg                →  1개만 발견     ← 에러 없이 3개 누락
```

대신 짧은 별칭을 둔다:

| 별칭 | 실제 |
|---|---|
| `c` | `bat --paging=never` |
| `rgi` | `rg -i` |
| `rga` | `rg -uuu` (ignore·숨김 무시하고 전부 검색) |
| `btm` | `btop` |
| `lst` | `eza -l --sort=modified --reverse` (`ls -ltr` 대용) |

`ls` → `eza` 만 예외적으로 유지한다. `-l`, `-a`, `-1`, `-h`, `--color` 를 다 받아서
호환성이 좋다. 단 **`-t` 는 eza 에서 `--time`(인자 필요)이라 `ls -t`, `ls -ltr` 이 깨진다** → `lst` 사용.


---

## macOS 시스템 설정

```sh
bash macos/defaults.sh     # 적용
bash macos/capture.sh      # 현재 상태 덤프 (defaults.sh 와 비교용)
```

`defaults.sh` 는 **현재 맥 설정의 스냅샷**이라 그대로 실행해도 체감 변화가 없다.
`# 추천:` 으로 시작하는 줄은 적용되지 않은 제안 — 원하면 주석을 풀면 된다.

주요 추천 항목:

- Dock 자동 숨김 / 최근 앱 숨기기
- 자동 대문자·마침표 치환 끄기 (코딩 시 방해)
- 탭 투 클릭 켜기
- 세 손가락 드래그 켜기 (스와이프를 네 손가락으로 옮겨야 함)

⚠ **트랙패드 제스처는 로그아웃/재시작해야 완전히 반영된다.** Dock/키보드는 즉시 반영.

이 스크립트는 **일부러 chezmoi 자동 실행(`run_` 스크립트)에서 제외했다.**
`chezmoi apply` 는 자주 돌리는 명령인데 그때마다 `killall Dock Finder` 가 실행되면 곤란하다.

---

## ccstatusline (Claude Code 상태줄)

`~/.claude/settings.json` 은 **의도적으로 chezmoi 관리에서 제외했다.**
Claude Code 가 이 파일을 직접 쓰기 때문에 (테마 변경, 권한 추가 등) chezmoi 와 서로 덮어쓴다.
반면 `~/.config/ccstatusline/settings.json` 은 chezmoi 가 관리한다.

새 맥에서는 아래 블록을 `~/.claude/settings.json` 에 직접 넣는다:

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

### 구성

```
Opus 5 | Context: [████░░░░░░░░░░░░] 253k/1.0M (25%) ↻ 0 | Cache: 🟢 59:53
rogiry/dotfiles | ⎇ main | 0170b75 | +0-0 | S:0M:0?:0 | ✓ | - | cwd: ~/.local/share/chezmoi
In: 570 (0.3 t/s) | Out: 367.1k (181.4 t/s) | Cached: 42.4M
Session: 12.0% (3hr 29m) | Weekly: 7.0% | Weekly Opus: 0.0%
```

| 줄 | 역할 |
|---|---|
| 1 | 모델 / 컨텍스트 사용량 + 컴팩션 횟수(`↻`) / 프롬프트 캐시 잔여 |
| 2 | 저장소 · 브랜치 · SHA · 변경량 · 파일 상태 · clean · CI / **cwd 는 항상 마지막** |
| 3 | 입력·출력 토큰과 각각의 속도 / 캐시 읽기 누적 |
| 4 | 세션 사용률(리셋까지) / 주간 / 주간 Opus |

`+5-1` 은 **줄 수** (staged + unstaged 합산), `S:1M:1?:2` 는 **파일 개수**
(Staged / Modified-미스테이지 / 추적 안 됨). 두 축이 달라 둘 다 표시한다.

### 알아둘 설정 (직접 파본 것들)

**`@latest` 를 붙이지 않는다.** 매 렌더링마다 npm 버전 확인을 해서 느려진다.

| 명령 | 렌더링 시간 |
|---|---|
| `bunx ccstatusline@latest` | ~0.42s |
| `bunx ccstatusline` | **~0.18s** |

업데이트는 `bun update -g` 대신 캐시를 비우거나 명시적으로 `bunx ccstatusline@latest` 를 한 번 실행하면 된다.

**`refreshInterval: 10`** — 이게 없으면 상태줄은 대화가 갱신될 때만 다시 그려진다.
즉 **유휴 상태에서 캐시 타이머가 멈춘다.** 캐시가 식기 전에 다음 메시지를 보낼지
판단하는 게 이 위젯의 존재 이유인데, 정작 그 순간에 멈춰 있으면 쓸모가 없다.
Claude Code >= 2.1.97 에서만 지원하며 1~60초를 넣을 수 있다.

**캐시 TTL 은 `3600`(1시간)으로 설정** — 위젯 기본값은 300초(5분)다.
Claude Code 는 1시간 TTL 을 쓰므로 기본값 그대로 두면 5분만 지나도
`❄️ COLD` 라고 **거짓 보고**한다. 실측으로 확인했다:

```
ttlSeconds= 300  (마지막 응답 20분 전) → Cache: ❄️ COLD     ← 틀림
ttlSeconds=3600  (마지막 응답 20분 전) → Cache: 🟢 39:54    ← 맞음
```

단, 사용량 초과(overage) 상태에서는 실제 TTL 이 5분으로 떨어지므로 그때는 반대로 길게 표시된다.

**git 위젯에 숨김 플래그가 걸려 있다.** 이게 없으면 git 저장소 밖에서
`(no git)` 이 9번 반복되며 134칸을 채우고 cwd 를 화면 밖으로 밀어낸다.

| 플래그 | 대상 위젯 |
|---|---|
| `hideNoGit` | branch, sha, ahead-behind, insertions/deletions, staged/unstaged/untracked, clean, ci |
| `hideNoRemote` | git-origin-owner-repo (`no remote` 출력 담당) |
| `hideWhenEmpty` | git-review (`(no PR)` 출력 담당) |

**cwd 는 `flex-separator` 를 쓰지 않고 그냥 마지막에 둔다.**
마지막에 두는 것만으로 "긴 경로가 다른 위젯을 밀어내지 않는다"는 목적은 달성된다.
flex 를 쓰면 줄 폭이 항상 터미널 전체로 고정되고, git 저장소 밖에서는
cwd 만 오른쪽 끝에 외따로 떨어져 읽기 나빠진다.

### 설정 변경

TUI 는 인터랙티브라 스크립트로 돌릴 수 없다:

```sh
bunx ccstatusline
chezmoi add ~/.config/ccstatusline/settings.json   # 바꾼 뒤 저장소에 반영
```

---

## 로컬 오버라이드 (`~/.zshrc.local`)

머신마다 다른 설정은 저장소에 넣지 않고 `~/.zshrc.local` 에 둔다.
`.zshrc` **13번 섹션이 맨 마지막에 읽으므로, 여기서 정의한 것이 항상 이긴다.**

```sh
$EDITOR ~/.zshrc.local     # chezmoi edit 아님 — 관리 대상이 아니다
exec zsh
```

**`chezmoi init --apply` 시 자동으로 생성된다** (`create_dot_zshrc.local`).
키체인 등록 방법, `_kc_export` 사용 예, 프로젝트별 키 설정까지 주석으로 들어있다.

`create_` 접두사의 동작 (실제로 검증함):

| 상황 | 결과 |
|---|---|
| 파일이 없음 | 템플릿으로 **생성** |
| 사용자가 수정함 | `diff` 비어있음, `apply` 해도 **보존** |
| 저장소의 템플릿이 바뀜 | 이미 있는 파일엔 **밀어넣지 않음** |

- 파일이 없어도 셸은 정상 동작한다 (존재할 때만 source)
- 우선순위 검증: 저장소가 정의한 `ll` 을 로컬에서 재정의하면 로컬이 이긴다

무엇을 넣나:

| 넣을 것 | 넣지 말 것 |
|---|---|
| 이 머신에서만 쓰는 alias | 모든 머신에 필요한 설정 → `dot_zshrc` |
| 회사/개인별 환경변수 | **시크릿 값** → 9번 섹션 키체인 방식 |
| 실험적 설정 | 위젯 감싸는 플러그인 → 12번 뒤라 충돌 |

예시 (실제로 이 머신에 들어있는 것):

```bash
# Claude Code: 권한 확인을 전부 건너뛰고 시작
alias c='claude --dangerously-skip-permissions'
```

---

## 시크릿 (API 키 등)

**이 저장소는 평문 시크릿을 담지 않는다.** 값은 macOS 키체인에 두고
`.zshrc` 가 셸 시작 시 조회한다. 저장소에도 디스크에도 평문이 남지 않는다.

### 추가하기

```sh
# 값을 프롬프트로 입력 (셸 히스토리에 안 남음)
security add-generic-password -s anthropic -a "$USER" -w -U

# 또는 한 줄로 (히스토리에 남으니 주의)
security add-generic-password -s anthropic -a "$USER" -w "sk-ant-..." -U
```

그다음 `dot_zshrc` 의 9번 섹션에서 해당 줄의 주석을 해제한다:

```bash
_kc_export ANTHROPIC_API_KEY  anthropic
```

`chezmoi apply` 후 새 셸을 열면 적용된다.

### 확인 / 삭제

```sh
security find-generic-password -s anthropic -a "$USER" -w      # 값 확인
security delete-generic-password -s anthropic -a "$USER"       # 삭제
```

### 왜 이 방식인가

`{{ keyring ... }}` 템플릿 함수도 있지만 **쓰지 않는다.** 이건 `chezmoi apply`
시점에 치환되기 때문에, 저장소는 깨끗해도 **디스크의 `~/.zshrc` 에 평문 키가 박힌다.**
런타임 조회는 `.zshrc` 에 조회 명령만 남으므로 그 파일 자체를 공개해도 안전하다.

| 방식 | 저장소 | 디스크 `~/.zshrc` |
|---|---|---|
| `{{ keyring }}` 템플릿 | 참조만 ✅ | **평문 ⚠️** |
| **런타임 조회 (채택)** | 명령만 ✅ | **명령만 ✅** |
| age 암호화 | 암호문 ✅ | 복호화된 평문 ⚠️ |

조회 비용은 키 하나당 약 10ms. 키가 많아지면 지연 로딩으로 바꾼다:

```bash
anthropic_key() { _kc anthropic; }
ANTHROPIC_API_KEY=$(anthropic_key) some-command
```

### 함정 두 가지

1. **`private_` 접두사는 암호화가 아니다.** `private_dot_ssh/config` 는 퍼미션을
   0600 으로 만들라는 뜻일 뿐, 저장소에는 평문 그대로 들어간다.
2. **`chezmoi secret keyring set` 으로 저장하지 말 것.** Go 키링 라이브러리가
   `go-keyring-base64:` 접두사를 붙여 저장해서 셸에서 바로 못 읽는다.
   `security add-generic-password` 로 저장하면 chezmoi 와 셸 양쪽에서 읽힌다.

---

## 되돌리기

원래 설정 백업은 `~/.dotfiles-backup/<타임스탬프>/` 에 있다.
Claude Code 상태줄만 되돌리려면 `~/.claude/settings.json.pre-ccstatusline` 을 참고한다.
