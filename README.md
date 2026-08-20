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

새 맥에서는 아래 블록을 `~/.claude/settings.json` 에 직접 넣는다:

```json
{
  "statusLine": {
    "type": "command",
    "command": "$HOME/.local/share/mise/shims/bunx ccstatusline@latest",
    "padding": 0
  }
}
```

그리고 설정 TUI 를 실행한다 (인터랙티브라 스크립트로 못 돌린다):

```sh
bunx ccstatusline@latest
```

결과는 `~/.config/ccstatusline/settings.json` 에 저장된다.
이 파일은 chezmoi 로 관리해도 안전하다:

```sh
chezmoi add ~/.config/ccstatusline/settings.json
```

**성능 메모** (이 맥에서 측정):

| 명령 | 렌더링 시간 |
|---|---|
| `bunx ccstatusline@latest` | ~0.42s (매번 최신 버전 확인) |
| `bunx ccstatusline` | ~0.16s (캐시 사용) |

상태줄이 느리게 느껴지면 `@latest` 를 떼거나 버전을 고정한다 (`ccstatusline@2.2.27`).
stdout 에는 상태줄만, bunx 의 `Resolving dependencies` 잡음은 stderr 로 나가므로
상태줄이 오염되지 않는다. bunx 는 작업 디렉토리에 lockfile 을 쓰지 않는다.

---

## 되돌리기

원래 설정 백업은 `~/.dotfiles-backup/<타임스탬프>/` 에 있다.
Claude Code 상태줄만 되돌리려면 `~/.claude/settings.json.pre-ccstatusline` 을 참고한다.
