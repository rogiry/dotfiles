# 셸 (zsh)

- 소스: [`dot_zshrc`](../dot_zshrc), [`dot_zprofile`](../dot_zprofile)
- 로컬 오버라이드 템플릿: [`create_dot_zshrc.local`](../create_dot_zshrc.local)

## `.zshrc` 로드 순서

**순서를 바꾸면 조용히 깨진다.** `dot_zshrc` 의 번호 매긴 섹션은 아래 순서를 그대로 따른다.

```
   brew shellenv          (.zprofile — 로그인 셸에서만)
0. brew shellenv 폴백     ($HOMEBREW_PREFIX 가 비었을 때만. 아래 설명)
1. mise activate          (PATH 를 바꾸므로 compinit 보다 먼저)
2. 히스토리 옵션
3. 디렉토리 / 일반 옵션
4. FPATH + compinit + zstyle
5. fzf-tab                (compinit 다음 & 위젯 래핑 플러그인들보다 먼저)
6. fzf 키바인딩
7. zoxide
8. zsh-autosuggestions
9. 시크릿 (키체인 조회)   ← 순서 무관. 편의상 여기
10. alias
11. starship init
12. zsh-syntax-highlighting   ← 반드시 맨 마지막
13. ~/.zshrc.local            ← 있으면 source. 여기서 정의한 것이 항상 이긴다
```

순서가 실제로 중요한 건 **0 → 1 → 4 → 5 → 6·7·8 → 11 → 12** 구간이다.
2·3·9·10 은 어디에 있어도 되지만, 번호를 유지해야 diff 가 읽기 쉽다.

### 0번(Homebrew 폴백)이 왜 필요한가

`.zprofile` 은 **로그인 셸에서만** 실행된다. 부모 환경을 물려받지 못한
차가운 비로그인 셸(cron, `ssh host zsh -i`, 일부 터미널 설정)에서는
`$HOMEBREW_PREFIX` 가 비고, 그러면 아래 플러그인 로드가 **에러 없이 전부 건너뛰어진다.**

실측한 증상:

```
비로그인 셸 (폴백 전):  HOMEBREW_PREFIX=[]  fzf-tab=0 autosuggest=0 syntax-hl=0 starship=INACTIVE
비로그인 셸 (폴백 후):  HOMEBREW_PREFIX=[/opt/homebrew]  fzf-tab=1 autosuggest=1 syntax-hl=1 starship=active
```

### 검증

```sh
script -q /dev/null zsh -lic 'exit'
```

`zsh -lic` 만 쓰면 pty 가 없어 `can't change option: zle` 가짜 경고가 뜬다.

---

## 탭 완성이 어디서 오는가

완성 정의는 다섯 군데에서 온다. 전부 **compinit 보다 먼저** FPATH 에 들어가야 한다
(`dot_zshrc` 4번 섹션. `/usr/share/zsh/*/functions` 는 zsh 의 기본 FPATH 라 그냥 있다).

| 경로 | 채우는 주체 | 예 |
|---|---|---|
| `$HOMEBREW_PREFIX/share/zsh/site-functions` | brew 가 포뮬러 설치할 때 | `_mise` `_gh` `_chezmoi` `_eza` |
| `$HOMEBREW_PREFIX/share/zsh-completions` | `zsh-completions` 포뮬러 | `_node` |
| `/usr/share/zsh/5.9/functions` | zsh 배포판 자체 (macOS 기본, FPATH 기본값) | `_npm` |
| `~/.local/share/zsh/functions` | **이 저장소** (chezmoi) | `_mise_comp_dispatch` |
| `~/.local/share/zsh/site-functions` | **`mise-completions` 가 생성** | `_bun` `_uv` `_uvx` (스텁) |

> [!IMPORTANT]
> **바이너리 출처와 완성 정의 출처는 별개다.** `node`/`npm` 은 mise 가 깐
> 바이너리인데 완성 정의는 mise 와 아무 상관 없는 데서 온다 (실측):
>
> ```
> node 바이너리 →  ~/.local/share/mise/installs/node/lts/bin/node   (mise)
> _node         →  /opt/homebrew/share/zsh-completions/_node        (brew, 정적)
> _npm          →  /usr/share/zsh/5.9/functions/_npm                (zsh 자체, 위임형)
> _npx          →  없음
> ```
>
> `mise-completions` 가 `_node`/`_npm` 을 만들지 못하는 이유:
> `node --completion-bash` 와 `npm completion` 은 **bash 완성**을 뱉는다.
> zsh 완성이 아니라서 검증 단계에서 걸러진다.

### mise 로 깐 툴은 왜 완성이 없었나

**mise 는 툴의 바이너리만 깐다.** brew 와 달리 완성 스크립트를 site-functions 로
옮겨주는 단계가 아예 없다. install 디렉토리에 완성 파일이 하나도 없다:

