FROM debian:13

ENV DEBIAN_FRONTEND=noninteractive

ARG XRDP_VERSION=0.10.6.1
ARG XORGXRDP_VERSION=0.10.5

# Escritorio + herramientas base
RUN apt-get update && \
    apt-get install -y \
        xfce4 \
        xfce4-terminal \
        dbus-x11 \
        procps \
        sudo \
        curl \
        wget \
        git \
        ca-certificates \
        ssl-cert \
        xserver-xorg-core \
        pipewire \
        pipewire-pulse \
        wireplumber \
        pipewire-module-xrdp \
        pulseaudio-utils && \
    apt-get purge -y pulseaudio && \
    rm -rf /var/lib/apt/lists/*

# ============================================================
# XRDP moderno compilado con H.264 / x264
# ============================================================

WORKDIR /tmp

RUN git clone \
        --depth 1 \
        --branch "v${XRDP_VERSION}" \
        https://github.com/neutrinolabs/xrdp.git \
        "/tmp/xrdp-${XRDP_VERSION}" && \
    cd "/tmp/xrdp-${XRDP_VERSION}" && \
    ./scripts/install_xrdp_build_dependencies_with_apt.sh min && \
    apt-get install -y --no-install-recommends \
        libfuse3-dev \
        libjpeg-dev \
        libopus-dev \
        libpixman-1-dev \
        libx264-dev && \
    ./bootstrap && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-socketdir=/run/xrdp/sockdir \
        --with-systemdsystemunitdir=no \
        --enable-pam \
        --enable-pam-config=debian \
        --enable-ipv6 \
        --enable-jpeg \
        --enable-fuse \
        --enable-opus \
        --enable-pixman \
        --enable-x264 && \
    make -j"$(nproc)" && \
    make install

# ============================================================
# xorgxrdp moderno
# ============================================================

RUN git clone \
        --depth 1 \
        --branch "v${XORGXRDP_VERSION}" \
        https://github.com/neutrinolabs/xorgxrdp.git \
        "/tmp/xorgxrdp-${XORGXRDP_VERSION}" && \
    cd "/tmp/xorgxrdp-${XORGXRDP_VERSION}" && \
    sed -i 's/const int vfreq = 50;/const int vfreq = 60;/' module/rdpRandR.c && \
    ./scripts/install_xorgxrdp_build_dependencies_with_apt.sh && \
    ./bootstrap && \
    ./configure --enable-glamor && \
    make -j"$(nproc)" && \
    make install

# XRDP necesita la ruta real de Xorg
RUN sed -i \
    's#param=Xorg#param=/usr/lib/xorg/Xorg#' \
    /etc/xrdp/sesman.ini

# Usuario interno de XRDP
RUN groupadd --system xrdp && \
    useradd \
        --system \
        --gid xrdp \
        --home-dir /run/xrdp \
        --shell /usr/sbin/nologin \
        xrdp && \
    usermod -aG ssl-cert xrdp

# Certificado TLS local
RUN make-ssl-cert generate-default-snakeoil && \
    ln -sf /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/xrdp/cert.pem && \
    ln -sf /etc/ssl/private/ssl-cert-snakeoil.key /etc/xrdp/key.pem

# ============================================================
# Brave
# ============================================================

RUN curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg && \
    curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
        https://brave-browser-apt-release.s3.brave.com/brave-browser.sources && \
    apt-get update && \
    apt-get install -y brave-browser && \
    rm -rf /var/lib/apt/lists/*

# ============================================================
# Usuario del escritorio
# ============================================================

RUN useradd -m -s /bin/bash debian && \
    echo 'debian:1234' | chpasswd && \
    usermod -aG sudo debian

# ============================================================
# Sesión XFCE + audio XRDP
# ============================================================

COPY start-xfce-xrdp /usr/local/bin/start-xfce-xrdp

RUN chmod +x /usr/local/bin/start-xfce-xrdp && \
    printf '%s\n' \
        'exec dbus-run-session -- /usr/local/bin/start-xfce-xrdp' \
        > /home/debian/.xsession && \
    chown debian:debian /home/debian/.xsession

# ============================================================
# Arranque del contenedor
# ============================================================

COPY start.sh /usr/local/bin/start-rdp

RUN chmod +x /usr/local/bin/start-rdp

ENV RDP_USER=debian

EXPOSE 3389

CMD ["/usr/local/bin/start-rdp"]
