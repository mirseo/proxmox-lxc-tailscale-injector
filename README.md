# lxc-injector — Proxmox LXC TUN 활성화 스크립트

[English README here](README.en.md)

## 소개
이 프로젝트는 Proxmox VE 환경에서 특정 LXC 컨테이너가 `/dev/net/tun` 디바이스를 사용할 수 있도록 가볍게 설정을 추가하는 스크립트입니다. 스크립트는 사용자가 입력한 LXC ID를 검증한 뒤, 해당 컨테이너 설정 파일(`/etc/pve/lxc/[ID].conf`)의 맨 마지막에 필요한 두 줄을 추가합니다. 동일한 설정이 이미 있으면 중복하여 추가하지 않습니다.

## 동작 요약
- LXC ID 입력 프롬프트 표시: `[proxmox LXC ID를 입력해주세요 >>> ]`
- 입력값이 1–65500 범위의 정수인지 검증
- `/etc/pve/lxc/[ID].conf` 파일 맨 아래에 다음 두 줄을 필요 시 추가

```conf
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file 0 0
```

## 전제 조건
- Proxmox VE 호스트에서 실행해야 합니다. (컨테이너 내부가 아님)
- 루트 권한이 필요합니다. (`/etc/pve`에 쓰기 권한 필요)
- 대상 LXC 컨테이너가 존재해야 합니다. (`pct list`로 확인 가능)

## 설치 및 실행
```bash
wget -O - https://raw.githubusercontent.com/mirseo/proxmox-lxc-tailscale-injector/refs/heads/main/install.sh | sudo bash
```
- 프롬프트가 뜨면 컨테이너 ID를 입력합니다. 예: `101`

## 적용 내용 확인
- 호스트에서 설정 파일에 두 줄이 들어갔는지 확인
```bash
grep -n "c 10:200 rwm" /etc/pve/lxc/<ID>.conf || true
grep -n "/dev/net/tun" /etc/pve/lxc/<ID>.conf || true
```
- 컨테이너 내부에서 TUN 디바이스 확인 (호스트에서 실행)
```bash
pct enter <ID> -- ls -l /dev/net/tun
```
문자 디바이스로 표시되면 정상입니다. 필요 시 컨테이너를 재시작하여 반영합니다.
```bash
pct restart <ID>
```

## 되돌리기(롤백)
- 변경 전 백업을 권장합니다.
```bash
cp /etc/pve/lxc/<ID>.conf /etc/pve/lxc/<ID>.conf.bak
```
- 되돌리려면 설정 파일을 열어 아래 두 줄을 삭제하고 컨테이너를 재시작합니다.
```conf
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file 0 0
```

## 문제 해결 가이드
- 권한 오류: 루트 권한으로 실행했는지 확인합니다. (`sudo -i` 또는 직접 root로 로그인)
- 파일을 찾을 수 없음: 입력한 ID의 컨테이너가 존재하는지 `pct list`로 확인합니다.
- 설정이 중복 추가됨: 스크립트는 동일한 한 줄이 정확히 존재하면 재추가하지 않습니다. 줄 끝 공백/철자 차이가 있으면 중복으로 보일 수 있으니 수동 정리 후 재시도하세요.

## 참고
- 이 스크립트는 최소 변경을 목표로 하며, 컨테이너의 다른 설정에는 영향을 주지 않습니다.
- Proxmox 클러스터 환경에서도 `/etc/pve/lxc/[ID].conf`에 동일하게 반영됩니다.

