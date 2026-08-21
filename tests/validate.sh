#!/usr/bin/env bash
# 저장소 검증 — CI(.github/workflows/ci.yml)와 로컬 Stop 훅이 이 한 파일을 돈다.
#
#   bash tests/validate.sh
#
# 한 파일로 모은 이유: 검사를 양쪽에 따로 적어두면 반드시 갈라진다.
# 도구가 없으면 건너뛰되 건너뛴 사실을 찍는다 — 조용히 통과하면
# 검증했다고 착각하게 된다.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

fails=0
ok()   { printf '  ok    %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }
skip() { printf '  skip  %s — %s 없음\n' "$1" "$2"; }
sec()  { printf '\n== %s\n' "$1"; }

SH_FILES=(bootstrap.sh macos/*.sh .chezmoiscripts/*.sh tests/*.sh
          dot_local/bin/executable_git-status-bits
          dot_local/bin/executable_mise-completions)
ZSH_FILES=(dot_zshrc dot_zprofile create_dot_zshrc.local
           dot_local/share/zsh/functions/_mise_comp_dispatch)

sec "셸 구문"
for f in "${SH_FILES[@]}"; do
  [ -f "$f" ] || continue
  if bash -n "$f" 2>/dev/null; then ok "$f"; else bad "$f"; bash -n "$f"; fi
done
if command -v zsh >/dev/null 2>&1; then
  for f in "${ZSH_FILES[@]}"; do
    [ -f "$f" ] || continue
    if zsh -n "$f" 2>/dev/null; then ok "$f"; else bad "$f"; zsh -n "$f"; fi
  done
else
  skip "zsh 파일 구문" zsh
fi

sec "shellcheck"
if command -v shellcheck >/dev/null 2>&1; then
  if out=$(shellcheck -S warning "${SH_FILES[@]}" 2>&1); then ok "경고 없음"
  else bad "경고 있음"; printf '%s\n' "$out"; fi
else
  skip shellcheck shellcheck
fi

sec "Brewfile"
if command -v ruby >/dev/null 2>&1; then
  # brew 없이 Ruby 파서로 구문만 본다 (따옴표/쉼표 오타를 잡는다).
  if out=$(ruby -c Brewfile 2>&1); then ok "구문 OK"; else bad "구문"; printf '%s\n' "$out"; fi
else
  skip Brewfile ruby
fi

sec "mise 설정"
if command -v mise >/dev/null 2>&1; then
  # TOML 구문 + 훅 키가 살아있는지. 훅이 깨지면 새로 깐 툴의 완성이
  # 조용히 안 생긴다 — 에러가 안 나므로 눈치채기 어렵다.
  if out=$(mise config get -f dot_config/mise/config.toml hooks.postinstall 2>&1); then
    case "$out" in
      *mise-completions*) ok "postinstall 훅" ;;
      *) bad "postinstall 훅이 mise-completions 를 안 부른다: $out" ;;
    esac
  else
    bad "config.toml 파싱"; printf '%s\n' "$out"
  fi
else
  skip "mise 설정" mise
fi

sec "JSON"
while IFS= read -r f; do
  if python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$f" 2>/dev/null; then ok "$f"
  else bad "$f"; python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$f"; fi
done < <(find . -name '*.json' -not -path './.git/*' | sort)

sec "mise 완성 디스패처 동작"
if out=$(bash tests/mise-completions.test.sh 2>&1); then
  ok "$(printf '%s' "$out" | tail -1)"
else
  bad "테스트 실패"; printf '%s\n' "$out" | grep -E 'FAIL|실패'
fi

sec "git-status-bits 동작"
if out=$(bash tests/git-status-bits.test.sh 2>&1); then
  ok "$(printf '%s' "$out" | tail -1)"
else
  bad "테스트 실패"; printf '%s\n' "$out" | grep -E 'FAIL|실패'
fi

sec "chezmoi 템플릿 렌더"
if command -v chezmoi >/dev/null 2>&1; then
  FAKE=$(mktemp -d); OUT=$(mktemp -d)
  trap 'rm -rf "$FAKE" "$OUT"' EXIT
  # 프롬프트는 TTY 를 요구하므로 값을 직접 준다. 이 경로가 깨지면
  # README 에 적어둔 비대화 설치법도 깨진 것이다.
  if HOME="$FAKE" chezmoi init --source="$PWD" \
       --promptString "Git 사용자 이름=ci" \
       --promptString "Git 이메일=ci@example.com" >/dev/null 2>&1; then
    # --format=tar 명시: 기본값 tar.gz 를 GNU tar 가 거부한다.
    if HOME="$FAKE" chezmoi archive --source="$PWD" --destination="$FAKE" \
         --format=tar 2>/dev/null | tar -xf - -C "$OUT"; then
      ok "모든 템플릿 렌더"
      # .chezmoiscripts/*.tmpl 은 {{ }} 때문에 렌더 전엔 구문 검사가 안 된다.
      for f in "$OUT"/.chezmoiscripts/*.sh "$OUT"/.local/bin/*; do
        [ -f "$f" ] || continue
        if bash -n "$f" 2>/dev/null; then ok "렌더됨: ${f#"$OUT"/}"; else bad "렌더됨: ${f#"$OUT"/}"; fi
      done
      if command -v zsh >/dev/null 2>&1; then
        if zsh -n "$OUT/.zshrc" 2>/dev/null; then ok "렌더됨: .zshrc"; else bad "렌더됨: .zshrc"; fi
      fi
    else
      bad "archive 렌더"
    fi
  else
    bad "chezmoi init (템플릿 오류 가능성)"
  fi
else
  skip "템플릿 렌더" chezmoi
fi

sec "개인 정보"
# 이름/이메일은 .chezmoi.toml.tmpl 로 옮겼다. 저장소에 평문으로 다시 들어오면 안 된다.
if hits=$(grep -rn --exclude-dir=.git --exclude-dir=.github --exclude-dir=docs --exclude-dir=.claude \
            --exclude='README.md' --exclude='CLAUDE.md' \
            -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' . \
          | grep -v 'example.com' | grep -v 'noreply'); then
  bad "평문 이메일 발견"; printf '%s\n' "$hits"
else
  ok "평문 이메일 없음"
fi

printf '\n'
if [ "$fails" -eq 0 ]; then echo "검증 통과"; exit 0; fi
echo "검증 실패 $fails 건" >&2
exit 1
