# Debian XFCE Docker

A lightweight Debian 13 desktop environment running inside a Docker container.

The container includes:

- Debian 13
- XFCE 4
- TigerVNC
- D-Bus
- Automatic desktop startup

## How it works

The container shares the Linux kernel of the host system instead of running a full virtual machine.

Architecture:

Docker
→ Debian 13
→ XFCE
→ TigerVNC
→ VNC Viewer

## Build

```bash
docker build -t debian-xfce:1.0 .