```
find ~/.local/share/mise/installs \( -path '*zsh/site-functions*' -o -path '*/completions/_*' \)
  →  0개
```

`mise` 자신은 완성이 되는데(brew 가 `_mise` 를 깔아준다) mise 로 깐 툴만 안 되니
"mise 완성이 반쯤 되는" 것처럼 보인다. 실측한 `compdef` 등록 상태 (수정 전):

```
mise -> _mise     node -> _node     npm -> _npm       ← brew·zsh 가 깔아준 것
bun  -> (없음)    uv   -> (없음)    uvx  -> (없음)    ← mise 가 깐 것
```

여기에 더해, 예전 `run_once_after_30-completions.sh` 는 이렇게 돼 있었다:

```sh
bun completions >/dev/null 2>&1 || true     # ← 완성 스크립트를 그대로 버린다
```

`bun completions` 는 설치해 주는 명령이 아니라 **완성 스크립트를 stdout 으로
뱉는 명령**이다 (1038줄). `>/dev/null` 이 그걸 버렸고, 에러도 안 났다.
게다가 `run_once` 라 나중에 `mise use -g deno` 로 툴을 더 넣어도 다시 돌지 않았다.

---

## 프로젝트마다 툴 버전이 다르면 — 완성도 따라간다

**툴 자체(PATH)는 mise 가 맞춘다.** `mise activate zsh` 가 `chpwd`·`precmd` 훅을
걸어서 디렉토리를 옮길 때마다 PATH 를 바꾼다 (`dot_zshrc` 1번 섹션).

**완성 정의도 따라가게 만들어 뒀다.** 완성 정의가 만들어지는 방식은 세 가지인데,
버전을 따라가는 건 **위임형**뿐이다:

| 방식 | 버전을 따라가나 | 예 |
|---|---|---|
| **위임형** — 완성하는 시점에 '지금 활성화된' 정의를 쓴다 | ✅ | `_npm` (zsh 기본), `_bun` `_uv` `_uvx` (이 저장소) |
| 정적 — 패키지에 박제돼 있음 | ❌ | `_node` (`zsh-completions` 0.36.0) |
| 생성형(고정) — 한 버전에서 뽑아 전역 파일 하나로 | ❌ | 안 쓴다 (아래 캐시는 버전별이라 다르다) |

`_node` 가 정적의 예다. node 24.19.0 에 있는 플래그가 `_node` 에는 없다:

```
--run  --watch  --env-file  --test        _node ✓   node 24.19.0 ✓
--experimental-strip-types                _node ✗   node 24.19.0 ✓
```

버전 차이는 작지 않다. uv 로 실측(0.9.0 vs 0.12.5):

```
완성 스크립트 줄수   5603  →  6978
서로 다른 옵션 개수   283  →   322      (39개가 새 버전에만 있음)
```

### 위임의 원본: zsh 가 기본 제공하는 `_npm`

`/usr/share/zsh/5.9/functions/_npm` 은 14줄이 전부다:

```zsh
if (( $+commands[npm] )); then
  eval "$(NPM_CONFIG_UPDATE_NOTIFIER=false npm completion)"   # ← 지금 PATH 의 npm 에게 물어봄
  ...
```

그래서 `npm` 완성은 프로젝트 버전을 정확히 따라간다. 대신 **TAB 마다 서브프로세스**를
돈다 (실측 63ms).

### 이 저장소가 하는 것: 위임 + 버전별 캐시

FPATH 에 깔리는 건 두 줄짜리 **스텁**뿐이다 (134바이트):

```zsh
# ~/.local/share/zsh/site-functions/_uvx
#compdef uvx
_mise_comp_dispatch uv uvx "$@"
```

실제 정의는 [`_mise_comp_dispatch`](../dot_local/share/zsh/functions/_mise_comp_dispatch)
가 고른다:

1. **활성 버전을 알아낸다** — `$path` 에서 `*/mise/installs/<툴>/*` 를 찾아
   `${d:A}` 로 심볼릭을 푼다. **서브프로세스 0개.**
   PATH 에 없으면 `mise current <툴>` (12ms), 그것도 없으면 캐시에 있는 최신 버전.
2. **캐시를 본다** — `~/.cache/zsh/mise-completions/<바이너리>@<버전>`.
   없으면 `mise-completions --emit` 이 만든다 (**버전당 최초 1회**).
3. 이전 버전 함수를 지우고 `source` 한 뒤, 진입 함수는 따로 보관하고
   스텁 자리는 디스패처로 되돌린다 (다음에 또 갈아탈 수 있도록).

비용 (실측):

