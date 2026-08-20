#!/usr/bin/env bash
# 셸 완성 정의 설치 — 최초 1회만 실행된다.
set -euo pipefail

BREW_PREFIX="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"
SITE="$BREW_PREFIX/share/zsh/site-functions"
mkdir -p "$SITE"

# bun 자체 완성 (mise 로 설치된 bun)
if command -v bun >/dev/null 2>&1; then
  echo "==> bun 완성 설치…"
  bun completions >/dev/null 2>&1 || true
fi

# compinit 이 "insecure directories" 경고를 내는 것을 예방
if [[ -d "$BREW_PREFIX/share" ]]; then
  chmod -R go-w "$BREW_PREFIX/share/zsh" 2>/dev/null || true
fi

# 완성 캐시 디렉토리
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# 오래된 zcompdump 무효화 → 다음 셸 시작 시 재생성
rm -f "$HOME/.zcompdump" 2>/dev/null || true

echo "==> 완료. 새 셸을 열면 완성이 적용됩니다."
