# lxc-injector — Enable TUN in Proxmox LXC

[Korean README](README.ko.md)

## Overview
This project provides a small script that enables `/dev/net/tun` in a specific Proxmox LXC container. It prompts for an LXC ID, validates the input, and appends two required lines to the end of `/etc/pve/lxc/[ID].conf`. If the lines already exist, the script avoids adding duplicates.

## What It Does
- Shows prompt: `[Please enter your proxmox LXC ID >>> ]`
- Validates that the input is an integer in the range 1–65500
- Appends the following two lines to `/etc/pve/lxc/[ID].conf` only if missing

```conf
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file 0 0
```

## Requirements
- Run on the Proxmox VE host (not inside the container)
- Root privileges are required (write access to `/etc/pve`)
- The target LXC container must exist (`pct list` to verify)

## Install and Run
```bash
chmod +x install.sh
./install.sh
```
- When prompted, enter your container ID. Example: `101`

## Verify Changes
- On the host, confirm that both lines are present
```bash
grep -n "c 10:200 rwm" /etc/pve/lxc/<ID>.conf || true
grep -n "/dev/net/tun" /etc/pve/lxc/<ID>.conf || true
```
- Inside the container, confirm the TUN device (run from the host)
```bash
pct enter <ID> -- ls -l /dev/net/tun
```
If you see a character device, you are good. Restart the container if needed:
```bash
pct restart <ID>
```

## Rollback
- Back up before changes if you prefer
```bash
cp /etc/pve/lxc/<ID>.conf /etc/pve/lxc/<ID>.conf.bak
```
- To revert, open the config file, remove the two lines below, and restart the container
```conf
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file 0 0
```

## Troubleshooting
- Permission denied: ensure you run as root (`sudo -i` or log in as root)
- File not found: make sure the container ID exists (`pct list`)
- Duplicate lines: the script checks exact matches. If you have variations (trailing spaces or different spelling), clean them up manually before re-running.

## Notes
- The script aims for minimal changes and does not touch other container settings.
- In Proxmox clusters, the same path `/etc/pve/lxc/[ID].conf` applies.

## LICENSE
MIT

