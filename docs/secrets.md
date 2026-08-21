# 시크릿 (API 키 등)

**이 저장소는 평문 시크릿을 담지 않는다.** 값은 macOS 키체인에 두고
`.zshrc` 9번 섹션이 셸 시작 시 조회한다. 저장소에도 디스크에도 평문이 남지 않는다.

## 추가하기

```sh
# 값을 프롬프트로 입력 (셸 히스토리에 안 남음)
security add-generic-password -s anthropic -a "$USER" -w -U

# 또는 한 줄로 (히스토리에 남으니 주의)
security add-generic-password -s anthropic -a "$USER" -w "sk-ant-..." -U
```

그다음 [`dot_zshrc`](../dot_zshrc) 9번 섹션에서 해당 줄의 주석을 해제한다:

```bash
_kc_export ANTHROPIC_API_KEY  anthropic
```

`chezmoi apply` 후 새 셸을 열면 적용된다.

## 확인 / 삭제

```sh
security find-generic-password -s anthropic -a "$USER" -w      # 값 확인
security delete-generic-password -s anthropic -a "$USER"       # 삭제
```

## 왜 런타임 조회인가

chezmoi 의 `{{ keyring ... }}` 템플릿 함수도 있지만 **쓰지 않는다.**
이건 `chezmoi apply` 시점에 치환되기 때문에, 저장소는 깨끗해도
**디스크의 `~/.zshrc` 에 평문 키가 박힌다.**
런타임 조회는 `.zshrc` 에 조회 명령만 남으므로 그 파일 자체를 공개해도 안전하다.

| 방식 | 저장소 | 디스크 `~/.zshrc` |
|---|---|---|
| `{{ keyring }}` 템플릿 | 참조만 ✅ | **평문 ⚠️** |
| **런타임 조회 (채택)** | 명령만 ✅ | **명령만 ✅** |
| age 암호화 | 암호문 ✅ | 복호화된 평문 ⚠️ |

조회 비용은 키 하나당 약 10ms. 키가 많아지면 지연 로딩으로 바꾼다:

```bash
anthropic_key() { _kc anthropic; }
ANTHROPIC_API_KEY=$(anthropic_key) some-command
```

## 함정 두 가지

1. **`private_` 접두사는 암호화가 아니다.** `private_dot_ssh/config` 는 퍼미션을
   0600 으로 만들라는 뜻일 뿐, 저장소에는 평문 그대로 들어간다.
2. **`chezmoi secret keyring set` 으로 저장하지 말 것.** Go 키링 라이브러리가
   `go-keyring-base64:` 접두사를 붙여 저장해서 셸에서 바로 못 읽는다.
   `security add-generic-password` 로 저장하면 chezmoi 와 셸 양쪽에서 읽힌다.

> [!WARNING]
> 시크릿 '값'은 [`~/.zshrc.local`](shell.md#로컬-오버라이드-zshrclocal) 에도 두지 않는다.
> 그 파일은 관리 대상이 아닐 뿐 평문 디스크 파일이다.
