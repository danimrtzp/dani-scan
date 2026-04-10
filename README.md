```
    ██████╗  █████╗ ███╗   ██╗██╗    ███████╗ ██████╗ █████╗ ███╗   ██╗
    ██╔══██╗██╔══██╗████╗  ██║██║    ██╔════╝██╔════╝██╔══██╗████╗  ██║
    ██║  ██║███████║██╔██╗ ██║██║    ███████╗██║     ███████║██╔██╗ ██║
    ██║  ██║██╔══██║██║╚██╗██║██║    ╚════██║██║     ██╔══██║██║╚██╗██║
    ██████╔╝██║  ██║██║ ╚████║██║    ███████║╚██████╗██║  ██║██║ ╚████║
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝
```

<div align="center">

**Network Scanner & OS Fingerprinting Tool**

![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-7.0-cyan?style=for-the-badge)
![Stars](https://img.shields.io/github/stars/danimrtzp/dani-scan?style=for-the-badge&color=yellow)

</div>

---

## ¿Que es DANI-SCAN?

Herramienta de escaneo de red en **Bash puro** que detecta todos los dispositivos activos en tu red local e identifica su sistema operativo, tipo de dispositivo, fabricante y hostname — incluso cuando el firewall bloquea el ping.

Detecta Samsung SmartTV y LG SmartTV con modelo exacto, identifica moviles con MAC aleatoria (privacidad WiFi de iOS y Android), diferencia Mac de Linux sacando la distro exacta por banner SSH, y detecta Windows aunque tenga los puertos filtrados gracias al analisis del TTL. Ademas incluye informacion util para pentesting como recursos SMB compartidos y puertos vulnerables abiertos en Linux.

---

## Instalacion

```bash
git clone https://github.com/danimrtzp/dani-scan.git
cd dani-scan
sudo bash dani-scan.sh
```

La primera vez que lo ejecutas el script se instala automaticamente en `/usr/local/bin` y las dependencias se instalan sin preguntar segun tu distro. A partir de ese momento lo ejecutas desde cualquier lugar:

```bash
sudo dani-scan
```

---

## Uso

```
[?] Interfaz de red (ej: wlp3s0, eth0, wlan0)
❯ wlp3s0

[?] Red a escanear (ej: 192.168.1 / 172.20.10)
❯ 172.20.10
```

Al terminar el escaneo te pregunta si quieres lanzar un nmap completo a algun host y donde guardar el log.

---

## Cadena de deteccion

Para cada host encontrado por ARP-scan el script sigue este orden hasta identificarlo:

```
HOST ENCONTRADO POR ARP
        │
        ├─► Samsung SmartTV API  (puerto 8001)
        │       └─ Nombre, modelo exacto, OS Tizen, resolucion, estado on/off
        │
        ├─► LG SmartTV API  (puertos 3000 / 1925)
        │       └─ WebOS, modelo
        │
        ├─► UPnP / DLNA  (9197, 9098, 49152...)
        │       └─ Tipo, fabricante, modelo
        │
        ├─► MAC aleatoria  (bit de privacidad WiFi iOS 14+ / Android 10+)
        │       ├─ TTL primero → si TTL=128 es Windows aunque tenga firewall
        │       └─ Puertos → 62078=iPhone · 5000/7000=Mac · 445/3389=Windows
        │
        ├─► OUI de MAC real  (fabricante)
        │       ├─ Apple → distingue iPhone/iPad de Mac (puerto lockdown 62078)
        │       ├─ Samsung Mobile / TV  │  LG Mobile / TV
        │       ├─ Xiaomi · Motorola · Huawei · OnePlus · Google Pixel
        │       ├─ OPPO/Realme · Sony Mobile · Sony TV
        │       ├─ Nintendo · PlayStation  │  Raspberry Pi
        │       └─ VMware · Hyper-V · VirtualBox · Cisco · TP-Link
        │
        ├─► Windows  (puertos SMB/RDP)
        │       ├─ Version: XP / 7 / 10 / 11 / Server 2012-2022
        │       ├─ Hostname via NetBIOS + DNS reverso
        │       ├─ Recursos SMB compartidos
        │       └─ Info de dominio AD (smb-os-discovery)
        │
        ├─► TTL = 128 sin puertos → Windows con firewall activo
        │       └─ Hostname via NetBIOS igualmente
        │
        └─► TTL = 64  →  Linux o Mac
                ├─ Mac  → AirPlay (5000) · AFP (548) · ARD (3283)
                ├─ iOS  → Puerto lockdown (62078)
                └─ Linux → Banner SSH revela distro:
                        Ubuntu · Debian · Kali · Parrot OS · Arch Linux
                        Fedora · CentOS/RHEL · Alpine · Manjaro · Mint · openSUSE
                        + Puertos vulnerables: FTP · Telnet · rpcbind · NFS
                          MySQL · PostgreSQL · MongoDB · Elasticsearch...
```

---

## Por que TTL primero para Windows

El error mas comun en scanners similares es clasificar un Windows como Linux o Mac cuando tiene el firewall activo y no responde por SMB/RDP. DANI-SCAN lo resuelve comprobando el TTL antes que los puertos: si el TTL es 128 es Windows aunque no abra ningun puerto. Solo si el TTL es 64 se buscan puertos de Mac o distros Linux.

---

## Ejemplo de salida

```
◈ 172.20.10.3  │  🖥️  Windows 10  (SMB)
│
├── MAC        : c8:15:4e:8c:50:b9
├── TTL        : 128
├── Método     : SMB
├── Hostname   : DESKTOP-DANIPC
├── SMB Info   : OS: Windows 10 Pro  Domain: WORKGROUP
└── Recursos   : \\172.20.10.3\IPC$

◈ 172.20.10.6  │  📺 Samsung SmartTV
│
├── Nombre     : 55" QLED
├── Modelo     : TQ55Q64DAUXXC
├── OS         : Tizen
├── Resolución : 3840x2160
├── Estado     : on
└── MAC        : 28:af:42:25:b3:78

◈ 172.20.10.1  │  📱 iPhone / iPad  (MAC aleatorizada)
│
├── Detalle    : Puerto lockdown iOS (62078)
├── TTL        : 64  (Linux/Mac)
└── MAC        : 32:d7:a1:76:d0:64  (aleatorizada)

◈ 172.20.10.4  │  🐧 Linux — Arch Linux
│
├── MAC        : a8:41:f4:2c:ca:1c
├── TTL        : 64
├── Detalle    : SSH banner
└── Hostname   : danimrtzp-pc
```

---

## Dependencias

El script las instala automaticamente. Si quieres instalarlas tu manualmente:

| Herramienta | Arch Linux | Kali / Parrot / Debian |
|---|---|---|
| `arp-scan` | `pacman -S arp-scan` | `apt install arp-scan` |
| `nmap` | `pacman -S nmap` | `apt install nmap` |
| `nmblookup` | `pacman -S samba` | `apt install samba-common-bin` |
| `curl` | `pacman -S curl` | `apt install curl` |

---

## Distros compatibles

| Distro | Soporte |
|---|:---:|
| Arch Linux | ✅ Completo |
| Kali Linux | ✅ Completo |
| Parrot OS | ✅ Completo |
| Debian / Ubuntu | ✅ Completo |
| Fedora / RHEL | ⚠️ Basico |

---

## Aviso legal

Solo para uso **educativo y en redes propias**. No lo uses en redes ajenas sin permiso. El autor no se responsabiliza del mal uso.

---

<div align="center">
  <sub>Made with 🖤 by <a href="https://github.com/danimrtzp">danimrtzp</a></sub>
</div>
