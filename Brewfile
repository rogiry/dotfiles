# rogiry / macOS (Apple Silicon)
# 적용: brew bundle --file=Brewfile
# 정리: brew bundle cleanup --file=Brewfile   (Brewfile 에 없는 건 제거 대상으로 표시)

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
cask "zed"
cask "font-meslo-lg-nerd-font"   # Ghostty 폰트. starship/ccstatusline 아이콘용

# 의도적으로 제외:
#   direnv — mise 가 .mise.toml 로 디렉토리별 env/툴 버전을 이미 처리. 병용 시 로딩 순서 충돌.
