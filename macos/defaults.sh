#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  macOS 시스템 설정 — Dock / 키보드 / 트랙패드 제스처
#
#  이 파일은 2026-08-20 시점 이 맥(macOS 26.3, Apple Silicon)의 실제 설정을
#  `defaults read` 로 덤프해서 만든 스냅샷이다. 그대로 실행하면 현재와 동일한
#  상태가 재현되고, 체감상 달라지는 것은 없다.
#
#  "# 추천:" 으로 시작하는 줄은 적용되지 않은 제안이다. 원하면 주석을 풀면 된다.
#
#  ⚠ 트랙패드 제스처는 로그아웃/재시작해야 완전히 반영된다.
#     Dock/Finder 는 아래 killall 로 즉시 반영된다.
#
#  실행:  bash macos/defaults.sh
#  재덤프: bash macos/capture.sh   (현재 맥 상태와의 차이를 확인)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

echo "==> macOS 설정 적용 중…"

# 스크립트가 도는 동안 시스템 환경설정이 값을 덮어쓰지 않도록 종료
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# sudo 는 쓰지 않는다 — 아래 설정은 전부 사용자 도메인이다.


# ═════════════════════════════════════════════════════════════════════════════
#  Dock
# ═════════════════════════════════════════════════════════════════════════════

# 아이콘 크기 (기본 48)
defaults write com.apple.dock tilesize -int 43

# Mission Control 에서 같은 앱의 윈도우를 묶어서 표시
defaults write com.apple.dock expose-group-apps -bool true

# 트랙패드 제스처로 앱 Exposé 열기 (세 손가락 아래로 쓸기)
defaults write com.apple.dock showAppExposeGestureEnabled -bool true

# 핫코너: 우측 하단 = 빠른 메모 (14), 수정키 없음 (0)
#   값: 1=사용안함 2=MissionControl 3=앱윈도우 4=데스크탑 5=화면보호기시작
#       6=화면보호기해제 7=Dashboard 10=디스플레이잠자기 11=Launchpad
#       12=알림센터 13=화면잠금 14=빠른메모
defaults write com.apple.dock wvous-br-corner -int 14
defaults write com.apple.dock wvous-br-modifier -int 0

# 추천: Dock 자동 숨김 — 세로 공간을 되찾는다
# defaults write com.apple.dock autohide -bool true
# defaults write com.apple.dock autohide-delay -float 0        # 나타나기까지 지연 제거
# defaults write com.apple.dock autohide-time-modifier -float 0.4

# 추천: 최근 사용한 앱 섹션 숨기기 (Dock 이 멋대로 늘어나는 것 방지)
# defaults write com.apple.dock show-recents -bool false

# 추천: 최소화 효과를 genie 대신 scale 로 (더 빠름)
# defaults write com.apple.dock mineffect -string "scale"

# 추천: 실행 중인 앱만 표시 (Dock 을 작업 표시줄처럼 사용)
# defaults write com.apple.dock static-only -bool true

# 추천: Spaces 를 최근 사용 순으로 재정렬하지 않기 (위치 기억이 깨지는 것 방지)
# defaults write com.apple.dock mru-spaces -bool false


# ═════════════════════════════════════════════════════════════════════════════
#  키보드
# ═════════════════════════════════════════════════════════════════════════════

# 키 반복 속도 — 이미 거의 최속으로 튜닝돼 있음
#   KeyRepeat: 낮을수록 빠름 (2 = 30ms, 시스템 설정 슬라이더 최대치보다 빠름)
#   InitialKeyRepeat: 반복 시작까지의 지연 (15 = 225ms)
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15

# F1~F12 를 표준 기능 키로 사용 (밝기/볼륨은 fn 조합)
defaults write -g com.apple.keyboard.fnState -bool true

# 자동 대문자 / 마침표 치환 (현재 켜져 있음)
defaults write -g NSAutomaticCapitalizationEnabled -bool true
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool true

# 추천: 코드/터미널 작업이 많다면 위 두 개를 끄는 편이 낫다.
#       "const" 가 "Const" 가 되거나 스페이스 두 번이 마침표로 바뀌는 것을 막는다.
# defaults write -g NSAutomaticCapitalizationEnabled -bool false
# defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false

# 추천: 자동 따옴표/대시 치환도 끄기 — 코드에 스마트 따옴표가 섞이는 사고 방지
# defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
# defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
# defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false

# 추천: 키를 꾹 눌렀을 때 악센트 팝업 대신 키 반복 (에디터에서 유용)
# defaults write -g ApplePressAndHoldEnabled -bool false

# 추천: Tab 으로 모든 컨트롤에 포커스 이동 (다이얼로그 키보드 조작)
# defaults write -g AppleKeyboardUIMode -int 3

# 스프링 로딩: 드래그 중 폴더 위에 머물면 열림
defaults write -g com.apple.springing.enabled -bool true
defaults write -g com.apple.springing.delay -float 0.5


