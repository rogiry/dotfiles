#!/usr/bin/env bash
# Claude Code CLI 설치 — 최초 1회, 없을 때만.
#
# 왜 Brewfile 의 claude-code cask 를 안 쓰나:
#   - 그 cask 는 auto_updates 를 선언하지 않아 brew 가 버전을 책임진다. 그런데
#     네이티브 설치본은 자체 업데이터로 계속 앞서간다 (실측: 2.1.238 vs cask 2.1.228).
#   - PATH 는 ~/.local/bin 이 /opt/homebrew/bin 보다 먼저다 (dot_zshrc 12번 줄).
#     brew 판을 깔아도 가려져서 실행되지 않는, 안 쓰는 구버전만 하나 더 생긴다.
#
# 설치 스크립트는 셸 rc 파일을 건드리지 않는다 (확인함). ~/.local/bin/claude 심링크만
# 만들고, 그 경로는 dot_zshrc 가 이미 PATH 에 넣으므로 chezmoi 관리와 충돌하지 않는다.
# 다운로드는 manifest.json 의 SHA256 으로 검증되고, sudo 를 거부한다.
set -euo pipefail

# chezmoi 스크립트는 비대화 셸이라 .zshrc 를 읽지 않는다 → PATH 에 ~/.local/bin 이
# 없을 수 있다. command -v 만 믿지 말고 실제 경로도 본다.
if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ]; then
  echo "==> Claude Code 이미 설치됨. 건너뜁니다."
  exit 0
fi

echo "==> Claude Code 설치 중…"
if ! curl -fsSL https://claude.ai/install.sh | bash; then
  echo "!! Claude Code 설치 실패. 네트워크를 확인하고 직접 실행하세요:" >&2
  echo "   curl -fsSL https://claude.ai/install.sh | bash" >&2
  exit 1
fi

echo "==> 완료. 새 셸에서 'claude' 를 쓸 수 있습니다."
