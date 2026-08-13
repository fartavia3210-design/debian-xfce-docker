# Debian XFCE Docker

Escritorio **Debian 13 + XFCE** ejecutándose dentro de un contenedor Docker y accesible mediante **XRDP + FreeRDP 3**.

El proyecto permite tener un escritorio Linux completo y aislado sin necesidad de ejecutar una máquina virtual pesada.

Incluye soporte para:

* XFCE 4
* XRDP 0.10.6.1
* xorgxrdp 0.10.5
* H.264 mediante x264
* RFX como fallback
* pantalla virtual a 60 Hz
* audio mediante PipeWire + XRDP
* portapapeles bidireccional
* resolución y tamaño de ventana automáticos
* Brave Browser
* launcher automático
* SDL-FreeRDP 3
* XFreeRDP 3 como alternativa
* `/dev/shm` ampliado a 1 GB

---

# Arquitectura

Este proyecto **no es una máquina virtual**.

Docker comparte el kernel Linux del host mientras Debian ejecuta su propio:

* userspace
* escritorio
* aplicaciones
* servidor gráfico
* sesión XRDP
* stack de audio

La arquitectura general es:

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
    ├── xorgxrdp
    │
    ├── PipeWire
    │
    ├── WirePlumber
    │
    └── XRDP
    │
    ▼
FreeRDP 3
    │
    ▼
Desktop Window
```

---

# Características

## Debian 13

La imagen utiliza:

```text
debian:13
```

como base.

---

## XFCE

El entorno de escritorio utilizado es **XFCE**, elegido por su bajo consumo de recursos y buen funcionamiento dentro de contenedores.

Se incluyen, entre otros:

```text
xfce4
xfce4-terminal
dbus-x11
xserver-xorg-core
```

---

# XRDP

El proyecto no utiliza simplemente la versión de XRDP incluida por defecto en Debian.

Durante el build se compilan desde código fuente:

```text
XRDP:      0.10.6.1
xorgxrdp:  0.10.5
```

XRDP se construye con soporte para:

* PAM
* IPv6
* JPEG
* FUSE
* Opus
* Pixman
* H.264/x264

---

# H.264 / x264

XRDP utiliza su Graphics Pipeline con soporte para H.264.

La configuración está orientada a escritorio remoto de baja latencia.

El encoder utilizado actualmente es:

```text
x264
```

Por tanto, la codificación H.264 se realiza actualmente mediante **CPU/software**.

La configuración está orientada a:

```text
preset: ultrafast
tune: zerolatency
objetivo: 60 FPS
```

Si H.264 no puede negociarse, XRDP puede utilizar **RFX como fallback**.

---

# 60 Hz

Durante la compilación de xorgxrdp se modifica su frecuencia virtual:

```c
const int vfreq = 50;
```

por:

```c
const int vfreq = 60;
```

Esto permite que la sesión RDP pueda reportar una pantalla virtual cercana a:

```text
60.00 Hz
```

La resolución real depende del tamaño solicitado por el cliente FreeRDP.

---

# Audio

El proyecto utiliza **PipeWire** para transportar el audio generado dentro del contenedor hacia el host mediante XRDP.

Stack utilizado:

```text
pipewire
pipewire-pulse
wireplumber
pipewire-module-xrdp
pulseaudio-utils
```

El antiguo servidor PulseAudio no se utiliza como servidor principal.

La arquitectura de audio es:

```text
Aplicación dentro de Debian
        │
        ▼
pipewire-pulse
        │
        ▼
PipeWire
        │
        ▼
pipewire-module-xrdp
        │
        ├── xrdp-sink
        └── xrdp-source
        │
        ▼
xrdp-chansrv
        │
        ▼
RDP Audio
        │
        ▼
FreeRDP /sound
        │
        ▼
