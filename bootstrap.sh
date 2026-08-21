#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  새 맥 셋업 부트스트랩
#
#    curl -fsSL https://raw.githubusercontent.com/rogiry/dotfiles/main/bootstrap.sh | bash
#  또는 저장소를 이미 받았다면:
#    bash bootstrap.sh
#
#  포크해서 쓴다면 저장소를 지정한다:
#    curl -fsSL .../bootstrap.sh | DOTFILES_REPO=you/dotfiles bash
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-rogiry/dotfiles}"

# curl | bash 로 실행하면 stdin 이 "스크립트 본문"이다.
# 이때 `read` 를 그냥 쓰면 사용자 답 대신 **스크립트의 다음 줄**을 먹어서
# 뒤따르는 if 문이 통째로 사라진다 (실제로 그랬다: defaults.sh 가 무조건 실행되고
# 남은 else 가 syntax error 를 냈다). 물어볼 일은 반드시 /dev/tty 에서 읽는다.
# `[ -r /dev/tty ]` 는 퍼미션만 보므로 TTY 가 없어도 참이 된다. 실제로 열어봐야 한다.
has_tty() { { : < /dev/tty; } 2>/dev/null; }

ask_yes_no() {
  local ans=""
  if has_tty; then
    read -r -p "$1" ans < /dev/tty || ans=""
  fi
  [[ "${ans:-n}" =~ ^[Yy]$ ]]
}

echo "==> 1/4  Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

echo "==> 2/4  chezmoi"
command -v chezmoi >/dev/null 2>&1 || brew install chezmoi

echo "==> 3/4  dotfiles 적용  ($DOTFILES_REPO)"
# chezmoi 는 stdin 이 아니라 /dev/tty 를 직접 열어 묻는다. 그래서 curl | bash
# 에서도 프롬프트가 정상 동작한다. 단 TTY 자체가 없으면 실패하므로 먼저 걸러낸다.
if ! has_tty; then
  cat >&2 <<MSG
    ✗ 터미널이 없어 Git 이름/이메일을 물어볼 수 없습니다.
      값을 직접 주고 실행하세요:

        chezmoi init --apply $DOTFILES_REPO \\
          --promptString "Git 사용자 이름=이름" \\
          --promptString "Git 이메일=메일"
MSG
  exit 1
fi
echo "    Git 사용자 이름과 이메일을 물어봅니다."
echo "    이 머신에만 저장되고(~/.config/chezmoi/chezmoi.toml) 저장소에는 올라가지 않습니다."
# init --apply 가 저장소를 받고, run_ 스크립트(brew bundle / mise)를 실행하고,
# 홈 디렉토리에 설정 파일을 전개한다.
chezmoi init --apply "$DOTFILES_REPO"

echo "==> 4/4  macOS 시스템 설정"
SRC="$(chezmoi source-path)"
if ask_yes_no "    Dock/키보드/트랙패드 설정을 적용할까요? [y/N] "; then
  bash "$SRC/macos/defaults.sh"
else
  echo "    건너뜀. 나중에: bash \"$SRC/macos/defaults.sh\""
fi

cat <<'MSG'

────────────────────────────────────────────────────────────
 완료. 남은 수동 작업:

  1. 터미널 재시작          (Nerd Font 적용)
  2. 로그아웃 또는 재시작    (트랙패드 제스처 완전 반영)
  3. bunx ccstatusline@latest   (Claude Code 상태줄 설정 TUI)
     → docs/statusline.md 참고
────────────────────────────────────────────────────────────
MSG
