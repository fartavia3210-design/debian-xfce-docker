# Debian XFCE Docker

Debian 13 con escritorio **XFCE** ejecutándose dentro de Docker y accesible mediante **XRDP + FreeRDP 3**.

Este repositorio contiene la imagen base de Debian + XFCE que posteriormente será integrada en el proyecto principal **Linux Desktop Containers**.

La meta es ofrecer un escritorio Linux completo, ligero y aislado, sin necesidad de ejecutar una máquina virtual completa.

---

# Estado actual

La imagen Standard se encuentra funcional y probada con:

* Debian 13
* XFCE
* XRDP 0.10.6.1
* xorgxrdp 0.10.5
* Xorg
* H.264 mediante x264
* pantalla virtual configurada a 60 Hz
* audio RDP mediante PipeWire
* WirePlumber
* `pipewire-pulse`
* `pipewire-module-xrdp`
* portapapeles RDP
* Brave Browser
* sandbox real de Brave
* usuario RDP predeterminado
* contraseña RDP predeterminada
* `/dev/shm` de 1 GB recomendado

La imagen fue probada correctamente en sesiones RDP desde diferentes hosts Linux.

---

# Objetivo del repositorio

Este repositorio **no pretende ser el administrador final de escritorios**.

Su función es desarrollar y estabilizar la imagen:

```text
Debian 13
   +
XFCE
   +
XRDP
   +
Audio
   +
Brave
```

El proyecto principal:

```text
Linux Desktop Containers
```

será el responsable posteriormente de:

* instalar dependencias del host;
* descargar imágenes desde GHCR;
* crear contenedores;
* asignar puertos;
* aplicar perfiles de seguridad;
* detectar SELinux/AppArmor;
* crear accesos directos;
* ejecutar FreeRDP;
* administrar múltiples distribuciones y escritorios.

Repositorio principal:

```text
https://github.com/fartavia3210-design/linux-desktop-containers
```

---

# Arquitectura

La arquitectura actual es:

```text
Host Linux
    │
    ▼
Docker
    │
    ▼
Debian 13
    │
    ├── XFCE
    ├── Xorg
    ├── xorgxrdp
    ├── XRDP
    ├── PipeWire
    ├── WirePlumber
    ├── Brave
    └── aplicaciones
    │
    ▼
RDP
    │
    ▼
FreeRDP 3
    │
    ▼
Ventana del escritorio Debian
```

Docker comparte el kernel del host, por lo que esto **no es una máquina virtual tradicional**.

---

# Componentes principales

## Debian

Imagen base:

```text
debian:13
```

---

## XFCE

El escritorio utiliza XFCE por su bajo consumo de recursos y buena compatibilidad con Xorg/XRDP.

Se instalan, entre otros:

```text
xfce4
xfce4-terminal
dbus-x11
xserver-xorg-core
```

---

# XRDP

XRDP se compila desde código fuente.

Versión:

```text
0.10.6.1
```

Configuración utilizada:

```text
--enable-pam
--enable-ipv6
--enable-jpeg
--enable-fuse
--enable-opus
--enable-pixman
--enable-x264
```

Esto permite utilizar funcionalidades gráficas modernas de XRDP, incluyendo H.264 mediante x264.

---

# xorgxrdp

Versión:

```text
0.10.5
```

También se compila desde código fuente.

Configuración:

```text
--enable-glamor
```

> `--enable-glamor` por sí solo no significa que esta imagen tenga una ruta completa de aceleración GPU.

Actualmente el modo Standard sigue estando diseñado para funcionar sin requerir acceso directo a GPU.

---

# 60 Hz

Durante el build se modifica xorgxrdp para cambiar:

```c
const int vfreq = 50;
```

por:

```c
const int vfreq = 60;
```

Esto permite que la pantalla virtual de la sesión XRDP trabaje a aproximadamente:

```text
60 Hz
```

---

# H.264

XRDP se compila con:

```text
--enable-x264
```

Por lo tanto, esta imagen puede utilizar H.264 mediante x264.

Actualmente la codificación se realiza principalmente mediante **CPU/software**.

No se utiliza todavía:

* VA-API;
* NVENC;
* AMF;
* Quick Sync;
* `/dev/dri/renderD*`;
* codificación H.264 por hardware.

Estas opciones pertenecen a futuros experimentos de rendimiento.

---

# Audio RDP

El audio está completamente implementado mediante PipeWire.

Paquetes principales:

```text
pipewire
pipewire-pulse
wireplumber
pipewire-module-xrdp
pulseaudio-utils
```

El servidor PulseAudio tradicional no se utiliza.

La arquitectura es:

```text
Aplicación Debian
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

Durante una sesión funcional se verificó:

```text
Server Name: PulseAudio (on PipeWire 1.4.2)
Default Sink: xrdp-sink
Default Source: xrdp-source
```

También se comprobaron los procesos:

```text
pipewire
wireplumber
pipewire-pulse
xrdp-chansrv
```

---

# Inicio de la sesión

El contenedor utiliza:

```text
start.sh
```

para preparar XRDP y el runtime del usuario.

El flujo es:

```text
Docker
   │
   ▼
start.sh
   │
   ├── /run/xrdp
   ├── /run/user/<UID>
   ├── xrdp-sesman
   └── xrdp
```

Cuando el usuario inicia sesión:

```text
XRDP
   │
   ▼
~/.xsession
   │
   ▼
dbus-run-session
   │
   ▼
