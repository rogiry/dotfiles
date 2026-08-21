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