| 상황 | 비용 |
|---|---|
| 셸 시작 | 영향 없음 — 스텁 있음 77ms / 없음 77ms (5회 평균) |
| 버전이 안 바뀐 TAB | 0 (이미 로드된 함수 호출) |
| 버전이 바뀐 뒤 첫 TAB | `_uv` 6978줄 source 33ms / `_bun` 1038줄 15ms |
| 처음 보는 버전의 첫 TAB | 완성 스크립트 생성 (한 번만, 이후 캐시) |
| (비교) zsh 기본 `_npm` | **TAB 마다** 63ms |

실측 — uv 0.9.0 프로젝트와 0.12.5 프로젝트를 한 셸 안에서 오가며
(`workspace` 는 0.12.5 에만 있는 서브커맨드):

```
projB(0.12.5)   uv wo + TAB  →  uv workspace
projA(0.9.0)    uv wo + TAB  →  uv wo          ← 그 버전엔 없으니 완성 안 됨
projB(0.12.5)   uv wo + TAB  →  uv workspace
projA(0.9.0)    uv ru + TAB  →  uv run
```

### 만들면서 두 번 물린 것

둘 다 **에러 없이 조용히 틀린 결과**를 냈다. `tests/mise-completions.test.sh` 가
회귀를 잡는다 (mise 도 네트워크도 없이 가짜 install 트리로 돈다).

**1. PATH 모양이 툴마다 다르다.** `installs/<툴>/<버전>/bin` 만 보면 안 된다:

```
~/.local/share/mise/installs/bun/latest/bin                    ← bin/ 있음, 별칭 심볼릭
~/.local/share/mise/installs/uv/0.9.0/uv-aarch64-apple-darwin   ← bin/ 없음
```

`installs/<툴>/` **바로 다음 조각**을 꺼내고, `latest`·`lts` 는 `:A` 로 먼저 풀어야
진짜 버전이 나온다 (`installs/bun/latest -> ./1.3.14`).

**2. clap 이 만든 완성 스크립트는 헬퍼를 재정의하지 않는다.**

```zsh
(( $+functions[_uv_commands] )) ||
_uv_commands() { ... }              # ← 이미 있으면 건너뛴다
```

그래서 지우지 않고 `source` 하면 진입 함수 `_uv` 만 바뀌고 헬퍼는 이전 버전
것이 남는다. 그 헬퍼 중 `_uv_commands` 가 **최상위 서브커맨드 목록**이라,
0.12.5 를 쓰던 셸에서 0.9.0 프로젝트로 가도 `uv wo` 가 `workspace` 로 완성됐다.
`unfunction -m "_<바이너리>" "_<바이너리>_*"` 로 먼저 지운다
(`_uv_*` 는 `_uvx` 를 건드리지 않는다).

### 예열은 전역 config 기준으로 고정

생성기는 `mise install` 뒤에 훅으로 불려서 **전역 config 가 정한 버전**의 캐시를
미리 만들어 둔다. `mise ls` 의 `active` 는 cwd 에 따라 달라지므로
`mise -C "$HOME" ls` 로 못박는다 — 안 그러면 어느 프로젝트에서 `mise install` 했느냐에
따라 예열되는 버전이 매번 달라진다. (프로젝트 버전은 디스패처가 TAB 시점에 처리하므로
예열은 "흔한 경우를 빠르게" 하는 용도일 뿐이다.)

### 함정

- **`compinit -C` 는 새 완성 파일을 알아채지 못한다.** 4번 섹션은 덤프가 하루
  이내면 `-C` 로 뜬다. 그래서 덤프를 두 군데서 무효화한다:
  - 생성기 — **스텁 목록이 바뀌었을 때만**. 버전만 달라진 경우엔 스텁이 그대로라
    지울 필요가 없다.
  - `run_onchange_after_30-completions` — **조건 없이**. 생성기는 자기 스텁만
    비교할 뿐 **FPATH 구성이 바뀐 것은 모른다.** 실제로 `~/.local/share/zsh/functions`
    를 FPATH 에 새로 추가한 `apply` 에서 스텁이 그대로였던 탓에 덤프가 남았고,
    `compinit -C` 가 그걸 써서 `_mise_comp_dispatch` 가 등록되지 않았다 —
    완성이 통째로 죽었는데 에러는 없었다.

  FPATH 블록을 손으로 고쳤다면 똑같이 `rm ~/.zcompdump` 를 해야 한다.
- **brew prefix 밑에 쓰지 않는다.** brew 가 관리하는 트리라 포뮬러 재설치나
  `brew cleanup` 때 사라지고, `brew doctor` 가 남의 파일이라고 경고한다.
- `~/.local/share/zsh/site-functions` 는 **매번 갈아엎는다.** 여기에 손으로 뭘 두면
  다음 실행에 사라진다. 직접 관리할 완성은 brew site-functions 에.
