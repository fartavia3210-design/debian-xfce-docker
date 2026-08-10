#!/bin/sh

set -e

if [ -z "$RDP_PASSWORD" ]; then
    echo "ERROR: Debes definir RDP_PASSWORD"
    exit 1
fi

echo "${RDP_USER}:${RDP_PASSWORD}" | chpasswd

mkdir -p /run/xrdp
chown xrdp:xrdp /run/xrdp

/usr/sbin/xrdp-sesman --nodaemon &

exec /usr/sbin/xrdp --nodaemon
