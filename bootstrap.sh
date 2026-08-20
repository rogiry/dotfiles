#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  새 맥 셋업 부트스트랩
#
#    curl -fsSL https://raw.githubusercontent.com/rogiry/dotfiles/main/bootstrap.sh | bash
#  또는 저장소를 이미 받았다면:
#    bash bootstrap.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

GITHUB_USER="rogiry"
REPO="dotfiles"

echo "==> 1/4  Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

echo "==> 2/4  chezmoi"
command -v chezmoi >/dev/null 2>&1 || brew install chezmoi

echo "==> 3/4  dotfiles 적용"
# init --apply 가 저장소를 받고, run_ 스크립트(brew bundle / mise)를 실행하고,
# 홈 디렉토리에 설정 파일을 전개한다.
chezmoi init --apply "$GITHUB_USER/$REPO"

echo "==> 4/4  macOS 시스템 설정"
SRC="$(chezmoi source-path)"
read -r -p "    Dock/키보드/트랙패드 설정을 적용할까요? [y/N] " ans
if [[ "${ans:-n}" =~ ^[Yy]$ ]]; then
  bash "$SRC/macos/defaults.sh"
else
  echo "    건너뜀. 나중에: bash \"$SRC/macos/defaults.sh\""
fi

cat <<'EOF'

────────────────────────────────────────────────────────────
 완료. 남은 수동 작업:

  1. Ghostty 재시작        (Nerd Font 적용)
  2. 로그아웃 또는 재시작    (트랙패드 제스처 완전 반영)
  3. bunx ccstatusline@latest   (Claude Code 상태줄 설정 TUI)
     → README 의 "ccstatusline" 절 참고
────────────────────────────────────────────────────────────
EOF
