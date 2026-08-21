#!/usr/bin/env bash
# _mise_comp_dispatch 동작 테스트. 로컬·CI 양쪽에서 돈다.
#
#   bash tests/mise-completions.test.sh
#
# 이 스크립트가 존재하는 이유: 완성은 깨져도 조용하다. 후보가 안 뜨거나
# 엉뚱한 버전의 후보가 떠도 에러가 없다. 실제로 만들면서 두 번 물렸다:
#
#   1) PATH 모양이 툴마다 다르다. installs/<툴>/<버전>/bin 만 보면
#      uv 처럼 bin/ 없는 레이아웃(installs/uv/0.9.0/uv-aarch64-apple-darwin)을
#      놓친다. latest·lts 는 심볼릭이라 풀어야 진짜 버전이 나온다.
#   2) clap 이 만든 완성 스크립트는 헬퍼를
#          (( $+functions[_uv_commands] )) || _uv_commands() { ... }
#      로 감싼다. 이미 있으면 다시 정의하지 않으므로, 지우지 않고 source 하면
#      진입 함수만 바뀌고 '최상위 서브커맨드 목록'은 이전 버전 것이 남는다.
#
# mise 도 네트워크도 필요 없다 — 가짜 install 트리와 가짜 캐시로만 돈다.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FN_DIR="$REPO_ROOT/dot_local/share/zsh/functions"
[ -f "$FN_DIR/_mise_comp_dispatch" ] || { echo "디스패처를 찾을 수 없음" >&2; exit 1; }
command -v zsh >/dev/null 2>&1 || { echo "  skip  zsh 없음"; exit 0; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

INST="$TMP/.local/share/mise/installs"
CACHE="$TMP/.cache/zsh/mise-completions"
mkdir -p "$CACHE"

# 가짜 install 트리 — 레이아웃 세 가지를 모두 만든다
mkdir -p "$INST/faketool/1.0.0/bin" "$INST/faketool/2.0.0/bin"   # bin/ 있는 형태
mkdir -p "$INST/nobin/3.0.0/nobin-aarch64-apple-darwin"          # bin/ 없는 형태
ln -s ./2.0.0 "$INST/faketool/latest"                            # 별칭 심볼릭

# 가짜 완성 캐시 — 진짜 clap 출력처럼 헬퍼를 $+functions 로 감싼다
mk_cache() { # mk_cache <바이너리> <버전> <표식>
  cat > "$CACHE/$1@$2" <<CACHE_EOF
#compdef $1
(( \$+functions[_$1_commands] )) ||
_$1_commands() { print -r -- "list=$3" }
_$1() { print -r -- "entry=$3 helper=\$(_$1_commands)" }
CACHE_EOF
}
mk_cache faketool 1.0.0 V1
mk_cache faketool 2.0.0 V2
mk_cache nobin    3.0.0 N3

fails=0
check() { # check <설명> <기대> <실제>
  if [ "$2" = "$3" ]; then printf '  ok    %-34s [%s]\n' "$1" "$3"
  else printf '  FAIL  %-34s 기대[%s] 실제[%s]\n' "$1" "$2" "$3"; fails=$((fails + 1)); fi
}

# zsh 안에서 디스패처를 돌리고 한 줄씩 결과를 뱉는다.
run_zsh_ok() { run_zsh "$@" || true; }
run_zsh() {
  HOME="$TMP" zsh -f -c "
    fpath=($FN_DIR \$fpath)
    autoload -Uz _mise_comp_dispatch
    setopt no_nomatch
    $1
  " 2>/dev/null
}

echo "== 버전 탐지"
out=$(run_zsh_ok '
  path=('"$INST"'/faketool/1.0.0/bin /usr/bin /bin)
  _mise_comp_dispatch faketool faketool
  print -r -- "LOADED=$_mise_comp_loaded[faketool]"
')
check "bin/ 있는 레이아웃 — 진입"      "entry=V1 helper=list=V1" "$(printf '%s' "$out" | sed -n 1p)"
check "bin/ 있는 레이아웃 — 버전"      "LOADED=1.0.0"        "$(printf '%s' "$out" | sed -n 2p)"

out=$(run_zsh_ok '
  path=('"$INST"'/nobin/3.0.0/nobin-aarch64-apple-darwin /usr/bin /bin)
  _mise_comp_dispatch nobin nobin >/dev/null
  print -r -- "LOADED=$_mise_comp_loaded[nobin]"
')
check "bin/ 없는 레이아웃"             "LOADED=3.0.0"        "$out"

out=$(run_zsh_ok '
  path=('"$INST"'/faketool/latest/bin /usr/bin /bin)
  _mise_comp_dispatch faketool faketool >/dev/null
  print -r -- "LOADED=$_mise_comp_loaded[faketool]"
')
check "latest 심볼릭을 실제 버전으로"  "LOADED=2.0.0"        "$out"

echo
echo "== 버전 갈아타기 (한 셸 안에서)"
out=$(run_zsh_ok '
  path=('"$INST"'/faketool/1.0.0/bin /usr/bin /bin)
  _mise_comp_dispatch faketool faketool
  path=('"$INST"'/faketool/2.0.0/bin /usr/bin /bin)
  _mise_comp_dispatch faketool faketool
  path=('"$INST"'/faketool/1.0.0/bin /usr/bin /bin)
  _mise_comp_dispatch faketool faketool
')
check "1) 처음"                        "entry=V1 helper=list=V1" "$(printf '%s' "$out" | sed -n 1p)"
check "2) 갈아탄 뒤 (헬퍼까지)"        "entry=V2 helper=list=V2" "$(printf '%s' "$out" | sed -n 2p)"
check "3) 되돌아온 뒤"                 "entry=V1 helper=list=V1" "$(printf '%s' "$out" | sed -n 3p)"

out=$(run_zsh_ok '
  path=('"$INST"'/faketool/1.0.0/bin /usr/bin /bin)
  _mise_comp_dispatch faketool faketool >/dev/null
  [[ ${functions[_faketool]} == *"_mise_comp_dispatch faketool faketool"* ]] && print 예 || print 아니오
')
check "호출 뒤에도 스텁이 디스패처"    "예" "$out"

echo
echo "== 캐시 미스 → 생성기 호출"
mkdir -p "$TMP/.local/bin"
cat > "$TMP/.local/bin/mise-completions" <<'GEN_EOF'
#!/bin/sh
# --emit <툴> <바이너리> <버전>
[ "$1" = "--emit" ] || exit 2
printf '#compdef %s\n_%s() { print -r -- "emitted=%s@%s" }\n' "$3" "$3" "$3" "$4"
GEN_EOF
chmod +x "$TMP/.local/bin/mise-completions"
out=$(run_zsh_ok '
  path=('"$INST"'/faketool/2.0.0/bin /usr/bin /bin)
  _mise_comp_dispatch faketool newbin
')
check "없는 캐시를 --emit 로 만든다"   "emitted=newbin@2.0.0"  "$out"
check "만든 것을 캐시에 남긴다"        "있음" \
      "$([ -s "$CACHE/newbin@2.0.0" ] && echo 있음 || echo 없음)"

echo
if [ "$fails" -eq 0 ]; then
  echo "모두 통과"
else
  echo "실패 $fails 건" >&2
  exit 1
fi
