FROM debian:13

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y \
        xfce4 \
        xfce4-terminal \
        xrdp \
        xorgxrdp \
        dbus-x11 \
        procps \
        sudo \
        curl \
        ca-certificates && \
    curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg && \
    curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
        https://brave-browser-apt-release.s3.brave.com/brave-browser.sources && \
    apt update && \
    apt install -y brave-browser && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i \
    's#Exec=/usr/bin/brave-browser-stable#Exec=/usr/bin/brave-browser-stable --no-sandbox#g' \
    /usr/share/applications/brave-browser.desktop \
    /usr/share/applications/com.brave.Browser.desktop

RUN useradd -m -s /bin/bash debian && \
    usermod -aG sudo debian

RUN echo "startxfce4" > /home/debian/.xsession && \
    chown debian:debian /home/debian/.xsession

COPY start.sh /usr/local/bin/start-rdp

RUN chmod +x /usr/local/bin/start-rdp

ENV RDP_USER=debian

EXPOSE 3389

CMD ["/usr/local/bin/start-rdp"]