Audio del host
```

La sesión XFCE inicia automáticamente:

```text
PipeWire
WirePlumber
pipewire-pulse
XFCE
```

El módulo `pipewire-module-xrdp` se carga dentro de la sesión gráfica y crea:

```text
xrdp-sink
xrdp-source
```

El launcher activa el audio de FreeRDP mediante:

```text
/sound
```

---

# Portapapeles

El launcher activa integración de portapapeles mediante FreeRDP:

```text
+clipboard
```

Esto permite copiar y pegar entre:

```text
Host ↔ Debian XFCE
```

---

# Brave Browser

Brave Browser se instala automáticamente durante el build.

> [!WARNING]
> Actualmente esta versión del proyecto todavía inicia Brave utilizando `--no-sandbox`.
>
> Esta configuración está pendiente de ser sustituida por una implementación con sandbox real antes de considerar la parte de seguridad completamente terminada.

---

# `/dev/shm`

Se recomienda crear el contenedor con:

```text
--shm-size=1g
```

No se recomienda utilizar el valor predeterminado pequeño de Docker, especialmente para navegadores basados en Chromium como Brave.

---

# Requisitos

El host debe utilizar Linux y disponer de:

* Docker
* Git
* FreeRDP 3

El launcher soporta:

```text
sdl-freerdp3
```

y como alternativa:

```text
xfreerdp3
```

Actualmente el launcher prefiere SDL-FreeRDP cuando ambos están disponibles.

---

# Instalación en Arch Linux / CachyOS

Instala las dependencias:

```bash
sudo pacman -S docker freerdp git
```

Activa Docker:

```bash
sudo systemctl enable --now docker
```

Agrega tu usuario al grupo Docker:

```bash
sudo usermod -aG docker "$USER"
```

Después debes **cerrar sesión y volver a entrar**, o reiniciar el equipo, para que el nuevo grupo tenga efecto.

Comprueba:

```bash
docker info
```

Si funciona sin `sudo`, Docker está listo.

---

# Clonar el repositorio

```bash
git clone https://github.com/fartavia3210-design/debian-xfce-docker.git
```

Entra al proyecto:

```bash
cd debian-xfce-docker
```

---

# Construir la imagen

Construye la imagen:

```bash
docker build -t debian-xfce:latest .
```

La primera compilación puede tardar varios minutos porque XRDP y xorgxrdp se compilan desde código fuente.

Comprueba que exista:

```bash
docker images | grep debian-xfce
```

Deberías ver algo parecido a:

```text
debian-xfce   latest
```

---

# Crear el contenedor

Crea el contenedor con:

```bash
docker create \
    --name debian-xfce-rdp \
    --shm-size=1g \
    -p 127.0.0.1:3389:3389 \
    -e RDP_PASSWORD='TU_CONTRASEÑA' \
    debian-xfce:latest
```

Cambia:

```text
TU_CONTRASEÑA
```

por la contraseña que quieras utilizar.

Por ejemplo:

```bash
docker create \
    --name debian-xfce-rdp \
    --shm-size=1g \
    -p 127.0.0.1:3389:3389 \
    -e RDP_PASSWORD='debian123' \
    debian-xfce:latest
```

El usuario interno del escritorio es:

```text
debian
```

---

# ¿Por qué `127.0.0.1`?

El puerto se publica como:

```text
127.0.0.1:3389
```

en lugar de:

```text
0.0.0.0:3389
```

De esta forma XRDP solamente queda accesible desde el mismo host y no se expone directamente a otros dispositivos de la red.

---

# Instalar el launcher

El repositorio incluye:

```text
scripts/debian-xfce
```

Cópialo a:

```text
~/.local/bin
```

con:

```bash
mkdir -p ~/.local/bin
cp scripts/debian-xfce ~/.local/bin/debian-xfce
chmod +x ~/.local/bin/debian-xfce
```

Comprueba:

```bash
command -v debian-xfce
```

Si devuelve:

```text
/home/TU_USUARIO/.local/bin/debian-xfce
```

ya está listo.

---

# Abrir Debian XFCE

Una vez construida la imagen, creado el contenedor e instalado el launcher, simplemente ejecuta:

```bash
debian-xfce
```

El launcher automáticamente:

1. Comprueba que Docker esté instalado.
2. Comprueba que exista `debian-xfce-rdp`.
3. Detecta SDL-FreeRDP 3 o XFreeRDP 3.
4. Arranca el contenedor si estaba detenido.
5. Espera a que XRDP y `xrdp-sesman` estén preparados.
6. Lee las credenciales RDP desde la configuración del contenedor.
7. Detecta el tamaño del monitor.
8. Calcula el tamaño inicial de la ventana.
9. Abre Debian XFCE mediante FreeRDP.
10. Activa portapapeles.
11. Activa audio.
12. Detiene el contenedor al cerrar la ventana si fue el launcher quien lo inició.

---

# Tamaño automático de la ventana

Por defecto el launcher utiliza aproximadamente:

```text
90 % del ancho
90 % del alto
```

del monitor.

En Hyprland utiliza:

```text
hyprctl
```

para detectar el monitor activo.

En escritorios X11 utiliza:

```text
xrandr
```

como fallback.

Si ninguno está disponible utiliza:

```text
1920x1080
```

como último fallback.

---

# Configurar el tamaño de la ventana

Puedes crear:

```text
~/.config/debian-xfce-docker/config
```

Por ejemplo:

```bash
mkdir -p ~/.config/debian-xfce-docker
nano ~/.config/debian-xfce-docker/config
```

Y configurar:

```bash
WINDOW_PERCENT_W=85
WINDOW_PERCENT_H=85
```

Por ejemplo, para utilizar casi toda la pantalla:

```bash
WINDOW_PERCENT_W=95
WINDOW_PERCENT_H=95
```

---

# Abrir manualmente sin launcher

También puedes iniciar todo manualmente.

Primero arranca el contenedor:

```bash
docker start debian-xfce-rdp
```

Comprueba:

```bash
docker ps --filter name=debian-xfce-rdp
```

Después conecta con XFreeRDP:

```bash
xfreerdp3 \
    /v:127.0.0.1:3389 \
    /u:debian \
    /p:'TU_CONTRASEÑA' \
    /cert:ignore \
    /dynamic-resolution \
    /clipboard \
    /sound
