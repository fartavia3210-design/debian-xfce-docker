#!/bin/sh

set -e

mkdir -p /root/.config/tigervnc

if [ -z "$VNC_PASSWORD" ]; then
    echo "ERROR: Debes definir VNC_PASSWORD"
    exit 1
fi

printf '%s\n' "$VNC_PASSWORD" | tigervncpasswd -f > /root/.config/tigervnc/passwd
chmod 600 /root/.config/tigervnc/passwd

exec tigervncserver :1 \
    -fg \
    -geometry "$VNC_RESOLUTION" \
    -localhost no
