# rogiry / macOS (Apple Silicon)
# 적용: brew bundle --file=Brewfile
# 정리: brew bundle cleanup --file=Brewfile   (Brewfile 에 없는 건 제거 대상으로 표시)

# ── 탭 ───────────────────────────────────────────────────
tap "stablyai/orca"              # Orca (AI 코딩 에이전트 IDE)
tap "manaflow-ai/cmux"           # cmux (Ghostty 기반 터미널)

# ── 셸 / 프롬프트 ─────────────────────────────────────────
brew "starship"                  # 프롬프트
brew "zsh-completions"           # 추가 완성 정의
brew "zsh-autosuggestions"       # 히스토리 기반 인라인 제안
brew "zsh-syntax-highlighting"   # 입력 문법 강조 (.zshrc 맨 마지막에 source)
brew "fzf"                       # 퍼지 파인더
brew "fzf-tab"                   # 탭 완성 메뉴를 fzf 로 대체

# ── 런타임 / 버전 관리 ────────────────────────────────────
brew "mise"                      # bun, node 등 런타임 버전 관리
brew "usage"                     # mise 완성 스크립트 백엔드

# ── 코어 CLI 대체재 ───────────────────────────────────────
brew "fd"                        # find 대체. fzf 의 파일 소스로 사용
brew "bat"                       # cat 대체. fzf 프리뷰 백엔드
brew "ripgrep"                   # grep 대체
brew "zoxide"                    # cd 대체 (z / zi)
brew "eza"                       # ls 대체 (git 상태 + 아이콘)

# ── git / 개발 ───────────────────────────────────────────
brew "gh"                        # GitHub CLI
brew "git-delta"                 # git diff 뷰어
brew "lazygit"                   # git TUI
brew "jq"                        # JSON 처리

# ── 시스템 ───────────────────────────────────────────────
brew "btop"                      # top 대체
brew "tlrc"                      # tldr (예제 중심 man)
brew "chezmoi"                   # 이 dotfiles 자체를 관리

# ── 앱 / 폰트 ────────────────────────────────────────────
# cask 는 설치만 해준다. auto_updates 인 앱은 이후 앱이 스스로 갱신하고
# `brew upgrade --cask` 는 건너뛴다 — 최신인데 다시 받을 이유가 없어서다.
# brew 기준으로 맞추려면 `brew upgrade --cask --greedy`.
#
# 이미 손으로 설치한 앱도 그냥 목록에 넣으면 된다. brew bundle 이 --adopt 를
# 자동으로 붙여서(Homebrew/bundle/cask.rb) 재설치 없이 관리 대상으로 인수한다.
# auto_updates 인 앱은 버전 동일성 검사까지 건너뛰므로 앱이 cask 보다 앞서도 된다.
# 반대로 auto_updates 가 없는 앱(cmux)은 버전이 어긋나면 adopt 가 실패한다.
cask "zed"
cask "visual-studio-code"
cask "google-chrome"
cask "stablyai/orca/orca"
cask "manaflow-ai/cmux/cmux"
cask "font-meslo-lg-nerd-font"   # ~/.config/ghostty/config 가 지정하는 폰트 (cmux 가 읽는다)

# 의도적으로 제외:
#   direnv — mise 가 .mise.toml 로 디렉토리별 env/툴 버전을 이미 처리. 병용 시 로딩 순서 충돌.