- 캐시(`~/.cache/zsh/mise-completions`)는 지워도 된다. 다음 TAB 에 다시 만든다.
- 표에 없는 툴은 `completions zsh` 같은 관용 형태를 차례로 시도한다. 결국 모르는
  서브커맨드를 실행하는 것이라 20초 제한을 직접 건다 (이 맥엔 `timeout` 이 없다).

### 검증

```sh
mise-completions -v                                     # 툴별로 무엇을 만들었는지
bash tests/mise-completions.test.sh                     # 디스패처 회귀 테스트
script -q /dev/null zsh -ic 'print ${_comps[bun]}'      # → _bun
```

---

## alias 정책: 원본 명령을 덮어쓰지 않는다

`cat`/`grep`/`top` 은 **일부러 alias 하지 않는다.** 대체 도구가 드롭인이 아니라서
원본 플래그가 깨지거나, 더 나쁘게는 **에러 없이 결과가 달라진다.**

실측한 것:

| 명령 | `bat`/`rg`/`btop` 로 alias 했을 때 |
|---|---|
| `cat -v`, `cat -e` | ✗ `error: unexpected argument` |
| `grep -E "a\|b"` | ✗ rg 는 기본이 정규식이라 `-E` 없음 |
| `grep "a\\|b"` (BRE) | ✗ rg 는 POSIX BRE 아님 |
| `top -l 1` | ✗ btop 에 `-l` 없음 |

**가장 위험한 건 조용한 오작동이다.** `rg` 는 `.gitignore` 와 숨김 파일을 건너뛴다:

```
같은 패턴이 4개 파일에 존재 (2개는 .gitignore, 1개는 숨김 파일)
  /usr/bin/grep -r  →  4개 발견
  rg                →  1개만 발견     ← 에러 없이 3개 누락
```

대신 짧은 별칭을 둔다:

| 별칭 | 실제 |
|---|---|
| `c` | `bat --paging=never` |
| `rgi` | `rg -i` |
| `rga` | `rg -uuu` (ignore·숨김 무시하고 전부 검색) |
| `btm` | `btop` |
| `lst` | `eza -l --sort=modified --reverse` (`ls -ltr` 대용) |

### `ls` → `eza` 만 예외

`-l`, `-a`, `-1`, `-h`, `--color` 를 다 받아서 호환성이 좋다.
단 **`-t` 는 eza 에서 `--time`(인자 필요)이라 `ls -t`, `ls -ltr` 이 깨진다.**

- 대화형으로는 `lst` 를 쓴다.
- **스크립트에서 최신 파일을 찾을 땐 `/bin/ls -t` 또는 `find` 를 쓴다.**

---

## 로컬 오버라이드 (`~/.zshrc.local`)

머신마다 다른 설정은 저장소에 넣지 않고 `~/.zshrc.local` 에 둔다.
`.zshrc` **13번 섹션이 맨 마지막에 읽으므로, 여기서 정의한 것이 항상 이긴다.**

```sh
$EDITOR ~/.zshrc.local     # chezmoi edit 아님 — 관리 대상이 아니다
exec zsh
```

**`chezmoi init --apply` 시 자동으로 생성된다** ([`create_dot_zshrc.local`](../create_dot_zshrc.local)).
키체인 등록 방법, `_kc_export` 사용 예, 프로젝트별 키 설정까지 주석으로 들어있다.

`create_` 접두사의 동작 (실제로 검증함):

| 상황 | 결과 |
|---|---|
| 파일이 없음 | 템플릿으로 **생성** |
| 사용자가 수정함 | `diff` 비어있음, `apply` 해도 **보존** |
| 저장소의 템플릿이 바뀜 | 이미 있는 파일엔 **밀어넣지 않음** |

- 파일이 없어도 셸은 정상 동작한다 (존재할 때만 source)
- 우선순위 검증: 저장소가 정의한 `ll` 을 로컬에서 재정의하면 로컬이 이긴다

> [!WARNING]
> `.chezmoiignore` 에 `.zshrc.local` 을 넣으면 **최초 생성 자체가 일어나지 않는다.**
> 넣지 말 것.

### 무엇을 넣나

| 넣을 것 | 넣지 말 것 |
|---|---|
| 이 머신에서만 쓰는 alias | 모든 머신에 필요한 설정 → `dot_zshrc` |
| 회사/개인별 환경변수 | **시크릿 값** → [키체인 방식](secrets.md) |
| 실험적 설정 | 위젯 감싸는 플러그인 → 12번 뒤라 충돌 |

예시 (실제로 이 머신에 들어있는 것):

```bash
# Claude Code: 권한 확인을 전부 건너뛰고 시작
alias c='claude --dangerously-skip-permissions'
```
