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

## 검증 명령

- `chezmoi diff` — 적용 전 미리보기 / `chezmoi apply -v` — 반영
- `script -q /dev/null zsh -lic 'exit'` — 셸 로드 검증. **`zsh -lic` 만 쓰면
  pty 가 없어 `can't change option: zle` 가짜 경고가 뜬다.**
- `bash macos/capture.sh` — 현재 맥 설정 덤프 (`macos/defaults.sh` 와 대조)
- `brew bundle check --verbose --file=Brewfile`

## 건드리면 깨지는 것

- `dot_zshrc` 의 번호 매긴 섹션은 **로드 순서가 load-bearing**. 재배열 금지.
  fzf-tab 은 compinit 뒤 + 위젯 래핑 플러그인 앞, syntax-highlighting 은 맨 끝.
- mise `node` 는 **core 백엔드 유지**. `aqua:nodejs/node` 는 `lts` 별칭을 해석 못 함.
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

`~/.local/bin/git-status-bits` (모드: `branch` / `commit` / `files` / `wt`).
내장 위젯으로 안 되는 이유가 각각 있다 — 스크립트 상단 주석에 적어뒀다.

- **빈 값 위젯 옆에 `custom-text` 를 두지 말 것.** custom-text 는 항상 렌더돼서,
  git 저장소 밖에서 `  |    | cwd: ~` 처럼 빈 구분자가 남는다.
- **`merge` 속성은 공백을 넣어주지 않는다.** `defaultPaddingSide` 는 Powerline 전용.
  간격이 필요하면 스크립트가 직접 출력해야 한다.
- **`custom-command` 출력은 `.trim()` 된다.** 앞뒤 공백으로 간격을 못 만든다.
  그래서 `commit` 모드가 SHA 와 ✓ 를 함께 출력한다.
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
