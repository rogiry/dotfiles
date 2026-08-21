# 런타임 (mise)

소스: [`dot_config/mise/config.toml`](../dot_config/mise/config.toml)

## 백엔드 정책: core > aqua > (asdf/vfox 차단)

설정에 `disable_backends = ["asdf", "vfox"]` 가 들어있다.

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
| **asdf/vfox** | 임의 코드를 실행하는 플러그인 백엔드 | 꺼둔다 |

## `node` 는 반드시 core 여야 한다

`aqua:nodejs/node` 로 바꾸면:

- `lts` 별칭을 해석하지 못한다 (빈 결과)
- 노출 버전이 100개뿐이다 (core 는 860개)

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