start-xfce-xrdp
```

`start-xfce-xrdp` inicia:

```text
PipeWire
WirePlumber
pipewire-pulse
XFCE
```

---

# Usuario y contraseña

La imagen ya incluye una credencial RDP interna predeterminada.

Usuario:

```text
debian
```

Contraseña:

```text
1234
```

La contraseña se establece durante el build.

Por lo tanto, **ya no es necesario pasar**:

```text
-e RDP_PASSWORD=...
```

al crear el contenedor.

Esto está pensado para el modo local del proyecto, donde XRDP se publica únicamente sobre:

```text
127.0.0.1
```

La contraseña `1234` no debe considerarse una contraseña segura para publicar XRDP directamente a Internet.

---

# Brave Browser

Brave Browser se instala desde su repositorio oficial durante el build.

La imagen **ya no utiliza**:

```text
--no-sandbox
```

Brave se ejecuta con su sandbox real.

---

# Sandbox de Brave

Para que Brave pueda ejecutar correctamente su sandbox dentro de Docker, el contenedor debe crearse utilizando el perfil seccomp del proyecto principal:

```text
common/security/seccomp-brave.json
```

El perfil se encuentra en:

```text
linux-desktop-containers/common/security/seccomp-brave.json
```

La imagen fue probada con dicho perfil.

En:

```text
brave://sandbox
```

se obtuvo:

```text
Layer 1 Sandbox                         Namespace
PID namespaces                          Yes
Network namespaces                      Yes
Seccomp-BPF sandbox                     Yes
Seccomp-BPF sandbox supports TSYNC      Yes
Ptrace Protection with Yama LSM         Yes
```

Brave reportó:

```text
You are adequately sandboxed.
```

Por lo tanto, Brave funciona sin:

```text
--no-sandbox
```

y sin:

```text
--privileged
```

ni:

```text
seccomp=unconfined
```

---

# Yama LSM

En algunas máquinas:

```text
Ptrace Protection with Yama LSM (Non-broker)
```

puede aparecer como:

```text
No
```

mientras el resto del sandbox aparece correctamente activo.

Esto no implica por sí solo que Brave esté funcionando sin sandbox.

La validación realizada mostró:

```text
You are adequately sandboxed.
```

junto con Namespace Sandbox y Seccomp-BPF activos.

---

# `/dev/shm`

El contenedor debe crearse con:

```text
--shm-size=1g
```

No se recomienda utilizar el valor predeterminado pequeño de Docker.

Esto es especialmente importante para navegadores Chromium/Brave.

---

# Seguridad de red

Para el modo Standard local, XRDP debe publicarse únicamente sobre:

```text
127.0.0.1
```

Ejemplo:

```text
127.0.0.1:3392:3389
```

Esto significa que XRDP solamente puede ser accedido desde el propio host.

No se recomienda publicar directamente:

```text
0.0.0.0:3389
```

especialmente utilizando la contraseña interna predeterminada.

El soporte remoto mediante VPN/servidor podrá añadirse en el futuro como una arquitectura separada.

---

# Requisitos

Para realizar pruebas manuales se necesita:

* Linux
* Docker
* Git
* FreeRDP 3

El proyecto ha sido desarrollado principalmente desde:

```text
CachyOS / Arch Linux
```

y también se ha probado desde otros hosts Linux.

---

# Instalación en Arch Linux / CachyOS

Instala:

```bash
sudo pacman -S docker freerdp git
```

Activa Docker:

```bash
sudo systemctl enable --now docker
```

Agrega el usuario actual al grupo Docker:

```bash
sudo usermod -aG docker "$USER"
```

Después cierra sesión y vuelve a entrar, o reinicia el equipo.

Comprueba:

```bash
docker info
```

Debe funcionar sin utilizar `sudo`.

---

# Instalación en Debian / Ubuntu

Instala Git y FreeRDP junto con Docker utilizando los paquetes apropiados para tu distribución.

Después comprueba:

```bash
docker --version
```

y:

```bash
xfreerdp3 /version
```

o:

```bash
sdl-freerdp3 /version
```

Dependiendo del cliente disponible.

El usuario que ejecuta el proyecto debe tener permiso para utilizar Docker.

---

# Clonar este repositorio

```bash
git clone https://github.com/fartavia3210-design/debian-xfce-docker.git
```

Entra:

```bash
cd debian-xfce-docker
```

---

# Construir la imagen

```bash
docker build -t debian-xfce:latest .
```

La primera compilación puede tardar varios minutos porque:

* XRDP se compila desde source;
* xorgxrdp se compila desde source;
* Brave se instala;
* XFCE y PipeWire se instalan.

Para hacer un build totalmente limpio:

```bash
docker build --no-cache -t debian-xfce:latest .
```

---

# Perfil seccomp de Brave

Para ejecutar Brave con su sandbox completo se necesita:

```text
seccomp-brave.json
```

Actualmente este perfil pertenece al proyecto principal:

```text
linux-desktop-containers/common/security/seccomp-brave.json
```

Si tienes ambos proyectos:

```text
~/Documentos/Proyectos/Distro Dockers/
├── debian-xfce-docker/
└── linux-desktop-containers/
```

el perfil se encuentra en:

```text
~/Documentos/Proyectos/Distro Dockers/linux-desktop-containers/common/security/seccomp-brave.json
```

---

# Crear un contenedor manualmente

Ejemplo para pruebas locales:

```bash
docker run -d \
    --name debian-xfce \
    --shm-size=1g \
    -p 127.0.0.1:3389:3389 \
    --security-opt seccomp="$HOME/Documentos/Proyectos/Distro Dockers/linux-desktop-containers/common/security/seccomp-brave.json" \
    debian-xfce:latest
```

No es necesario pasar ninguna contraseña mediante variables de entorno.

---

# Si el puerto 3389 está ocupado

Puedes utilizar otro puerto del host.

Por ejemplo:

```bash
docker run -d \
    --name debian-xfce \
    --shm-size=1g \
    -p 127.0.0.1:3390:3389 \
    --security-opt seccomp="$HOME/Documentos/Proyectos/Distro Dockers/linux-desktop-containers/common/security/seccomp-brave.json" \
    debian-xfce:latest
```

Aquí:

```text
3390 = puerto del host
3389 = puerto XRDP dentro del contenedor
```

---

# Abrir Debian XFCE manualmente

Con XFreeRDP 3:

```bash
xfreerdp3 \
    /v:127.0.0.1:3390 \
    /u:debian \
    /p:1234 \
    /cert:ignore \
    /dynamic-resolution \
    /clipboard \
    /sound
```

Con SDL-FreeRDP:

```bash
sdl-freerdp3 \
    /v:127.0.0.1:3390 \
    /u:debian \
    /p:1234 \
    /cert:ignore \
    /dynamic-resolution \
    /clipboard \
    /sound
