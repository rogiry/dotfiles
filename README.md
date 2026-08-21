# dotfiles

macOS 개발 환경을 [chezmoi](https://chezmoi.io) 로 관리한다.
새 맥에서 명령 한 줄이면 셸·런타임·터미널·시스템 설정이 그대로 복원된다.

| 영역 | 구성 |
|---|---|
| 셸 | zsh + starship + fzf-tab + autosuggestions + syntax-highlighting |
| 런타임 | mise (bun, node) |
| 터미널 | cmux (Ghostty 기반) + MesloLGS Nerd Font |
| 도구 | eza, bat, rg, fd, fzf, zoxide, lazygit, gh |
| 시스템 | Dock / 키보드 / 트랙패드 설정 스크립트 |
| 부가 | Claude Code CLI + 상태줄 (ccstatusline) |

## 설치

```sh
curl -fsSL https://raw.githubusercontent.com/rogiry/dotfiles/main/bootstrap.sh | bash
```

수동으로 하려면:

```sh
brew install chezmoi
chezmoi init --apply rogiry/dotfiles
bash "$(chezmoi source-path)/macos/defaults.sh"   # 시스템 설정은 별도 실행
```

설치 중 **Git 사용자 이름과 이메일**을 물어본다. 답은 저장소가 아니라
`~/.config/chezmoi/chezmoi.toml` 에 **머신별로** 저장되므로, 이 저장소를 그대로 써도
자기 이름으로 커밋된다. 기본값은 일부러 두지 않았다 — 엔터만 쳐서 남의 이름으로
커밋하는 사고를 막기 위해서다.

터미널이 없는 곳(CI 등)에서는 값을 직접 준다:

```sh
chezmoi init --apply rogiry/dotfiles \
  --promptString "Git 사용자 이름=이름" --promptString "Git 이메일=메일"
```

설치 후 남는 수동 작업:

1. **터미널 재시작** — Nerd Font 반영
2. **로그아웃 또는 재시작** — 트랙패드 제스처 완전 반영
3. **[상태줄 설정](docs/statusline.md)** — `~/.claude/settings.json` 에 스니펫 추가

## 포크해서 쓰기

개인 설정이지만 그대로 가져다 써도 동작한다 — 개인 식별 정보가 저장소에 없고
설치할 때 물어보기 때문이다. 포크했다면 저장소 주소만 바꾸면 된다:

```sh
curl -fsSL https://raw.githubusercontent.com/rogiry/dotfiles/main/bootstrap.sh \
  | DOTFILES_REPO=you/dotfiles bash
```

취향에 맞게 고칠 곳:

| 파일 | 무엇 |
|---|---|
| `Brewfile` | 설치할 패키지·앱 |
| `macos/defaults.sh` | 시스템 기본값 (이 맥의 스냅샷이다) |
| `dot_config/ghostty/config` | 터미널 폰트·테마 (cmux 가 읽는다) |
| `dot_gitconfig.tmpl` | git alias, 에디터 (`zed --wait`) |
| `bootstrap.sh` | `DOTFILES_REPO` 기본값 |

## 사용법

| 명령 | 하는 일 | alias |
|---|---|---|
| `chezmoi edit ~/.zshrc` | 소스 파일 편집 | `cme` |
| `chezmoi diff` | 적용 전 변경 미리보기 | `cmd` |
| `chezmoi apply` | 홈 디렉토리에 반영 | `cma` |
| `chezmoi cd` | 소스 저장소로 이동 | `cmcd` |
| `chezmoi update` | 원격 pull + apply | |
| `chezmoi add ~/.foo` | 새 파일을 관리 대상에 추가 | |

> [!WARNING]
> **`~/.zshrc` 를 직접 고치지 말 것.** 다음 `chezmoi apply` 에 덮어써진다.
> `chezmoi edit ~/.zshrc` 를 쓰거나 이 저장소의 `dot_zshrc` 를 편집한다.

머신마다 다른 설정은 저장소가 아니라 `~/.zshrc.local` 에 둔다 →
[로컬 오버라이드](docs/shell.md#로컬-오버라이드-zshrclocal)

## 문서

| 문서 | 내용 |
|---|---|
| [docs/shell.md](docs/shell.md) | `.zshrc` 로드 순서, alias 정책, 로컬 오버라이드 |
| [docs/runtimes.md](docs/runtimes.md) | mise 백엔드 정책 (core > aqua, asdf/vfox 차단) |
| [docs/macos.md](docs/macos.md) | 시스템 기본값 스크립트와 drift 확인 |
| [docs/statusline.md](docs/statusline.md) | Claude Code 상태줄 구성과 `git-status-bits` |
| [docs/secrets.md](docs/secrets.md) | API 키를 macOS 키체인으로 다루는 방식 |

각 문서에는 **왜 그렇게 했는지와 실측값**이 함께 들어있다.
설정을 바꾸기 전에 해당 문서를 먼저 읽는 것을 권한다.

## 구조

```
.
├── bootstrap.sh                 새 맥 부트스트랩
├── Brewfile                     brew 패키지 목록
├── .chezmoi.toml.tmpl           init 때 이름/이메일을 물어봄 (답은 저장소 밖)
├── .chezmoidata.toml            저장소 공통 상수
├── .chezmoiignore               저장소에만 두고 홈에 안 뿌릴 것
├── .chezmoiscripts/
│   ├── run_onchange_before_10-brew.sh.tmpl    Brewfile 변경 시 brew bundle
│   ├── run_onchange_after_20-mise.sh.tmpl     mise 설정 변경 시 런타임 설치
│   ├── run_once_after_30-completions.sh       완성 정의 설치 (최초 1회)
│   └── run_once_after_40-claude-code.sh       Claude Code CLI 설치 (없을 때만)
├── dot_zshrc                    →  ~/.zshrc
├── dot_zprofile                 →  ~/.zprofile
├── dot_gitconfig.tmpl           →  ~/.gitconfig  (템플릿)
├── create_dot_zshrc.local       →  ~/.zshrc.local  (최초 1회만 생성)
├── dot_config/
│   ├── starship.toml            →  ~/.config/starship.toml
│   ├── ghostty/config           →  ~/.config/ghostty/config  (cmux 가 읽음)
│   ├── mise/config.toml         →  ~/.config/mise/config.toml
│   ├── bat/config               →  ~/.config/bat/config
│   └── ccstatusline/settings.json  →  ~/.config/ccstatusline/settings.json
├── dot_local/bin/
│   └── executable_git-status-bits  →  ~/.local/bin/git-status-bits
├── macos/
│   ├── defaults.sh              Dock / 키보드 / 트랙패드 설정 적용
│   └── capture.sh               현재 맥 상태 덤프 (drift 확인용)
├── tests/
│   ├── validate.sh              저장소 전체 검증 (CI·Stop 훅이 함께 쓴다)
│   └── git-status-bits.test.sh  상태줄 스크립트 동작 테스트
├── .github/workflows/ci.yml     CI — tests/validate.sh 를 돌린다
├── .claude/settings.json        Stop 훅 — 같은 스크립트를 로컬에서 돌린다
└── docs/                        세부 문서
```

`dot_` → `.`, `create_` → 없을 때만 생성, `executable_` → +x, `.tmpl` → 템플릿 렌더링.
[chezmoi 파일명 규칙](https://chezmoi.io/reference/source-state-attributes/) 참고.

## 검증

| 명령 | 확인하는 것 |
|---|---|
| `chezmoi diff` | 적용될 변경 |
| `script -q /dev/null zsh -lic 'exit'` | 셸이 경고 없이 로드되는지 |
| **`bash tests/validate.sh`** | **아래를 전부 — CI 와 같은 스크립트** |
| `bash tests/git-status-bits.test.sh` | 상태줄 git 위젯 동작 |
| `shellcheck -S warning **/*.sh` | 셸 스크립트 정적 분석 |
| `brew bundle check --verbose --file=Brewfile` | 누락된 패키지 |
| `bash macos/capture.sh` | 현재 맥 설정 (`macos/defaults.sh` 와 대조) |

> `zsh -lic` 만 쓰면 pty 가 없어 `can't change option: zle` 가짜 경고가 뜬다.
> 반드시 `script -q /dev/null` 로 감싼다.

push·PR 마다 [CI](.github/workflows/ci.yml) 가 **같은 `tests/validate.sh`** 를 돌리고,
로컬에서도 Claude Code 의 Stop 훅([.claude/settings.json](.claude/settings.json))이 같은 것을 돌린다.
검사 내용을 한 파일에만 적어두어 "로컬은 통과하는데 CI 만 빨간불" 이 생기지 않게 했다.
**`chezmoi apply` 는 CI 에서 실행하지 않는다** — `run_` 스크립트가 brew bundle 과
Claude Code 설치를 시도해 느리고 불안정하다. 대신 `chezmoi archive` 로
"적용될 결과"를 전부 렌더해 템플릿이 깨지지 않았는지 본다.

## 되돌리기

원래 설정 백업은 `~/.dotfiles-backup/<타임스탬프>/` 에 있다.
Claude Code 상태줄만 되돌리려면 `~/.claude/settings.json.pre-ccstatusline` 을 참고한다.
