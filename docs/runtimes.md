# 런타임 (mise)

소스: [`dot_config/mise/config.toml`](../dot_config/mise/config.toml)

## 백엔드 정책: core > aqua > vfox/asdf (마지막 수단)

`disable_backends` 는 **쓰지 않는다.** asdf(bash)와 vfox(Lua) 모두 제3자 플러그인 코드를
내 권한으로 실행하므로 어느 쪽도 보안 경계가 아니다 — asdf 만 막아도 vfox 가 열려 있으면
실질 보호는 늘지 않는다. 실제 보호는 **core/aqua 를 먼저 쓰는 것**(체크섬·서명 검증,
플러그인 코드 없음)에서 나온다.

mise 레지스트리는 이미 이 우선순위를 반영한다:

```
bun     -> core:bun                                       core 가 있으면 core 만
node    -> core:node
jq      -> aqua:jqlang/jq        asdf:mise-plugins/asdf-jq  core 없으면 aqua 가 1순위
lazygit -> aqua:jesseduffield/lazygit   asdf:...
```

| 백엔드 | 성격 | 쓰는 이유 |
|---|---|---|
| **core** | mise 내장 구현 | 언어별 특수사항 처리 — `lts` 별칭, `.node-version` 인식, `npm`/`npx`/`corepack` 심 생성, 소스 빌드 |
| **aqua** | 체크섬·서명이 검증되는 범용 바이너리 레지스트리 | core 가 없는 툴의 1순위 |
| **vfox/asdf** | 제3자 플러그인 코드를 실행하는 백엔드 | 마지막 수단. 막지는 않는다 |

일부 툴은 레지스트리에서 vfox 가 aqua 보다 앞이라 단축명으로 쓰면 vfox 로 깔린다.
`dot_config/mise/config.toml` 주석에 목록이 있다 — aqua 를 원하면 `aqua:` 를 명시한다.

## `node` 는 반드시 core 여야 한다

`aqua:nodejs/node` 로 바꾸면:

- `lts` 별칭을 해석하지 못한다 (빈 결과)
- 노출 버전이 100개뿐이다 (core 는 860개)

## mise 자체는 brew 가 아니라 공식 스크립트로 깐다

[`.chezmoiscripts/run_once_before_15-mise.sh`](../.chezmoiscripts/run_once_before_15-mise.sh)
가 `curl https://mise.run | sh` 로 `~/.local/bin/mise` 에 깐다 (없을 때만).
`Brewfile` 에 `brew "mise"` 를 되살리지 말 것.

- **이유:** brew 판은 패키저가 `self-update` 를 막아둔다 (`brew upgrade mise` 로만 올림).
  공식 스크립트판은 `mise self-update` 가 되고 릴리스 서명을 검증한다.
- 업데이트: `mise self-update`. 릴리스 후 24시간이 안 지난 버전은 건너뛴다(기본 정책).
- `~/.local/bin` 은 `dot_zshrc` 12번 줄이 PATH 에 넣는다. chezmoi 스크립트는 비대화 셸이라
  `.zshrc` 를 안 읽으므로 20·30번 스크립트가 PATH 를 직접 잡는다.
- **mise 바이너리 위치를 옮기면 `mise reshim --force` 를 한 번 돌린다.**
  `~/.local/share/mise/shims/*` 는 mise 바이너리로 향하는 심볼릭 링크라, 옛 경로
  (`/opt/homebrew/bin/mise`)를 지우면 전부 깨진다. ccstatusline 이 `shims/bunx` 를
  부르므로 상태줄이 통째로 안 나온다 (brew → 공식 스크립트로 옮긴 날 실제로 겪음).
- `mise` 자신의 완성(`_mise`)도 brew 판이 깔아주던 것이라, 이제는 `mise-completions` 가
  `mise completion zsh` 로 같이 만든다.

## 런타임 설치 시점

[`.chezmoiscripts/run_onchange_after_20-mise.sh.tmpl`](../.chezmoiscripts/run_onchange_after_20-mise.sh.tmpl)
이 mise 설정 해시를 추적한다. `config.toml` 이 바뀐 `chezmoi apply` 에서만 설치가 돈다.

## 툴 완성은 mise 가 안 깔아준다

**mise 는 바이너리만 깐다.** brew 와 달리 완성 스크립트를 site-functions 로
옮겨주는 단계가 없어서, 그냥 두면 `bun`/`uv` 는 탭 완성이 통째로 없다.

그래서 설정에 훅을 걸어둔다:

```toml
[hooks]
postinstall = '! [ -x "$HOME/.local/bin/mise-completions" ] || "$HOME/.local/bin/mise-completions" --quiet'
```

`mise install` / `mise use` 로 툴이 깔릴 때마다
[`mise-completions`](../dot_local/bin/executable_mise-completions) 가 돈다.
**`mise use -g deno` 한 번이면 완성까지 따라온다.**

- 훅은 `sh -c -o errexit` 로 돈다. `~` 확장이 안 되므로 `$HOME` 을 쓴다.
- 스크립트가 없는 머신에서 mise 가 WARN 을 뱉지 않도록 `-x` 로 먼저 거른다.

### 프로젝트마다 버전이 달라도 완성이 따라간다

생성기가 깔아두는 건 두 줄짜리 스텁이고, 실제 완성 정의는
[`_mise_comp_dispatch`](../dot_local/share/zsh/functions/_mise_comp_dispatch) 가
**TAB 시점에 활성화된 버전**을 보고 고른다. mise 의 `chpwd` 훅이 PATH 를 바꾸면
완성도 같이 바뀐다.

원리·비용 측정·함정은
[docs/shell.md 의 「프로젝트마다 툴 버전이 다르면」](shell.md#프로젝트마다-툴-버전이-다르면--완성도-따라간다).
