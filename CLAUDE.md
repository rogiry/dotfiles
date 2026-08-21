# dotfiles (chezmoi)

소스: `~/.local/share/chezmoi` · 개요는 `README.md`, 설정 근거와 실측값은 `docs/` 참고
(`docs/shell.md` · `docs/runtimes.md` · `docs/macos.md` · `docs/statusline.md` · `docs/secrets.md`).

## 절대 하지 말 것

- `~/.zshrc` 등 **홈의 파일을 직접 수정 금지** — 다음 `chezmoi apply` 에 덮어써짐.
  소스(`dot_zshrc`)를 고치거나 `chezmoi edit ~/.zshrc` 를 쓸 것.
- `~/.claude/settings.json` 을 **`chezmoi add` 하지 말 것** — Claude Code 가 직접 쓰는
  파일이라 서로 덮어씀. statusLine 스니펫만 `docs/statusline.md` 에 둔다.
- `macos/defaults.sh` 를 `.chezmoiscripts/` 로 옮기지 말 것 — `chezmoi apply` 마다
  `killall Dock Finder` 가 돌게 된다. 수동 실행이 의도된 설계.

## 문서 / 저장소 전용 파일

- 설명·근거·실측값은 **README 가 아니라 해당 `docs/*.md`** 에 쓴다.
  README 는 개요·설치·사용법·구조만 유지한다 (예전엔 396줄까지 불었다).
- 저장소에만 둘 최상위 항목은 **`.chezmoiignore` 에 반드시 추가** — 안 넣으면
  `~/docs/` 처럼 홈으로 전개된다. **디렉토리는 이름 한 줄이면 하위가 다 빠진다**
  (기존 `macos/**`, `docs/**` 두 번째 줄은 불필요 — 실측 확인).
- 확인: `chezmoi managed | grep <이름>` — 비어야 정상. `chezmoi diff` 로는 안 잡힌다.

## 검증 명령

- `bash tests/validate.sh` — **저장소 전체 검증. CI 와 Stop 훅이 같은 파일을 돈다.**
  검사를 늘릴 땐 여기 한 곳에만 적을 것.
- `chezmoi diff` — 적용 전 미리보기 / `chezmoi apply -v` — 반영
- `script -q /dev/null zsh -lic 'exit'` — 셸 로드 검증. **`zsh -lic` 만 쓰면
  pty 가 없어 `can't change option: zle` 가짜 경고가 뜬다.**
- `script -q /dev/null zsh -ic 'print ${_comps[bun]}'` — 완성 등록 확인.
  **`compinit -C` 는 새 완성 파일을 못 알아챈다** — `~/.zcompdump` 를 지워야 한다.
- `bash macos/capture.sh` — 현재 맥 설정 덤프 (`macos/defaults.sh` 와 대조)
- `brew bundle check --verbose --file=Brewfile`

## 건드리면 깨지는 것

- `dot_zshrc` 의 번호 매긴 섹션은 **로드 순서가 load-bearing**. 재배열 금지.
  fzf-tab 은 compinit 뒤 + 위젯 래핑 플러그인 앞, syntax-highlighting 은 맨 끝.
- mise `node` 는 **core 백엔드 유지**. `aqua:nodejs/node` 는 `lts` 별칭을 해석 못 함.
- **mise 는 완성 스크립트를 안 깔아준다** (바이너리만). `~/.local/bin/mise-completions`
  가 `~/.local/share/zsh/site-functions` 에 **두 줄짜리 스텁**만 깔고, 실제 정의는
  `_mise_comp_dispatch` 가 TAB 시점의 활성 버전에 맞춰 캐시에서 고른다 (위임형).
  그 디렉토리에 손으로 뭘 두지 말 것 — 매번 갈아엎는다.
  `bun completions` 는 설치 명령이 아니라 **stdout 으로 뱉는 명령**이다
  (`>/dev/null` 로 버린 게 예전 버그).
- **완성 정의 출처 ≠ 바이너리 출처.** `node`/`npm` 은 mise 바이너리인데 완성은
  brew `zsh-completions`(정적, `_node`)와 zsh 배포판(`/usr/share/zsh/5.9/functions/_npm`,
  위임형)에서 온다. `node --completion-bash` / `npm completion` 은 **bash 완성**이라
  생성기가 못 쓴다.
- 디스패처에서 **`unfunction -m` 을 지우지 말 것.** clap 완성 스크립트는 헬퍼를
  `(( $+functions[...] )) ||` 로 감싸서 재정의를 건너뛴다. 안 지우고 source 하면
  최상위 서브커맨드 목록이 이전 버전 것으로 남아 **조용히 틀린 후보**가 뜬다.
- PATH 에서 버전 뽑을 때 **`installs/<툴>/*/bin` 으로 고정하지 말 것.** uv 처럼
  `bin/` 없는 레이아웃이 있다. `latest`/`lts` 는 심볼릭이라 `:A` 로 풀어야 한다.
  (위 둘은 `tests/mise-completions.test.sh` 가 잡는다 — mise·네트워크 불필요.)