```

O con SDL-FreeRDP:

```bash
sdl-freerdp3 \
    /v:127.0.0.1:3389 \
    /u:debian \
    /p:'TU_CONTRASEÑA' \
    /cert:ignore \
    /dynamic-resolution \
    /clipboard \
    /sound
```

---

# Detener Debian XFCE

Si utilizaste el launcher y fue el launcher quien arrancó el contenedor, este lo detendrá automáticamente cuando cierres FreeRDP.

También puedes detenerlo manualmente:

```bash
docker stop debian-xfce-rdp
```

---

# Volver a abrirlo

No necesitas reconstruir la imagen cada vez.

Simplemente ejecuta:

```bash
debian-xfce
```

El contenedor existente será reutilizado.

---

# Estado del contenedor

Verifica si está ejecutándose:

```bash
docker ps --filter name=debian-xfce-rdp
```

Para incluir contenedores detenidos:

```bash
docker ps -a --filter name=debian-xfce-rdp
```

---

# Ver logs

Logs principales del contenedor:

```bash
docker logs debian-xfce-rdp
```

Últimas 50 líneas:

```bash
docker logs --tail 50 debian-xfce-rdp
```

---

# Diagnóstico de audio

Con una sesión RDP abierta puedes comprobar los procesos:

```bash
docker exec debian-xfce-rdp sh -lc '
ps -ef | grep -E "[p]ipewire|[w]ireplumber|[x]rdp-chansrv"
'
```

Deberían existir procesos similares a:

```text
pipewire
wireplumber
pipewire-pulse
xrdp-chansrv
```

Para comprobar el servidor de audio:

```bash
docker exec debian-xfce-rdp sh -lc '
su - debian -c "XDG_RUNTIME_DIR=/run/user/\$(id -u) pactl info"
'
```

La salida debería indicar algo similar a:

```text
Server Name: PulseAudio (on PipeWire 1.4.2)
Default Sink: xrdp-sink
Default Source: xrdp-source
```

Puedes comprobar los sinks con:

```bash
docker exec debian-xfce-rdp sh -lc '
su - debian -c "XDG_RUNTIME_DIR=/run/user/\$(id -u) pactl list short sinks"
'
```

Debería aparecer:

```text
xrdp-sink
```

---

# Puerto 3389 ocupado

Si aparece un error parecido a:

```text
Bind for 127.0.0.1:3389 failed: port is already allocated
```

algún otro proceso o contenedor ya está utilizando el puerto.

Comprueba Docker:

```bash
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}' | grep 3389
```

También puedes comprobar el host:

```bash
ss -ltnp | grep ':3389'
```

Detén el servicio o contenedor que esté utilizando el puerto antes de iniciar `debian-xfce-rdp`.

---

# Crear una instancia de prueba en otro puerto

Para hacer pruebas sin interferir con otro escritorio RDP puedes utilizar otro puerto del host.

Por ejemplo:

```bash
docker run -d \
    --name debian-xfce-test \
    --shm-size=1g \
    -p 127.0.0.1:3390:3389 \
    -e RDP_PASSWORD='debian' \
    debian-xfce:latest