```

---

# Parámetros RDP probados

Para Debian XFCE se ha probado correctamente:

```text
/dynamic-resolution
/clipboard
/sound
/cert:ignore
```

Estos parámetros no deben asumirse necesariamente como óptimos para todas las demás distribuciones.

El proyecto principal Linux Desktop Containers podrá definir parámetros RDP específicos por combinación:

```text
Distribución + Escritorio
```

por ejemplo:

```text
Arch + XFCE
Debian + XFCE
Fedora + KDE
Ubuntu + GNOME
```

Esto evita modificar una configuración estable de una distribución para solucionar otra.

---

# Comprobar que el contenedor está activo

```bash
docker ps
```

O:

```bash
docker ps --filter name=debian-xfce
```

---

# Detener el contenedor

```bash
docker stop debian-xfce
```

---

# Volver a iniciarlo

```bash
docker start debian-xfce
```

---

# Eliminar el contenedor

```bash
docker rm -f debian-xfce
```

---

# Ver logs

```bash
docker logs debian-xfce
```

Últimas líneas:

```bash
docker logs --tail 50 debian-xfce
```

---

# Diagnóstico de audio

Con una sesión XRDP abierta:

```bash
docker exec debian-xfce sh -lc '
ps -ef | grep -E "[p]ipewire|[w]ireplumber|[x]rdp-chansrv"
'
```

Se espera encontrar:

```text
pipewire
wireplumber
pipewire-pulse
xrdp-chansrv
```

---

# Comprobar PipeWire

```bash
docker exec debian-xfce sh -lc '
su - debian -c "XDG_RUNTIME_DIR=/run/user/\$(id -u) pactl info"
'
```

Una sesión correcta debería mostrar algo similar a:

```text
Server Name: PulseAudio (on PipeWire 1.4.2)
Default Sink: xrdp-sink
Default Source: xrdp-source
```

---

# Comprobar sinks

```bash
docker exec debian-xfce sh -lc '
su - debian -c "XDG_RUNTIME_DIR=/run/user/\$(id -u) pactl list short sinks"
'
```

Debe aparecer:

```text
xrdp-sink
```

---

# Comprobar Brave

Abre Brave desde XFCE.

Después visita:

```text
brave://sandbox
```

Debe mostrar activos al menos:

```text
Namespace Sandbox
PID namespaces
Network namespaces
Seccomp-BPF
TSYNC
```

y al final:

```text
You are adequately sandboxed.
```

---

# Puerto ocupado

Si Docker devuelve:

```text
Bind for 127.0.0.1:3389 failed: port is already allocated
```

comprueba:

```bash
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}' | grep 3389
```

También:

```bash
ss -ltnp | grep ':3389'
```

Utiliza otro puerto del host o detén el proceso que esté ocupándolo.

---

# Archivos del proyecto

```text
debian-xfce-docker/
├── Dockerfile
├── README.md
├── start.sh
├── start-xfce-xrdp
└── scripts/
    └── debian-xfce
```

---

# Dockerfile

El `Dockerfile` construye:

```text
Debian 13
XFCE
XRDP 0.10.6.1
xorgxrdp 0.10.5
H.264/x264
PipeWire
WirePlumber
pipewire-module-xrdp
Brave Browser
usuario debian
password 1234
```

---

# start.sh

Se ejecuta como proceso inicial del contenedor.

Prepara:

```text
/run/xrdp
/run/user/<UID>
```

y después inicia:

```text
xrdp-sesman
xrdp
```

---

# start-xfce-xrdp

Se ejecuta dentro de la sesión gráfica del usuario.

Inicia:

```text
PipeWire
WirePlumber
pipewire-pulse
XFCE
```

Después limpia los procesos cuando termina la sesión.

---

# scripts/debian-xfce

Este launcher pertenece al desarrollo standalone original del proyecto.

Puede utilizarse para pruebas manuales, pero **no es la arquitectura final prevista para Linux Desktop Containers**.

El administrador principal dispondrá de su propio launcher genérico y configuración específica por distribución/escritorio.

---

# Integración futura con Linux Desktop Containers

Cuando esta imagen se integre en el proyecto principal, el flujo esperado será:

```text
linux-desktops
       │
       ▼