- 생성기의 `mise -C "$HOME" ls` 에서 **`-C "$HOME"` 을 빼지 말 것.** `active` 가
  cwd 에 달려 있어 예열되는 버전이 매번 달라진다.
- 트랙패드 설정은 **두 도메인 모두**에 써야 함 (내장 + Magic Trackpad),
  그리고 로그아웃해야 반영됨.

## 로컬 오버라이드

- `~/.zshrc.local` 은 `create_dot_zshrc.local` 로 **최초 1회만 생성**되고
  이후 `apply` 가 절대 안 건드린다. `.chezmoiignore` 에 넣으면 그 생성이
  아예 안 일어나므로 **넣지 말 것.**
  `dot_zshrc` 13번 섹션이 맨 마지막에 읽으므로 **여기서 정의한 것이 항상 이긴다.**
- 머신 전용 alias·환경변수는 여기에. **저장소(`dot_zshrc`)에 넣지 말 것.**
- 시크릿 '값'은 여기에도 두지 않는다 — 9번 섹션 키체인 방식을 쓴다.
- 위젯 감싸는 플러그인은 여기 넣으면 안 된다 (12번 syntax-highlighting 뒤라 충돌).

## 상태줄 git 위젯은 자체 스크립트다

`~/.local/bin/git-status-bits` (모드: `repo` / `branch` / `commit` / `sync` / `files` / `wt`).
내장 위젯으로 안 되는 이유가 각각 있다 — 스크립트 상단 주석에 적어뒀다.

- **빈 값 위젯 옆에 `custom-text` 를 두지 말 것.** custom-text 는 항상 렌더돼서,
  git 저장소 밖에서 `  |    | cwd: ~` 처럼 빈 구분자가 남는다.
- **`merge` 속성은 공백을 넣어주지 않는다.** `defaultPaddingSide` 는 Powerline 전용.
  간격이 필요하면 스크립트가 직접 출력해야 한다.
- **`custom-command` 출력은 `.trim()` 된다.** 앞뒤 공백으로 간격을 못 만든다.
  그래서 `branch` 모드가 브랜치와 동기화 표시(✓/↑↓/⚠)를 함께 출력한다.
  동기화는 브랜치-upstream 관계라 SHA 가 아니라 브랜치에 붙인다.
- **`merge: true` + 빈 위젯 = 구분자를 건너뛴다.** 옵셔널 위젯에 merge 를 걸면
  값이 없을 때 앞뒤가 붙어버린다 (`⎇ main0afd20f✓`).
- `custom-command` 의 cwd 는 ccstatusline 프로세스의 cwd 다. stdin JSON 에서 읽을 것.

## 셸 관련 함정

- `.zprofile` 은 로그인 셸에서만 돈다. `dot_zshrc` 0번 섹션의 brew shellenv
  폴백을 지우면 **차가운 비로그인 셸에서 플러그인이 전부 조용히 안 올라온다.**
- `ls` 는 `eza` alias 라 **`ls -t` / `ls -ltr` 이 깨진다.** 스크립트에서
  최신 파일을 찾을 땐 `/bin/ls -t` 또는 `find` 를 쓸 것.
  (Bash 도구 셸도 사용자 프로파일을 읽어 alias 가 살아있다.)
- `cat`/`grep`/`top` 은 alias 하지 않는다. 특히 `rg` 는 `.gitignore` 와 숨김
  파일을 건너뛰어 **에러 없이 결과가 누락**된다. 전수 검색은 `rg -uuu`.
- 이 맥의 `python3` 은 **3.9.6** — `tomllib` 없음. TOML 파싱은 도구 자체에 시킬 것.
- `timeout` 명령이 없다 (GNU coreutils 미설치).
- `starship config` 는 **에디터를 연다.** 검증에는 `starship prompt` 를 쓸 것.

## ccstatusline 테스트

stdin 에 JSON 을 넣어 렌더한다:

```sh
echo "$PAYLOAD" | ~/.local/share/mise/shims/bunx ccstatusline
```

- **모델 ID 는 반드시 `claude-opus-5[1m]` 처럼 실제 값**을 넣을 것.
  `[1m]` 를 빼면 컨텍스트 창을 200k 로 계산해 퍼센트가 5배 틀리게 나온다.
- 상태줄은 **stdout**, bunx 잡음은 stderr 로 나간다.
- 위젯 렌더 비용은 전부 ~155-190ms 로 동일(bunx 기동시간이 지배).
  **usage 계열은 첫 호출만 ~1.6s 콜드 페치** — 느리다고 판단하기 전에 재측정할 것.
- 값이 항상 비는 위젯: `session-cost`, `cache-read/write/hit-rate`, `extra-usage-*`
