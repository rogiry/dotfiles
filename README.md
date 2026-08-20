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

```
1. brew shellenv          (.zprofile — $HOMEBREW_PREFIX 를 .zshrc 가 참조)
2. mise activate          (PATH 를 바꾸므로 compinit 보다 먼저)
3. FPATH 구성
4. compinit + zstyle
5. fzf-tab                (compinit 다음 & 위젯 래핑 플러그인들보다 먼저)
6. fzf 키바인딩
7. zoxide
8. zsh-autosuggestions
9. starship init
10. zsh-syntax-highlighting   ← 반드시 맨 마지막
```

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

## 되돌리기

원래 설정 백업은 `~/.dotfiles-backup/<타임스탬프>/` 에 있다.
Claude Code 상태줄만 되돌리려면 `~/.claude/settings.json.pre-ccstatusline` 을 참고한다.
