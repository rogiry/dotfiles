# dotfiles (chezmoi)

소스: `~/.local/share/chezmoi` · 설정 근거와 실측값은 `README.md` 참고.

## 절대 하지 말 것

- `~/.zshrc` 등 **홈의 파일을 직접 수정 금지** — 다음 `chezmoi apply` 에 덮어써짐.
  소스(`dot_zshrc`)를 고치거나 `chezmoi edit ~/.zshrc` 를 쓸 것.
- `~/.claude/settings.json` 을 **`chezmoi add` 하지 말 것** — Claude Code 가 직접 쓰는
  파일이라 서로 덮어씀. statusLine 스니펫만 README 에 둔다.
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