Debian
       │
       ▼
XFCE
       │
       ▼
Instalar
       │
       ▼
GHCR
       │
       ▼
docker pull
       │
       ▼
docker create
       │
       ├── localhost
       ├── puerto automático
       ├── shm 1g
       ├── seccomp Brave
       └── seguridad del host
       │
       ▼
Acceso directo
       │
       ▼
FreeRDP
       │
       ▼
Debian XFCE
```

---

# GitHub Container Registry

La imagen final del proyecto principal está pensada para publicarse mediante:

```text
GitHub Container Registry
```

o:

```text
GHCR
```

El formato esperado será:

```text
ghcr.io/fartavia3210-design/linux-desktop-containers/debian-xfce:latest
```

Esto permitirá que el usuario final no tenga que compilar XRDP ni construir la imagen localmente.

El administrador simplemente podrá descargarla mediante:

```text
docker pull
```

---

# Seguridad por host

La imagen no debe encargarse por sí sola de modificar la seguridad global del host.

El proyecto principal Linux Desktop Containers se encargará de manejar:

```text
seccomp
AppArmor
SELinux
```

según corresponda.

El perfil seccomp de Brave es independiente de las políticas específicas de SELinux/AppArmor.

No utilizar:

```text
--privileged
```

No utilizar:

```text
seccomp=unconfined
```

No desactivar SELinux globalmente.

---

# Modo Standard

Esta configuración representa el futuro:

```text
Debian XFCE — Standard
```

Prioridades:

* estabilidad;
* compatibilidad;
* bajo consumo;
* buena fluidez;
* seguridad;
* facilidad de mantenimiento;
* funcionamiento en varios hosts Linux.

---

# Futuro modo Performance

Después de terminar e integrar el modo Standard se podrán experimentar opciones como:

```text
/dev/dri/renderD*
Mesa
VA-API
GPU real
H.264 por hardware
Xpra
Waypipe
Sunshine + Moonlight
```

Pero estas mejoras deberán mantenerse separadas del modo Standard.

El objetivo será comparar:

* RAM;
* CPU en reposo;
* CPU moviendo ventanas;
* reproducción de video;
* latencia;
* scrolling;
* frame pacing;
* uso de GPU;
* tiempo de arranque;
* complejidad;
* compatibilidad;
* seguridad.

La meta es mejorar notablemente la fluidez **sin convertir el proyecto en una máquina virtual pesada**.

---

# Principios del proyecto

1. No romper una distribución para arreglar otra.
2. Mantener configuraciones específicas por distro/escritorio cuando sea necesario.
3. No desactivar seguridad globalmente.
4. Mantener `/dev/shm` adecuado.
5. Utilizar sandbox real en Brave.
6. Mantener el modo Standard estable.
7. Probar cambios antes de integrarlos al administrador principal.
8. Mantener Docker ligero frente a una VM tradicional.
9. Diseñar el proyecto para poder crecer a múltiples distribuciones.
10. Mantener abierta la posibilidad de un futuro modo remoto seguro.

---

# Estado de Debian XFCE Standard

```text
Debian 13                         ✅
XFCE                              ✅
Xorg                              ✅
XRDP 0.10.6.1                     ✅
xorgxrdp 0.10.5                   ✅
H.264 / x264                      ✅
60 Hz                             ✅
Audio PipeWire                    ✅
xrdp-sink                         ✅
xrdp-source                       ✅
Clipboard                         ✅
Usuario debian                    ✅
Password interno 1234             ✅
RDP_PASSWORD externo eliminado    ✅
Brave instalado                   ✅
Brave sin --no-sandbox            ✅
Namespace Sandbox                 ✅
PID namespaces                    ✅
Network namespaces                ✅
Seccomp-BPF                       ✅
TSYNC                             ✅
You are adequately sandboxed      ✅
shm 1 GB                          ✅
```

La siguiente etapa del proyecto es integrar esta imagen en:

```text
Linux Desktop Containers
```

manteniendo intacta la configuración estable existente de Arch XFCE.
