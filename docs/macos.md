# macOS 시스템 설정

소스: [`macos/defaults.sh`](../macos/defaults.sh), [`macos/capture.sh`](../macos/capture.sh)

```sh
bash macos/defaults.sh     # 적용
bash macos/capture.sh      # 현재 상태 덤프 (defaults.sh 와 비교용)
```

`defaults.sh` 는 **현재 맥 설정의 스냅샷**이라 그대로 실행해도 체감 변화가 없다.
`# 추천:` 으로 시작하는 줄은 적용되지 않은 제안 — 원하면 주석을 풀면 된다.

## 주요 추천 항목

- Dock 자동 숨김 / 최근 앱 숨기기
- 자동 대문자·마침표 치환 끄기 (코딩 시 방해)
- 탭 투 클릭 켜기
- 세 손가락 드래그 켜기 (스와이프를 네 손가락으로 옮겨야 함)

## 반영 시점

| 영역 | 언제 반영되나 |
|---|---|
| Dock / 키보드 | `killall Dock` 즉시 |
| **트랙패드 제스처** | **로그아웃 또는 재시작 필요** |

트랙패드 설정은 **두 도메인 모두**에 써야 한다 — 내장 트랙패드와 Magic Trackpad 가
별도 도메인을 쓴다. 한쪽만 쓰면 해당 기기에서만 적용된다.

## 왜 chezmoi 자동 실행이 아닌가

이 스크립트는 **일부러 `.chezmoiscripts/` 밖에 둔다.**
`chezmoi apply` 는 자주 돌리는 명령인데, `run_` 스크립트로 옮기면 그때마다
`killall Dock Finder` 가 실행된다. 수동 실행이 의도된 설계다.

## drift 확인

```sh
bash macos/capture.sh > /tmp/now.txt
# defaults.sh 와 눈으로 대조 — 맥에서 GUI 로 바꾼 설정이 여기 잡힌다
```

바뀐 값을 저장소에 남기고 싶으면 `defaults.sh` 의 해당 줄을 갱신한다.
