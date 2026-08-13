#!/bin/sh

set -e

RDP_USER="${RDP_USER:-debian}"

# ============================================================
# Runtime de XRDP
# ============================================================

mkdir -p /run/xrdp
chown xrdp:xrdp /run/xrdp

# ============================================================
# Runtime del usuario para PipeWire
# ============================================================

RDP_UID="$(id -u "$RDP_USER")"
RDP_GID="$(id -g "$RDP_USER")"

mkdir -p "/run/user/${RDP_UID}"
chown "${RDP_UID}:${RDP_GID}" "/run/user/${RDP_UID}"
chmod 700 "/run/user/${RDP_UID}"

# ============================================================
# XRDP
# ============================================================

/usr/sbin/xrdp-sesman --nodaemon &

exec /usr/sbin/xrdp --nodaemon
