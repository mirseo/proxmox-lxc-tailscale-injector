#!/usr/bin/env bash

# 이 스크립트는 Proxmox 호스트에서 특정 LXC 컨테이너에 대해
# TUN 디바이스를 사용할 수 있도록 필요한 설정 두 줄을
# 컨테이너 설정 파일(/etc/pve/lxc/[ID].conf)의 맨 아래에 추가합니다.
#
# 작성자 메모:
# - 사람이 보기 좋은 형태로 간단한 안내/검증 로직을 넣었습니다.
# - 동일한 설정이 이미 있으면 중복 추가하지 않습니다.
# - 루트 권한으로 실행해야 /etc/pve 경로에 쓸 수 있습니다.

set -o errexit
set -o nounset
set -o pipefail

# bash 전용 문법([[, (( )) 등])을 사용하므로 bash가 아닐 경우 재실행
if [ -z "${BASH_VERSION:-}" ]; then
  # 사람이 주로 `sh install.sh`로 실행했을 때를 대비
  exec bash "$0" "$@"
fi

# 대화형/비대화형(파이프) 모두에서 안정적으로 입력을 받기 위한 처리
if [ -t 0 ]; then
  # 표준입력이 터미널이면 일반적인 방식으로 프롬프트와 입력
  read -r -p "[Please enter your proxmox LXC ID >>> ] " LXC_ID
else
  # 파이프 설치(wget|bash 등) 시에는 /dev/tty에서 직접 입력을 받음
  printf "[Please enter your proxmox LXC ID >>> ] " > /dev/tty
  read -r LXC_ID < /dev/tty
fi

# 숫자 형태인지 먼저 확인
if ! [[ "$LXC_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: Only numbers are allowed (e.g. 101)" >&2
  exit 1
fi

# 허용 범위(1~65500) 확인
if (( LXC_ID < 1 || LXC_ID > 65500 )); then
  echo "Error: LXC ID must be a value between 1 and 65500." >&2
  exit 1
fi

CONF_PATH="/etc/pve/lxc/${LXC_ID}.conf"

# 대상 컨테이너 설정 파일 존재 여부 확인
if [[ ! -f "$CONF_PATH" ]]; then
  echo "Error: Could not find container configuration file: $CONF_PATH" >&2
  echo "Hint: Check the container list with 'pct list' or double-check the ID." >&2
  exit 1
fi

# 추가 반영 예정사항(Todo)
# - 스크립트 호환성 개선 ( + 추가적인 권한 안정화 )
LINE1="lxc.cgroup2.devices.allow: c 10:200 rwm"
LINE2="lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file 0 0"

# 파일에 라인이 없는 경우에만 추가하는 함수
append_if_missing() {
  local line="$1"
  local path="$2"
  if grep -qxF "$line" "$path"; then
    echo "Already included: $line"
  else
    echo "$line" >> "$path"
    echo "Added: $line"
  fi
}

echo "target file: $CONF_PATH"
append_if_missing "$LINE1" "$CONF_PATH"
append_if_missing "$LINE2" "$CONF_PATH"

echo "complete: The required settings have been applied to the end of the $CONF_PATH file."
