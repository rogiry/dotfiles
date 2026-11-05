#!/usr/bin/env bash
# mise 설치 — 최초 1회, 없을 때만.
#
# 왜 Brewfile 의 mise 를 안 쓰나:
#   - brew 판은 패키저가 self-update 를 막아둔다. `mise self-update` 가 거부되고
#     `brew upgrade mise` 로만 올릴 수 있다. 공식 설치 스크립트(mise.run)로 깐
#     바이너리는 self-update 가 되고, 릴리스 서명도 검증한다.
#   - 설치 위치는 ~/.local/bin/mise — dot_zshrc 12번 줄이 이미 PATH 에 넣는다.
#   - 설치 스크립트는 GitHub 릴리스에서 받아 sha256 을 검증한다. 셸 rc 파일은
#     건드리지 않고 "이걸 .zshrc 에 넣어라" 는 안내만 출력한다
#     (활성화는 dot_zshrc 1번 섹션이 이미 한다).
#   - 최신 릴리스가 나온 지 24시간 안이면 직전 릴리스를 깐다 (스크립트의 기본 정책).
set -euo pipefail

# chezmoi 스크립트는 비대화 셸이라 .zshrc 를 읽지 않는다 → PATH 에 ~/.local/bin 이
# 없을 수 있다. command -v 만 믿지 말고 실제 경로도 본다.
if command -v mise >/dev/null 2>&1 || [ -x "$HOME/.local/bin/mise" ]; then
  echo "==> mise 이미 설치됨. 건너뜁니다."
  exit 0
fi

echo "==> mise 설치 중…"
if ! curl -fsSL https://mise.run | sh; then
  echo "!! mise 설치 실패. 네트워크를 확인하고 직접 실행하세요:" >&2
  echo "   curl https://mise.run | sh" >&2
  exit 1
fi

echo "==> 완료. 새 셸에서 'mise' 를 쓸 수 있습니다."
