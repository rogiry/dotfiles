#!/usr/bin/env bash
# git-status-bits 동작 테스트. 로컬·CI 양쪽에서 돈다.
#
#   bash tests/git-status-bits.test.sh
#
# 이 스크립트가 존재하는 이유: git-status-bits 는 상태줄에만 나타나서
# 깨져도 조용하다. 특히 "빈 출력" 계약(git 저장소가 아니면 아무것도 안 찍는다)이
# 무너지면 저장소 밖에서 구분자가 줄줄이 남는데, 눈으로만 보면 놓치기 쉽다.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/dot_local/bin/executable_git-status-bits"
[ -f "$SCRIPT" ] || { echo "스크립트를 찾을 수 없음: $SCRIPT" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0
# bits <디렉토리> <모드>  — ANSI 를 벗겨서 돌려준다
bits() {
  printf '{"current_dir":"%s"}' "$1" | sh "$SCRIPT" "$2" | sed 's/\x1b\[[0-9;]*m//g'
}
check() { # check <설명> <기대> <실제>
  if [ "$2" = "$3" ]; then
    printf '  ok    %-22s [%s]\n' "$1" "$3"
  else
    printf '  FAIL  %-22s 기대[%s]  실제[%s]\n' "$1" "$2" "$3"
    fails=$((fails + 1))
  fi
}

git config --global --get init.defaultBranch >/dev/null 2>&1 || git config --global init.defaultBranch main
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# ── 고정 저장소 구성 ────────────────────────────────────────
git init -q --bare "$TMP/remote.git"
git clone -q "$TMP/remote.git" "$TMP/w" 2>/dev/null
W="$TMP/w"
( cd "$W" && echo a > a.txt && git add . && git commit -qm first && git push -q origin HEAD:main )
( cd "$W" && git branch -q --set-upstream-to=origin/main 2>/dev/null || true )

check "동기화됨"      "⎇ main ✓"  "$(bits "$W" branch)"
check "sync 단독"     "✓"          "$(bits "$W" sync)"
check "commit 은 SHA" "$(cd "$W" && git rev-parse --short HEAD)" "$(bits "$W" commit)"

# ahead
( cd "$W" && echo b > b.txt && git add . && git commit -qm second )
check "ahead"         "⎇ main ↑1"  "$(bits "$W" branch)"

# behind — 다른 클론에서 밀어넣고 fetch
git clone -q "$TMP/remote.git" "$TMP/other" 2>/dev/null
( cd "$TMP/other" && echo c > c.txt && git add . && git commit -qm third && git push -q origin HEAD:main )
( cd "$W" && git fetch -q )
check "갈라짐"        "⎇ main ↑1↓1" "$(bits "$W" branch)"

# 분리된 HEAD — upstream 개념이 없으므로 표시를 붙이지 않는다
( cd "$W" && git checkout -q --detach HEAD )
check "분리된 HEAD"   "⎇ $(cd "$W" && git rev-parse --short HEAD)" "$(bits "$W" branch)"

# upstream 없는 브랜치
( cd "$W" && git checkout -q - && git checkout -qb noups )
check "upstream 없음" "⎇ noups ⚠"  "$(bits "$W" branch)"

# 연결된 워크트리 — branch 는 항상 ⎇ (표시는 repo 모드가 그린다)
( cd "$W" && git worktree add -q "$TMP/wt" -b wtbranch )
check "워크트리"      "⎇ wtbranch ⚠" "$(bits "$TMP/wt" branch)"
check "wt 모드"       "⑂"           "$(bits "$TMP/wt" wt)"
check "wt 모드(본체)" ""            "$(bits "$W" wt)"

# 파일 상태
( cd "$W" && git checkout -q noups && echo s > staged.txt && git add staged.txt \
  && echo m >> a.txt && echo u > untracked.txt )
check "files"         "S:1 M:1 ?:1" "$(bits "$W" files)"

# ── repo 모드 ───────────────────────────────────────────────
# origin URL 형식별 owner/repo 파싱. 여기서부터는 fetch/push 를 하지 않는다.
# 호스트는 example.com — git@github.com 은 validate.sh 의 평문 이메일 검사에 걸린다.
for url in \
  "git@example.com:rogiry/dotfiles.git" \
  "https://example.com/rogiry/dotfiles.git" \
  "ssh://git@example.com/rogiry/dotfiles" \
  "https://example.com/rogiry/dotfiles/"
do
  ( cd "$W" && git remote set-url origin "$url" )
  check "repo:$url" "rogiry/dotfiles" "$(bits "$W" repo)"
done
# 워크트리는 이름 뒤에 ⑂ 가 붙는다 (config 는 본체와 공유한다)
check "repo 워크트리"  "rogiry/dotfiles ⑂" "$(bits "$TMP/wt" repo)"
# 원격이 없으면 빈 출력 — 내장 위젯의 hideNoRemote 와 같은 계약
( cd "$W" && git remote remove origin )
check "repo 원격 없음" ""            "$(bits "$W" repo)"

# ── 빈 출력 계약 ────────────────────────────────────────────
# git 저장소가 아니면 모든 모드가 아무것도 출력하지 않아야 한다.
mkdir -p "$TMP/plain"
for m in repo branch commit sync files wt; do
  check "저장소 아님:$m" "" "$(bits "$TMP/plain" "$m")"
done
# 존재하지 않는 경로도 마찬가지
check "없는 경로"     ""            "$(bits "$TMP/nope" branch)"
# current_dir 가 아예 없는 JSON
check "current_dir 없음" ""         "$(printf '{}' | sh "$SCRIPT" branch)"

echo
if [ "$fails" -eq 0 ]; then
  echo "모두 통과"
else
  echo "실패 $fails 건" >&2
  exit 1
fi