# ═════════════════════════════════════════════════════════════════════════════
#  트랙패드 / 제스처
#
#  두 도메인 모두에 써야 한다:
#    com.apple.AppleMultitouchTrackpad                  = 내장 트랙패드
#    com.apple.driver.AppleBluetoothMultitouch.trackpad = Magic Trackpad
#  이 맥은 두 도메인 다 실제 값을 갖고 있다.
#
#  제스처 값의 의미:
#    0 = 사용 안 함
#    1 = 두 손가락
#    2 = 세 손가락 (스와이프 계열의 기본값)
#    3 = 네 손가락 / 또는 탭 동작 활성
# ═════════════════════════════════════════════════════════════════════════════

for domain in com.apple.AppleMultitouchTrackpad \
              com.apple.driver.AppleBluetoothMultitouch.trackpad; do

  # ── 클릭 ──────────────────────────────────────────────────────
  defaults write "$domain" Clicking -int 0                  # 탭 투 클릭: 꺼짐
  defaults write "$domain" Dragging -int 0                  # 탭 후 드래그: 꺼짐
  defaults write "$domain" DragLock -int 0
  defaults write "$domain" TrackpadRightClick -int 1        # 두 손가락 보조 클릭
  defaults write "$domain" TrackpadCornerSecondaryClick -int 0

  # ── 스크롤 / 확대 ─────────────────────────────────────────────
  defaults write "$domain" TrackpadScroll -int 1
  defaults write "$domain" TrackpadHorizScroll -int 1
  defaults write "$domain" TrackpadMomentumScroll -int 1
  defaults write "$domain" TrackpadPinch -int 1             # 핀치 줌
  defaults write "$domain" TrackpadRotate -int 1            # 회전

  # ── 제스처 ────────────────────────────────────────────────────
  defaults write "$domain" TrackpadThreeFingerDrag -int 0            # 세 손가락 드래그: 꺼짐
  defaults write "$domain" TrackpadThreeFingerTapGesture -int 0      # 세 손가락 탭(사전): 꺼짐
  defaults write "$domain" TrackpadTwoFingerDoubleTapGesture -int 1  # 두 손가락 더블탭 = 스마트 확대
  defaults write "$domain" TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3  # 우측 가장자리 = 알림 센터

  # 스와이프: 3 = Mission Control / 앱 Exposé, 4 = Spaces 이동
  defaults write "$domain" TrackpadThreeFingerVertSwipeGesture -int 2
  defaults write "$domain" TrackpadThreeFingerHorizSwipeGesture -int 2
  defaults write "$domain" TrackpadFourFingerVertSwipeGesture -int 2
  defaults write "$domain" TrackpadFourFingerHorizSwipeGesture -int 2
  defaults write "$domain" TrackpadFourFingerPinchGesture -int 2      # 네 손가락 핀치 = Launchpad
  defaults write "$domain" TrackpadFiveFingerPinchGesture -int 2      # 다섯 손가락 오므리기 = 데스크탑

  # ── 기타 ──────────────────────────────────────────────────────
  defaults write "$domain" TrackpadHandResting -int 1        # 손바닥 인식
  defaults write "$domain" USBMouseStopsTrackpad -int 0      # 마우스 연결해도 트랙패드 유지
  defaults write "$domain" UserPreferences -int 1
done

# 세게 클릭(Force Click) 및 햅틱 피드백
defaults write -g com.apple.trackpad.forceClick -int 1
defaults write com.apple.AppleMultitouchTrackpad ActuateDetents -int 1
defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -int 0
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 1

# 추천: 탭 투 클릭 켜기 — 클릭 소리 없이, 손목 피로 감소
#   두 도메인 + NSGlobalDomain 미러 키를 함께 써야 시스템 설정 UI 에도 반영된다.
# for domain in com.apple.AppleMultitouchTrackpad \
#               com.apple.driver.AppleBluetoothMultitouch.trackpad; do
#   defaults write "$domain" Clicking -int 1
# done
# defaults write -g com.apple.mouse.tapBehavior -int 1

# 추천: 세 손가락 드래그 — 윈도우 이동/텍스트 선택이 훨씬 편해진다.
#   단, 세 손가락 스와이프(Mission Control)와 충돌하므로 그쪽은 네 손가락으로 옮겨야 한다.
# for domain in com.apple.AppleMultitouchTrackpad \
#               com.apple.driver.AppleBluetoothMultitouch.trackpad; do
#   defaults write "$domain" TrackpadThreeFingerDrag -int 1
#   defaults write "$domain" TrackpadThreeFingerVertSwipeGesture -int 0
#   defaults write "$domain" TrackpadThreeFingerHorizSwipeGesture -int 0
#   defaults write "$domain" TrackpadFourFingerVertSwipeGesture -int 2
#   defaults write "$domain" TrackpadFourFingerHorizSwipeGesture -int 2
# done

# 추천: 마우스/트랙패드 추적 속도 (0.0 ~ 3.0). 현재 미설정 = 시스템 기본
# defaults write -g com.apple.trackpad.scaling -float 1.5


# ═════════════════════════════════════════════════════════════════════════════
#  반영
# ═════════════════════════════════════════════════════════════════════════════
echo "==> 프로세스 재시작 중…"
for app in Dock Finder SystemUIServer; do
  killall "$app" >/dev/null 2>&1 || true
done

cat <<'EOF'

==> 완료.

    ⚠ 트랙패드 제스처 변경은 로그아웃 또는 재시작해야 완전히 반영됩니다.
      Dock/키보드 설정은 이미 적용되었습니다.

EOF
