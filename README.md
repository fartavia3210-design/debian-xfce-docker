# Debian XFCE Docker

A lightweight Debian 13 desktop environment running inside a Docker container, with XFCE, XRDP, H.264/x264 encoding, 60 Hz virtual display support, clipboard integration, and Brave Browser.

This project provides a desktop-like Linux environment without running a full virtual machine.

## Features

- Debian 13
- XFCE 4 desktop environment
- XRDP 0.10.6.1
- xorgxrdp 0.10.5
- H.264 desktop encoding using x264
- RFX fallback support
- 60 Hz virtual RDP display
- Bidirectional clipboard
- Brave Browser preinstalled
- Automatic XFCE session startup
- Automatic Docker container launcher
- SDL-FreeRDP / FreeRDP 3 support
- Automatic window sizing
- Local per-user window size configuration
- RDP exposed only on `127.0.0.1` by default

## How it works

This is **not a virtual machine**.

The Debian container shares the Linux kernel of the host system while running its own userspace, desktop environment, applications, and graphical session.

The desktop is rendered by Xorg through xorgxrdp and transmitted to the host using the RDP Graphics Pipeline.

```text
Linux Host
    │
    ▼
Docker Engine
    │
    ▼
Debian 13 Container
    │
    ├── XFCE
    │
    ├── Xorg
    │
    └── xorgxrdp
            │
            ▼
        XRDP 0.10.6.1
            │
            ▼
      H.264 / x264
            │
            ▼
     FreeRDP 3 Client
            │
            ▼
      Desktop Window
```

XRDP prefers H.264 and falls back to RFX when H.264 cannot be negotiated.

The codec configuration is:

```toml
[codec]
order = [ "H.264", "RFX" ]

h264_encoder = "x264"
```

The x264 encoder is configured for low-latency desktop use:

```toml
preset = "ultrafast"
tune = "zerolatency"
fps_num = 60
fps_den = 1
```

## 60 Hz support

xorgxrdp normally creates its virtual display using a 50 Hz pseudo refresh rate.

During the Docker build, this project patches xorgxrdp before compilation:

```c
const int vfreq = 60;
```

The resulting RDP display reports:

```text
1900x1026     60.00*
```

Resolution itself is determined by the RDP client and can be changed depending on the host display.

## Requirements

A Linux host with:

- Docker
- Git
- FreeRDP 3

Recommended RDP client:

```text
sdl-freerdp3
```

The launcher can also fall back to:

```text
xfreerdp3
```

when SDL-FreeRDP is not available.

### Arch / CachyOS

Install Docker and FreeRDP using the distribution repositories.

For example:

```bash
sudo pacman -S docker freerdp
```

Enable and start Docker if necessary:

```bash
sudo systemctl enable --now docker
```

Your user must also have permission to access Docker.

## Clone

```bash
git clone https://github.com/fartavia3210-design/debian-xfce-docker.git
cd debian-xfce-docker
```

## Build

Build the Docker image:

```bash
docker build -t debian-xfce:2.0.0 .
```

XRDP and xorgxrdp are compiled from source during the image build, so the first build may take several minutes.

The versions currently used are:

```text
XRDP:     0.10.6.1
xorgxrdp: 0.10.5
```

## Create the container

Create the desktop container:

```bash
docker create \
    --name debian-xfce-rdp \
    --shm-size=1g \
    -p 127.0.0.1:3389:3389 \
    -e RDP_PASSWORD='CHANGE_THIS_PASSWORD' \
    debian-xfce:2.0.0
```

Replace:

```text
CHANGE_THIS_PASSWORD
```

with the password you want to use for the Debian RDP session.

The internal desktop user is:

```text
debian
```

### Why bind to 127.0.0.1?

The container publishes RDP as:

```text
127.0.0.1:3389
```

instead of:

```text
0.0.0.0:3389
```

This prevents the RDP service from being directly exposed to other devices on the network by default.

## Manual start

Start the container:

```bash
docker start debian-xfce-rdp
```

Check its status:

```bash
docker ps --filter name=debian-xfce-rdp
```

The RDP service will be available at:

```text
127.0.0.1:3389
```

Stop it with:

```bash
docker stop debian-xfce-rdp
```

## Automatic launcher

The repository includes:

```text
scripts/debian-xfce
```

The launcher automatically:

1. Checks whether the container exists.
2. Starts it if necessary.
3. Waits for XRDP to become ready.
4. Reads the RDP username and password from the container configuration.
5. Detects the current monitor size.
6. Opens SDL-FreeRDP or XFreeRDP.
7. Enables clipboard integration.
8. Stops the container when the RDP window closes, if the launcher started it.

Install it locally:

```bash
mkdir -p ~/.local/bin

cp scripts/debian-xfce ~/.local/bin/debian-xfce

chmod +x ~/.local/bin/debian-xfce
```

Then run:

```bash
debian-xfce
```

Make sure:

```text
~/.local/bin
```

is included in your `PATH`.

## Window size configuration

The launcher calculates the initial RDP resolution based on the current monitor.

Default values are:

```text
WINDOW_PERCENT_W=90
WINDOW_PERCENT_H=90
```

You can override them without modifying the repository.

Create:

```text
~/.config/debian-xfce-docker/config
```

Example:

```bash
WINDOW_PERCENT_W=99
WINDOW_PERCENT_H=95
```

This configuration remains local to the machine and does not need to be committed to Git.

## Display detection

The launcher currently has specialized detection for Hyprland using:

```text
hyprctl monitors
```

It also includes an X11 fallback using:

```text
xrandr
```

The project has been primarily tested on a Linux + Hyprland host.

Other desktop environments such as KDE Plasma or GNOME may work with FreeRDP, but automatic monitor-size detection may require additional testing or adjustments.

## Verify 60 Hz

Inside the Debian XFCE session run:

```bash
xrandr
```

A successful 60 Hz session should show something similar to:

```text
Screen 0: minimum 256 x 256, current 1900 x 1026, maximum 16384 x 16384
rdp0 connected 1900x1026+0+0
   1900x1026     60.00*
```

The exact resolution depends on the RDP client window size.

## Verify H.264

Check the XRDP log:

```bash
docker exec debian-xfce-rdp \
    sh -c "grep -Ei 'h264|x264|rfx|gfx|encoder' /var/log/xrdp.log | tail -n 80"
```

When H.264 is successfully negotiated, the output should include messages similar to:

```text
Codec search order is H264, RFX
Matched H264 mode
xrdp_encoder_create: starting h264 codec session gfx
xrdp_encoder_create: using x264 for software encoder
xrdp_encoder_x264_encode: x264_encoder_open
```

This confirms that the session is actually using H.264/x264 rather than the RFX fallback.

## Verify XRDP build

Run:

```bash
docker run --rm \
    --entrypoint /usr/sbin/xrdp \
    debian-xfce:2.0.0 \
    --version
```

The configure options should include:

```text
--enable-x264
```

## Brave Browser

Brave Browser is preinstalled.

Inside this Docker environment Chromium's normal sandbox cannot initialize using the default container restrictions.

For this reason, the desktop launcher entries start Brave with:

```text
--no-sandbox
```

This is convenient for this isolated desktop container, but it reduces the browser's own process sandboxing.

If stronger browser isolation is required, the container security model should be adjusted instead of relying on `--no-sandbox`.

## Clipboard

RDP clipboard integration is enabled by the launcher:

```text
+clipboard
```

Text can be copied between the host and Debian desktop in both directions.

## Project structure

```text
debian-xfce-docker/
├── Dockerfile
├── README.md
├── start.sh
└── scripts/
    └── debian-xfce
```

### Dockerfile

Builds:

- Debian 13
- XFCE
- XRDP
- xorgxrdp
- x264 support
- Brave Browser
- Debian desktop user
- 60 Hz xorgxrdp patch

### start.sh

Starts the XRDP services inside the container and configures the RDP user's password.

### scripts/debian-xfce

Host-side launcher responsible for managing the container and opening the FreeRDP client.

## Useful commands

Container status:

```bash
docker ps -a --filter name=debian-xfce-rdp
```

Start:

```bash
docker start debian-xfce-rdp
```

Stop:

```bash
docker stop debian-xfce-rdp
```

Container logs:

```bash
docker logs debian-xfce-rdp
```

XRDP log:

```bash
docker exec debian-xfce-rdp tail -n 100 /var/log/xrdp.log
```

XRDP session manager log:

```bash
docker exec debian-xfce-rdp tail -n 100 /var/log/xrdp-sesman.log
```

Open a shell:

```bash
docker exec -it debian-xfce-rdp bash
```

Remove the container:

```bash
docker rm -f debian-xfce-rdp
```

Rebuild:

```bash
docker build -t debian-xfce:2.0.0 .
```

## Performance

The current version uses the RDP Graphics Pipeline with H.264/x264 instead of relying exclusively on RFX.

Compared with the previous RFX-based version, H.264 provides smoother desktop motion and window updates in the tested environment.

The x264 configuration prioritizes low latency:

```text
preset: ultrafast
tune: zerolatency
target: 60 FPS
```

Encoding is currently performed in software using x264.

## Versions

### v2.0.0

Major graphical transport upgrade.

- Replaced TigerVNC with XRDP.
- Added xorgxrdp.
- Added FreeRDP launcher support.
- Added bidirectional clipboard.
- Added Brave Browser.
- Added H.264 Graphics Pipeline support.
- Added x264 software encoding.
- Added RFX fallback.
- Updated XRDP to 0.10.6.1.
- Updated xorgxrdp to 0.10.5.
- Changed the virtual xorgxrdp display from 50 Hz to 60 Hz.
- Added automatic monitor-based window sizing.
- Added local launcher configuration support.

### v1.1.0

- Added automatic Debian XFCE launcher.
- Improved desktop startup workflow.

### v1.0.0

- Initial Debian 13 + XFCE Docker desktop.
- TigerVNC-based remote desktop access.

## Notes

This project is intended for Linux hosts.

Because Linux containers share the host kernel, this setup is significantly different from running a complete Debian virtual machine.

Running the image through Docker Desktop on Windows may be possible using its Linux VM / WSL2 backend, but the included Linux host launcher is not designed for native Windows usage.

## License

No license has been specified yet.