```

Después conecta mediante:

```bash
xfreerdp3 \
    /v:127.0.0.1:3390 \
    /u:debian \
    /p:debian \
    /cert:ignore \
    /dynamic-resolution \
    /clipboard \
    /sound
```

---

# Eliminar el contenedor

```bash
docker rm -f debian-xfce-rdp
```

Esto elimina el contenedor, pero no la imagen.

---

# Eliminar la imagen

Primero elimina cualquier contenedor que la esté utilizando.

Después:

```bash
docker image rm debian-xfce:latest
```

---

# Reconstruir después de actualizar

Actualiza el repositorio:

```bash
git pull
```

Reconstruye:

```bash
docker build --no-cache -t debian-xfce:latest .
```

Si quieres recrear completamente el contenedor:

```bash
docker rm -f debian-xfce-rdp
```

y luego:

```bash
docker create \
    --name debian-xfce-rdp \
    --shm-size=1g \
    -p 127.0.0.1:3389:3389 \
    -e RDP_PASSWORD='TU_CONTRASEÑA' \
    debian-xfce:latest
```

---

# Archivos principales

```text
debian-xfce-docker/
├── Dockerfile
├── README.md
├── start.sh
├── start-xfce-xrdp
└── scripts/
    └── debian-xfce
```

## `Dockerfile`

Construye:

* Debian 13
* XFCE
* XRDP
* xorgxrdp
* H.264/x264
* PipeWire
* integración XRDP de audio
* Brave Browser

## `start.sh`

Es el proceso de entrada del contenedor.

Se encarga de:

* configurar la contraseña RDP
* preparar `/run/xrdp`
* preparar `/run/user/<UID>`
* iniciar `xrdp-sesman`
* iniciar XRDP

## `start-xfce-xrdp`

Se ejecuta dentro de la sesión del usuario.

Inicia:

```text
PipeWire
WirePlumber
pipewire-pulse
XFCE
```

y limpia los procesos de audio cuando la sesión termina.

## `scripts/debian-xfce`

Launcher ejecutado en el host.

Se encarga del ciclo completo de apertura del escritorio.

---

# Flujo de arranque

```text
debian-xfce
     │
     ▼
Docker container
     │
     ▼
start.sh
     │
     ├── /run/xrdp
     ├── /run/user/1000
     ├── xrdp-sesman
     └── xrdp
            │
            ▼
       Login RDP
            │
            ▼
       .xsession
            │
            ▼
     dbus-run-session
            │
            ▼
    start-xfce-xrdp
            │
            ├── PipeWire
            ├── WirePlumber
            ├── pipewire-pulse
            └── XFCE
                    │
                    ▼
            pipewire-module-xrdp
                    │
                    ▼
              xrdp-sink
                    │
                    ▼
                 /sound
                    │
                    ▼
                 Host
```

---

# Rendimiento

Esta versión debe considerarse el modo **Standard** del proyecto.

Actualmente utiliza:

```text
XRDP
xorgxrdp
H.264
x264 por CPU
60 Hz
XFCE
```

No utiliza todavía una ruta completa de GPU dentro del contenedor.

Opciones como:

* `/dev/dri/renderD*`
* VA-API
* codificación H.264 mediante hardware
* GPU passthrough parcial
* Sunshine + Moonlight
* Xpra
* Waypipe

pertenecen a experimentos futuros de rendimiento y no forman parte de la configuración Standard actual.

El objetivo del modo Standard es mantener:

* bajo consumo
* buena compatibilidad
* estabilidad
* facilidad de instalación
* buena fluidez sin convertir el contenedor en una VM pesada

---

# Seguridad

El puerto XRDP se limita por defecto a:

```text
127.0.0.1
```

para evitar exposición directa a la red.

No se recomienda publicar el puerto:

```text
0.0.0.0:3389
```

sin implementar medidas adicionales de seguridad.

También se recomienda utilizar una contraseña RDP fuerte.

> [!WARNING]
> Brave todavía utiliza `--no-sandbox` en esta versión.
>
> Esta parte se encuentra pendiente de migración hacia una configuración con sandbox real.

---

# Proyecto

Repositorio:

```text
https://github.com/fartavia3210-design/debian-xfce-docker
```

Proyecto relacionado:

```text
Linux Desktop Containers
```

El objetivo general es investigar y desarrollar escritorios Linux completos, ligeros y reutilizables ejecutándose dentro de contenedores Docker.
