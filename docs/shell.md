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
