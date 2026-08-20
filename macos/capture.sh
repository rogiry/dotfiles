#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  현재 맥의 Dock / 키보드 / 트랙패드 설정을 덤프한다.
#
#  용도: 시스템 설정 UI 에서 뭔가 바꾼 뒤, defaults.sh 와 무엇이 달라졌는지 확인.
#
#  사용:
#    bash macos/capture.sh              # 사람이 읽는 표 형태로 출력
#    bash macos/capture.sh --diff       # defaults.sh 의 적용값과 비교
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

DOMAINS_TRACKPAD=(
  com.apple.AppleMultitouchTrackpad
  com.apple.driver.AppleBluetoothMultitouch.trackpad
)

DOCK_KEYS=(
  tilesize largesize magnification autohide autohide-delay
  autohide-time-modifier orientation mineffect minimize-to-application
  show-recents show-process-indicators static-only mru-spaces
  expose-group-apps showAppExposeGestureEnabled showMissionControlGestureEnabled
  showLaunchpadGestureEnabled showDesktopGestureEnabled
  wvous-tl-corner wvous-tl-modifier wvous-tr-corner wvous-tr-modifier
  wvous-bl-corner wvous-bl-modifier wvous-br-corner wvous-br-modifier
)

GLOBAL_KEYS=(
  KeyRepeat InitialKeyRepeat ApplePressAndHoldEnabled AppleKeyboardUIMode
  com.apple.keyboard.fnState
  NSAutomaticCapitalizationEnabled NSAutomaticPeriodSubstitutionEnabled
  NSAutomaticQuoteSubstitutionEnabled NSAutomaticDashSubstitutionEnabled
  NSAutomaticSpellingCorrectionEnabled
  com.apple.springing.enabled com.apple.springing.delay
  com.apple.swipescrolldirection com.apple.trackpad.forceClick
  com.apple.trackpad.scaling com.apple.mouse.tapBehavior
)

TRACKPAD_KEYS=(
  Clicking Dragging DragLock TrackpadRightClick TrackpadCornerSecondaryClick
  TrackpadScroll TrackpadHorizScroll TrackpadMomentumScroll TrackpadPinch TrackpadRotate
  TrackpadThreeFingerDrag TrackpadThreeFingerTapGesture
  TrackpadTwoFingerDoubleTapGesture TrackpadTwoFingerFromRightEdgeSwipeGesture
  TrackpadThreeFingerVertSwipeGesture TrackpadThreeFingerHorizSwipeGesture
  TrackpadFourFingerVertSwipeGesture TrackpadFourFingerHorizSwipeGesture
  TrackpadFourFingerPinchGesture TrackpadFiveFingerPinchGesture
  TrackpadHandResting USBMouseStopsTrackpad
  ActuateDetents ForceSuppressed FirstClickThreshold SecondClickThreshold
)

read_key() {  # $1=domain($ 또는 -g) $2=key
  local out
  if [[ "$1" == "-g" ]]; then
    out=$(defaults read -g "$2" 2>/dev/null)
  else
    out=$(defaults read "$1" "$2" 2>/dev/null)
  fi
  [[ -z "$out" ]] && out="(unset)"
  printf '%s' "$out"
}

section() { printf '\n\033[1m── %s %s\033[0m\n' "$1" "$(printf '─%.0s' $(seq 1 $((60 - ${#1}))))"; }

section "Dock  (com.apple.dock)"
for k in "${DOCK_KEYS[@]}"; do
  printf '  %-38s %s\n' "$k" "$(read_key com.apple.dock "$k")"
done

section "키보드 / 전역  (NSGlobalDomain)"
for k in "${GLOBAL_KEYS[@]}"; do
  printf '  %-45s %s\n' "$k" "$(read_key -g "$k")"
done

for d in "${DOMAINS_TRACKPAD[@]}"; do
  section "트랙패드  ($d)"
  for k in "${TRACKPAD_KEYS[@]}"; do
    printf '  %-46s %s\n' "$k" "$(read_key "$d" "$k")"
  done
done

section "환경"
printf '  %-20s %s\n' "macOS"    "$(sw_vers -productVersion) ($(sw_vers -buildVersion))"
printf '  %-20s %s\n' "hardware" "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
printf '  %-20s %s\n' "captured" "$(date '+%Y-%m-%d %H:%M:%S')"
echo
