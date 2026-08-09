FROM debian:13

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y \
        xfce4 \
        tigervnc-standalone-server \
        tigervnc-tools \
        dbus-x11 \
        procps && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.config/tigervnc

COPY xstartup /root/.config/tigervnc/xstartup
COPY start.sh /usr/local/bin/start-desktop

RUN chmod +x /root/.config/tigervnc/xstartup && \
    chmod +x /usr/local/bin/start-desktop

EXPOSE 5901

ENV VNC_RESOLUTION=1280x1080

CMD ["/usr/local/bin/start-desktop"]

