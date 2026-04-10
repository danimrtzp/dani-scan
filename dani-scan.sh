#!/bin/bash

# ═══════════════════════════════════════════════════════════════
#   DANI-SCAN - Network Scanner & OS Fingerprinting Tool
#   Author  : danimrtzp  |  Version : 7.0  |  License : MIT
#   Run     : sudo dani-scan
# ═══════════════════════════════════════════════════════════════

if [ "$EUID" -ne 0 ]; then
    echo -e "\n  [!] Requiere root. Ejecuta: sudo dani-scan\n"; exit 1
fi

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'
C='\033[0;36m'; M='\033[0;35m'; W='\033[1;37m'; DIM='\033[2m'
BOLD='\033[1m'; NC='\033[0m'; ORANGE='\033[0;33m'

# ─── AUTO-INSTALL ──────────────────────────────────────────────
SELF="$(realpath "${BASH_SOURCE[0]}")"
INSTALL_PATH="/usr/local/bin/dani-scan"
if [[ "$SELF" != "$INSTALL_PATH" ]]; then
    cp "$SELF" "$INSTALL_PATH" 2>/dev/null && chmod +x "$INSTALL_PATH" 2>/dev/null
fi

TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
OUTFILE="/tmp/dani-scan_${TIMESTAMP}.txt"

log(){
    echo -e "$1"
    echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$OUTFILE"
}

function ctrl_c(){
    echo -e "\n\n${R}[!]${NC} Saliendo...\n"
    echo "[!] Interrumpido" >> "$OUTFILE"
    tput cnorm; exit 1
}
trap ctrl_c INT
tput civis

clear
echo -e "${C}"
cat << 'EOF'
    ██████╗  █████╗ ███╗   ██╗██╗    ███████╗ ██████╗ █████╗ ███╗   ██╗
    ██╔══██╗██╔══██╗████╗  ██║██║    ██╔════╝██╔════╝██╔══██╗████╗  ██║
    ██║  ██║███████║██╔██╗ ██║██║    ███████╗██║     ███████║██╔██╗ ██║
    ██║  ██║██╔══██║██║╚██╗██║██║    ╚════██║██║     ██╔══██║██║╚██╗██║
    ██████╔╝██║  ██║██║ ╚████║██║    ███████║╚██████╗██║  ██║██║ ╚████║
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝
EOF
echo -e "${NC}"
echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${W}${BOLD}Network Scanner & OS Fingerprinting${NC}  ${DIM}│${NC}  ${M}by danimrtzp${NC}  ${DIM}│${NC}  ${DIM}v7.0${NC}"
echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "    ${DIM}[log] ${OUTFILE}${NC}\n"

{ echo "═══════════════════════════════════════════════════════════════"
  echo "  DANI-SCAN v7.0 - by danimrtzp  |  $(date '+%Y-%m-%d %H:%M:%S')"
  echo "═══════════════════════════════════════════════════════════════"; } >> "$OUTFILE"

# ─── DISTRO LOCAL ──────────────────────────────────────────────
detect_local_distro(){
    [ -f /etc/os-release ] && { . /etc/os-release; echo "$ID"; return; }
    command -v pacman &>/dev/null && echo "arch"   && return
    command -v apt    &>/dev/null && echo "debian" && return
    echo "unknown"
}
DISTRO=$(detect_local_distro)
case "$DISTRO" in
    arch|manjaro|endeavouros)   PKG_MANAGER="pacman";;
    kali|parrot|debian|ubuntu)  PKG_MANAGER="apt";;
    fedora|rhel|centos)         PKG_MANAGER="dnf";;
    *)                          PKG_MANAGER="unknown";;
esac

# ─── DEPENDENCIAS — AUTO-INSTALL ───────────────────────────────
echo -e "    ${C}[*]${NC} Comprobando dependencias...\n"
DEPS=("arp-scan" "nmap" "nmblookup" "curl" "ping")

pkg_name(){
    case "$PKG_MANAGER" in
        pacman) case "$1" in arp-scan) echo "arp-scan";; nmap) echo "nmap";;
            nmblookup) echo "samba";; curl) echo "curl";; ping) echo "iputils";; esac;;
        apt) case "$1" in arp-scan) echo "arp-scan";; nmap) echo "nmap";;
            nmblookup) echo "samba-common-bin";; curl) echo "curl";; ping) echo "iputils-ping";; esac;;
        *) echo "$1";;
    esac
}

for dep in "${DEPS[@]}"; do
    if command -v "$dep" &>/dev/null; then
        echo -e "    ${G}[✓]${NC} $dep"
    else
        echo -e "    ${Y}[~]${NC} $dep — instalando..."
        pkg=$(pkg_name "$dep")
        case "$PKG_MANAGER" in
            pacman) pacman -S --noconfirm "$pkg" &>/dev/null;;
            apt)    apt-get install -y "$pkg"    &>/dev/null;;
            dnf)    dnf install -y "$pkg"        &>/dev/null;;
            *) echo -e "    ${R}[!]${NC} Instala $dep manualmente."; tput cnorm; exit 1;;
        esac
        command -v "$dep" &>/dev/null \
            && echo -e "    ${G}[✓]${NC} $dep instalado" \
            || { echo -e "    ${R}[✗]${NC} Error instalando $dep."; tput cnorm; exit 1; }
    fi
done
echo ""
echo -e "    ${G}[✓]${NC} ${BOLD}Dependencias listas${NC}\n"
sleep 1

# ─── PEDIR DATOS ───────────────────────────────────────────────
echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${C}[?]${NC} ${BOLD}Interfaz de red${NC} ${DIM}(ej: wlp3s0, eth0, wlan0)${NC}"
echo -ne "    ${W}❯ ${NC}"; read -r INTERFAZ
echo ""
echo -e "    ${C}[?]${NC} ${BOLD}Red a escanear${NC} ${DIM}(ej: 192.168.1 / 172.20.10)${NC}"
echo -ne "    ${W}❯ ${NC}"; read -r RED_BASE
echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

{ echo ""; echo "Red: ${RED_BASE}.0/24  Interfaz: ${INTERFAZ}"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; } >> "$OUTFILE"

# ─── ARP-SCAN ──────────────────────────────────────────────────
echo -e "    ${B}[~]${NC} Ejecutando arp-scan en ${W}${RED_BASE}.0/24${NC}..."
ACTIVOS=$(arp-scan -I "$INTERFAZ" --localnet --bandwidth=256k --retry=2 2>/dev/null \
    | grep -E "^${RED_BASE}\.[0-9]+" | awk '{print $1"|"$2}')

if [ -z "$ACTIVOS" ]; then
    echo -e "\n    ${R}[!]${NC} Sin hosts. Comprueba la interfaz."
    tput cnorm; exit 1
fi
TOTAL=$(echo "$ACTIVOS" | wc -l)
echo -e "    ${G}[✓]${NC} ${BOLD}$TOTAL hosts detectados${NC}\n"
sleep 0.5

# ═══════════════════════════════════════════════════════════════
#   FUNCIONES DE DETECCION
# ═══════════════════════════════════════════════════════════════

# ─── TTL ───────────────────────────────────────────────────────
get_ttl(){
    local ttl=$(ping -c 1 -W 2 "$1" 2>/dev/null | grep -oP '(?i)ttl=\K[0-9]+' | head -1)
    [[ -z "$ttl" ]] && ttl=$(ping -c 1 -W 2 "$1" 2>/dev/null \
        | awk -F'ttl=' '{print $2}' | awk '{print $1}' | head -1)
    echo "$ttl"
}

ttl_to_os(){
    local ttl="$1"
    [[ -z "$ttl" || ! "$ttl" =~ ^[0-9]+$ ]] && echo "Desconocido" && return
    [ "$ttl" -le 64  ] && echo "Linux/Mac" && return
    [ "$ttl" -le 128 ] && echo "Windows"   && return
    echo "Desconocido"
}

# ─── MAC ALEATORIA ─────────────────────────────────────────────
is_random_mac(){
    local c2=$(echo "$1" | tr '[:lower:]' '[:upper:]' | cut -c2)
    case "$c2" in 2|6|A|E) return 0;; *) return 1;; esac
}

# ─── OUI DATABASE COMPLETA ─────────────────────────────────────
oui_lookup(){
    local mac=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    local oui=$(echo "$mac" | cut -c1-8)
    case "$oui" in
        "AC:BC:32"|"F0:18:98"|"3C:22:FB"|"A4:CF:99"|"F4:DB:E6"|"DC:2B:61"|\
        "A8:BE:27"|"F8:4D:89"|"18:65:90"|"BC:9F:EF"|"8C:85:90"|"70:3E:AC"|\
        "F0:D1:A9"|"CC:08:8D"|"14:7D:DA"|"60:F8:1D"|"AC:87:A3"|"04:52:F3"|\
        "90:B2:1F"|"34:C0:59"|"D0:03:4B"|"38:F9:D3"|"7C:D1:C3"|"A8:96:8A"|\
        "00:1B:63"|"00:1E:C2"|"00:1F:F3"|"00:21:E9"|"00:22:41"|"3C:07:54"|\
        "4C:8D:79"|"60:33:4B"|"D4:9A:20"|"E8:80:2E"|"F4:31:C3"|"00:CD:FE"|\
        "04:4B:ED"|"08:66:98"|"0C:4D:E9"|"10:9A:DD"|"14:98:77"|"18:AF:61"|\
        "1C:36:BB"|"20:78:F0"|"24:A2:E1"|"28:CF:DA"|"2C:BE:EB"|"30:10:B3"|\
        "34:36:3B"|"38:48:4C"|"3C:AB:8E"|"40:33:1A"|"44:2A:60"|"48:43:7C"|\
        "4C:57:CA"|"50:EE:D3"|"54:AE:27"|"58:55:CA"|"5C:8D:4E"|"60:C5:47"|\
        "64:9A:BE"|"68:D9:3C"|"6C:40:08"|"70:56:81"|"74:8F:3C"|"78:D7:52"|\
        "7C:04:D0"|"80:49:71"|"84:FC:FE"|"88:66:A5"|"8C:00:6D"|"90:60:F1"|\
        "94:E9:6A"|"98:9E:63"|"9C:F3:87"|"A0:99:9B"|"A4:D1:8C"|"A8:51:AB"|\
        "AC:29:3A"|"B0:65:BD"|"B4:F0:AB"|"B8:09:8A"|"BC:52:B7"|"C0:CE:CD"|\
        "C4:2C:03"|"C8:BC:C8"|"CC:44:63"|"D0:4F:7E"|"D4:F4:6F"|"D8:00:4D"|\
        "DC:37:14"|"E0:5F:45"|"E4:9A:79"|"E8:06:88"|"EC:35:86"|"F0:98:9D"|\
        "F4:5C:89"|"F8:95:EA"|"FC:25:3F")
            echo "Apple|Apple|🍎";;
        # Samsung Mobile
        "28:AF:42"|"8C:79:F0"|"78:BD:BC"|"F4:7B:5E"|"B0:C4:E7"|"A4:23:05"|\
        "50:01:BB"|"D0:22:BE"|"CC:07:AB"|"94:35:0A"|"BC:20:A4"|"FC:A1:3E"|\
        "40:0E:85"|"8C:71:F8"|"B4:EF:39"|"C8:14:79"|"E8:50:8B"|"14:A3:64"|\
        "00:26:37"|"30:19:66"|"34:23:BA"|"44:78:3E"|"50:32:37"|"5C:0A:5B"|\
        "60:6B:BD"|"64:77:91"|"6C:83:36"|"70:F9:27"|"74:45:8A"|"78:1F:DB"|\
        "7C:61:93"|"80:57:19"|"84:11:9E"|"84:25:DB"|"84:38:38"|"84:55:A5"|\
        "8C:C8:CD"|"90:18:7C"|"94:01:C2"|"94:63:D1"|"98:0C:82"|"9C:02:98"|\
        "A0:07:98"|"A0:0B:BA"|"A0:82:1F"|"A4:EB:D3"|"AC:5F:3E"|"B4:79:A7"|\
        "B8:5E:7B"|"BC:14:EF"|"BC:72:B1"|"BC:85:1F"|"C0:BD:D1"|"C4:42:02"|\
        "C8:19:F7"|"D0:59:E4"|"D0:C1:B1"|"D4:88:90"|"E4:40:E2"|"E4:58:B8"|\
        "E8:03:9A"|"E8:11:32"|"EC:1F:72"|"F0:5A:09"|"F0:72:8C"|"F4:42:8F"|\
        "F8:77:B8"|"FC:00:12"|"FC:F1:36")
            echo "Mobile|Samsung|📱";;
        # Samsung TV (OUIs especificos TV)
        "34:AA:8B"|"FC:03:9F"|"8C:77:12"|"CC:6E:A4"|"F8:04:2E"|"00:12:47"|\
        "00:17:C9"|"00:1F:CC"|"00:13:77"|"38:D4:0B"|"50:85:69"|"78:BD:BC"|\
        "7C:64:56"|"8C:E1:17"|"A4:11:62"|"D8:E0:E1"|"F4:9F:54")
            echo "TV|Samsung TV|📺";;
        # LG TV
        "00:1E:75"|"00:1F:6B"|"00:26:E2"|"20:55:31"|"A8:23:FE"|"CC:2D:8C"|\
        "D8:31:CF"|"E8:5B:5B"|"F8:0C:F3"|"FC:CD:2F"|"10:68:3F"|"14:C9:13"|\
        "18:47:3D"|"1C:08:C1"|"28:CF:E9"|"2C:54:CF"|"34:4D:F7"|"38:8C:50"|\
        "3C:BD:3E"|"40:40:A7"|"4C:BB:58"|"50:55:27"|"54:35:30"|"58:A2:B5"|\
        "5C:62:8B"|"60:E3:2B"|"64:B8:53"|"6C:40:08"|"70:4F:57"|"74:E6:B8"|\
        "78:A8:73"|"7C:2F:80"|"80:6C:1B"|"84:B5:41"|"88:C9:D0"|"90:61:0C"|\
        "94:4A:0C"|"98:D6:BB"|"9C:3A:AF"|"A0:39:F7"|"A4:70:D6"|"B0:39:56"|\
        "B4:0F:3B"|"B8:E8:56"|"BC:F5:AC"|"C0:97:27"|"C4:36:6C"|"C8:02:8F"|\
        "CC:FA:00"|"D4:39:6E"|"DC:1A:C5"|"E4:A7:C5"|"E8:F2:E2"|"EC:88:92"|\
        "F0:6D:78"|"F4:6A:92"|"F8:95:C7"|"FC:26:05"|"40:B0:FA"|"48:59:29"|\
        "58:FB:84"|"64:99:5D"|"78:5D:C8"|"88:36:6C")
            echo "TV|LG TV|📺";;
        # LG Mobile
        "AC:F1:DF"|"D0:13:FD")
            echo "Mobile|LG|📱";;
        # Xiaomi
        "0C:1D:AF"|"28:6C:07"|"34:80:B3"|"50:64:2B"|"64:09:80"|"74:51:BA"|\
        "AC:C1:EE"|"F4:8B:32"|"FC:64:BA"|"D4:97:0B"|"A4:50:46"|"00:9E:C8"|\
        "10:2A:B3"|"18:59:36"|"20:82:C0"|"24:CF:24"|"28:E3:1F"|"2C:95:69"|\
        "34:CE:94"|"38:A4:ED"|"3C:BD:D8"|"40:31:3C"|"44:A1:60"|"48:13:7E"|\
        "4C:49:E3"|"50:8F:4C"|"54:A0:50"|"58:44:98"|"5C:E8:EB"|"60:AB:67"|\
        "64:B4:73"|"68:DF:DD"|"6C:5C:14"|"70:47:E9"|"74:23:44"|"78:11:DC"|\
        "7C:1D:D9"|"80:35:C1"|"84:16:F9"|"88:63:DF"|"8C:BE:BE"|"90:C6:82"|\
        "94:04:F2"|"98:FA:E3"|"9C:99:A0"|"A0:86:C6"|"A4:C3:F0"|"A8:9F:BA"|\
        "B0:E2:35"|"B4:A2:EB"|"B8:2C:A8"|"BC:29:11"|"C0:1A:DA"|"C4:6A:B7"|\
        "C8:47:8C"|"CC:2D:E0"|"D0:C0:BF"|"D4:F5:27"|"D8:A3:5C"|"DC:44:27"|\
        "E0:55:3D"|"E4:46:DA"|"E8:AB:FA"|"EC:D0:9F"|"F0:B4:29"|"F8:A2:D6")
            echo "Mobile|Xiaomi|📱";;
        # Motorola
        "00:17:A4"|"00:1A:1E"|"00:1C:9E"|"00:1E:EC"|"00:21:6B"|"00:22:A4"|\
        "00:23:68"|"00:24:1D"|"00:24:E8"|"00:25:D3"|"00:26:CB"|"04:CF:8C"|\
        "0C:47:C9"|"10:68:C6"|"14:9A:05"|"18:86:AC"|"1C:B7:2C"|"20:02:AF"|\
        "24:01:C7"|"28:C6:8E"|"2C:BE:08"|"30:CB:F8"|"34:BB:26"|"38:17:C3"|\
        "3C:CB:7C"|"40:78:25"|"44:80:EB"|"48:A4:72"|"4C:68:C7"|"50:2C:C8"|\
        "54:A5:1B"|"58:A6:F7"|"5C:51:4F"|"60:DF:A2"|"64:CC:2E"|"68:F0:28"|\
        "6C:D7:1F"|"70:F1:A1"|"74:7A:E6"|"78:A5:04"|"7C:2E:BD"|"80:BE:AF"|\
        "84:10:0D"|"84:A4:66"|"88:3D:24"|"8C:DE:52"|"90:68:C3"|"94:D7:23"|\
        "98:0D:2E"|"9C:4E:36"|"A0:7D:60"|"A4:34:F1"|"A8:26:D9"|"AC:3A:7A"|\
        "B0:35:9F"|"B4:B6:86"|"B8:1D:AA"|"BC:16:65"|"C0:B5:D7"|"C4:6E:1F"|\
        "C8:7E:75"|"CC:31:AE"|"D0:1D:BC"|"D4:50:3F"|"D8:3B:BF"|"DC:44:6D"|\
        "E0:75:0A"|"E4:2C:56"|"E8:DF:70"|"EC:07:26"|"F0:27:45"|"F4:55:95"|\
        "F8:7E:FC"|"FC:3F:DB")
            echo "Mobile|Motorola|📱";;
        # OnePlus
        "04:4F:4C"|"94:65:2D"|"C0:EE:FB"|"10:3B:59"|"18:26:49"|"1C:77:F6"|\
        "2C:16:DB"|"38:78:62"|"48:8A:D2"|"4C:BC:98"|"60:21:C0"|"64:A0:E7"|\
        "6C:0B:84"|"70:5C:AF"|"74:4C:A1"|"7C:9E:BD"|"80:4C:58"|"84:C2:E4"|\
        "88:32:9B"|"8C:47:6E"|"90:7A:58"|"94:87:E0"|"98:CB:3C"|"9C:8E:CD"|\
        "A4:C0:E1"|"A8:6B:AD"|"B4:69:21"|"C0:25:A5"|"C4:B3:01"|"C8:F7:50"|\
        "D0:6F:82"|"D4:6A:35"|"DC:1B:A1"|"E0:4F:43"|"E4:D5:3D"|"E8:C0:4F"|\
        "EC:55:F9")
            echo "Mobile|OnePlus|📱";;
        # Huawei
        "04:BD:70"|"28:31:52"|"40:4E:36"|"48:46:FB"|"54:89:98"|"70:72:3C"|\
        "A0:08:6F"|"BC:25:E0"|"CC:96:A0"|"E8:08:8B"|"00:18:82"|"00:1E:10"|\
        "00:25:68"|"00:34:FE"|"00:9A:CD"|"04:02:1F"|"04:75:03"|"08:19:A6"|\
        "08:7A:4C"|"08:C0:84"|"0C:37:DC"|"0C:96:BF"|"10:1B:54"|"10:47:80"|\
        "10:C6:1F"|"14:B9:68"|"18:B4:30"|"1C:1D:67"|"1C:67:58"|"20:08:ED"|\
        "20:2B:C1"|"24:09:95"|"24:7F:3C"|"24:DA:9B"|"28:3C:E4"|"28:6E:D4"|\
        "28:A1:83"|"2C:AB:00"|"30:45:96"|"34:6B:D3"|"34:A8:4E"|"38:37:8B"|\
        "38:BC:1A"|"3C:47:11"|"3C:D5:8C"|"40:CB:A8"|"44:C3:46"|"48:DB:50"|\
        "4C:1F:CC"|"4C:54:99"|"50:9F:27"|"54:25:EA"|"54:51:1B"|"58:60:5F"|\
        "5C:8D:4E"|"60:19:29"|"60:DE:44"|"64:16:F0"|"68:13:24"|"6C:8D:C1"|\
        "70:54:D2"|"74:A5:28"|"78:1D:BA"|"78:D7:52"|"7C:60:97"|"80:D0:9B"|\
        "84:5B:12"|"84:AD:58"|"88:4A:F7"|"88:E3:AB"|"8C:34:FD"|"90:17:AC"|\
        "90:67:1C"|"94:04:9C"|"94:DB:DA"|"98:52:B1"|"9C:28:EF"|"A0:D0:60"|\
        "A4:A1:C2"|"A8:CA:7B"|"AC:4E:91"|"B0:A7:37"|"B4:15:13"|"B8:08:D7"|\
        "BC:3E:E4"|"C0:70:CF"|"C4:07:2F"|"C8:14:51"|"C8:51:95"|"CC:A2:23"|\
        "D0:D0:4B"|"D4:6A:A8"|"D8:49:0B"|"DC:D2:FC"|"E0:19:54"|"E4:A8:DF"|\
        "E8:CD:2D"|"EC:23:3D"|"F0:7D:68"|"F4:4C:7F"|"F8:3D:FF"|"FC:48:EF"|\
        "FC:87:43")
            echo "Mobile|Huawei|📱";;
        # Google Pixel
        "08:9E:08"|"1C:F2:9A"|"3C:5A:B4"|"54:60:09"|"6C:AD:F8"|\
        "A4:77:33"|"F4:F5:E8"|"20:DF:B9"|"2C:DF:86"|"34:E1:2D"|\
        "48:B0:2D"|"58:CB:52"|"60:BE:B5"|"70:15:84"|"78:F8:82"|\
        "9A:9A:8E"|"D0:27:88"|"E0:C7:67"|"E4:4E:2D"|"E8:D0:55"|\
        "F4:60:E2")
            echo "Mobile|Google Pixel|📱";;
        # OPPO / Realme
        "00:1A:11"|"04:D4:C4"|"08:F8:BC"|"0C:7F:ED"|"10:4A:D6"|\
        "14:56:18"|"18:51:CF"|"20:19:07"|"28:5F:DB"|"2C:77:D3"|\
        "30:6C:5A"|"34:4B:F2"|"38:A5:1C"|"40:8D:5C"|"44:D4:E0"|\
        "48:A4:93"|"50:FF:20"|"54:AB:3A"|"58:B0:D2"|"5C:97:F3"|\
        "60:A4:D0"|"64:37:E8"|"68:1C:A2"|"6C:B0:CE"|"70:C0:71"|\
        "74:EB:80"|"78:C2:C0"|"7C:91:22"|"80:7A:BF"|"84:54:DF"|\
        "88:44:77"|"8C:7A:AA"|"90:0D:CB"|"94:87:E0"|"9C:5C:F9"|\
        "A0:AF:BD"|"A4:6C:F1"|"A8:9F:EC"|"AC:2B:6E"|"B0:92:48"|\
        "B4:C4:FC"|"B8:86:87"|"BC:5A:56"|"C0:25:A5"|"C4:AC:60"|\
        "C8:40:81"|"CC:FB:65"|"D0:9C:7A"|"D4:12:BB"|"D8:80:83"|\
        "DC:6D:CD"|"E0:0A:F6"|"E4:8F:34"|"E8:B4:C8"|"EC:DF:3A"|\
        "F0:AE:05"|"F4:3E:61"|"F8:28:19"|"FC:4B:BC")
            echo "Mobile|OPPO/Realme|📱";;
        # Sony Mobile
        "00:01:4A"|"00:13:A9"|"1C:98:C1"|"20:0C:C8"|"24:91:FF"|\
        "28:DD:A4"|"34:C7:31"|"38:2D:E8"|"3C:01:EF"|"44:39:C4"|\
        "48:42:4B"|"4C:74:BF"|"54:42:49"|"58:17:0C"|"5C:96:9D"|\
        "60:F4:45"|"68:86:A7"|"6C:5A:B0"|"74:C2:46"|"78:84:3C"|\
        "7C:6D:62"|"84:7A:88"|"88:07:4B"|"8C:64:22"|"90:C1:15"|\
        "94:CE:2C"|"98:48:27"|"9C:AD:97"|"A0:CE:C8"|"A4:90:05"|\
        "A8:78:17"|"AC:9B:0A"|"B0:05:94"|"B4:52:7E"|"B8:7A:2E"|\
        "BC:30:D9"|"C4:9D:ED"|"C8:AD:04"|"CC:70:ED"|"D4:AE:52"|\
        "D8:45:00"|"DC:0B:34"|"E0:AE:5E"|"E4:22:A5"|"E8:76:35"|\
        "EC:BE:F5"|"F0:BF:97"|"F4:FA:77"|"F8:62:AA"|"FC:0F:E6")
            echo "Mobile|Sony|📱";;
        # Sony TV
        "00:24:BE"|"00:25:E7"|"04:CF:8C"|"18:00:2D"|"30:17:C8"|\
        "40:23:43"|"70:26:05"|"80:19:34"|"C0:28:8D"|"E0:AE:5E")
            echo "TV|Sony TV|📺";;
        # Nintendo
        "00:09:BF"|"00:16:56"|"00:17:AB"|"00:19:1D"|"00:1A:E9"|\
        "00:1B:EA"|"00:1C:BE"|"00:1D:BC"|"00:1E:35"|"00:1F:32"|\
        "00:21:47"|"00:22:4C"|"00:23:CC"|"00:24:F3"|"00:25:A0"|\
        "00:26:59"|"2C:10:C1"|"40:D2:8A"|"58:2F:40"|"64:B5:C6"|\
        "7C:BB:8A"|"8C:56:C5"|"A4:5C:27"|"B8:AE:6E"|"CC:9E:00"|\
        "E0:E7:51"|"E8:4E:CE"|"F4:98:44")
            echo "Gaming|Nintendo|🎮";;
        # PlayStation
        "00:04:1F"|"00:15:C1"|"00:19:C5"|"00:1D:0D"|"00:24:8D"|\
        "28:37:37"|"38:D5:47"|"70:9E:29"|"A8:E3:EE"|"BC:60:A7"|\
        "F8:46:1C"|"00:04:1F"|"FC:0F:E6")
            echo "Gaming|PlayStation|🎮";;
        # Raspberry Pi
        "B8:27:EB"|"DC:A6:32"|"E4:5F:01"|"28:CD:C1"|"D8:3A:DD")
            echo "IoT|Raspberry Pi|🍓";;
        # VMware / VirtualBox / Hyper-V
        "00:50:56"|"00:0C:29"|"00:05:69") echo "VM|VMware|💻";;
        "00:15:5D")                        echo "VM|Hyper-V|💻";;
        "08:00:27")                        echo "VM|VirtualBox|💻";;
        # Cisco
        "00:00:0C"|"00:01:42"|"00:01:96"|"00:02:16"|"00:03:6B"|\
        "00:04:27"|"00:05:00"|"00:05:31"|"00:06:7C"|"00:07:0D"|\
        "00:08:20"|"00:08:A3"|"00:09:12"|"00:0A:8A"|"00:0B:45"|\
        "00:0C:85"|"00:0D:28"|"00:0E:38"|"00:0F:8F"|"00:10:2F"|\
        "00:11:5C"|"00:12:17"|"00:13:19"|"00:14:1B"|"00:15:2B"|\
        "00:16:46"|"00:17:59"|"00:18:73"|"00:19:07"|"00:1A:2F"|\
        "00:1B:0D"|"00:1C:57"|"00:1D:71"|"00:1E:BD"|"00:1F:CA"|\
        "00:21:55"|"00:22:55"|"00:23:04"|"00:24:14"|"00:25:45"|\
        "00:26:CB"|"58:AC:78"|"68:EF:BD"|"70:81:05"|"84:B8:02"|\
        "A0:CF:5B"|"B4:A4:E3"|"C8:9C:1D"|"D0:C7:89"|"E4:C7:22"|\
        "F0:7F:06")
            echo "Network|Cisco|🔌";;
        # TP-Link
        "00:1D:0F"|"00:23:CD"|"08:57:00"|"10:FE:ED"|"14:CC:20"|\
        "1C:69:7A"|"20:76:93"|"24:69:A5"|"2C:59:8A"|"30:B4:9E"|\
        "34:CE:00"|"38:94:96"|"40:16:9F"|"40:ED:98"|"44:94:FC"|\
        "48:8D:36"|"4C:E6:76"|"50:3E:AA"|"54:E6:FC"|"5C:89:9A"|\
        "60:32:B1"|"64:70:02"|"68:A0:F6"|"6C:B0:CE"|"70:4F:57"|\
        "74:DA:38"|"78:8C:54"|"7C:8B:CA"|"80:35:C1"|"84:16:F9"|\
        "88:25:2C"|"8C:21:0A"|"90:F6:52"|"94:0C:6D"|"98:DE:D0"|\
        "9C:A6:15"|"A0:F3:C1"|"A4:2B:B0"|"A8:57:4E"|"AC:84:C6"|\
        "B0:48:7A"|"B4:B0:24"|"B8:69:F4"|"BC:46:99"|"C0:4A:00"|\
        "C4:6E:1F"|"C8:D3:A3"|"CC:32:E5"|"D0:37:45"|"D4:6E:5C"|\
        "D8:0D:17"|"DC:EF:CA"|"E0:05:C5"|"E4:C1:46"|"E8:94:F6"|\
        "EC:17:2F"|"F0:A7:31"|"F4:EC:38"|"F8:1A:67"|"FC:D7:33")
            echo "Router|TP-Link|🔌";;
        # Generico router
        "00:50:7F"|"18:A6:F7"|"2C:30:33"|"A8:40:41"|"C8:3A:35"|\
        "E4:8D:8C"|"00:26:B9"|"FC:EC:DA"|"C8:BE:19"|"48:EE:0C"|\
        "00:E0:4C"|"00:11:32"|"00:90:27"|"00:1A:2B")
            echo "Router|Router|🔌";;
        *) echo "Unknown|Desconocido|❓";;
    esac
}

# ─── HOSTNAME: NetBIOS + DNS siempre ───────────────────────────
get_hostname(){
    local ip="$1"
    local nb=$(nmblookup -A "$ip" 2>/dev/null \
        | grep "<00>" | grep -v "GROUP" | head -1 \
        | awk '{print $1}' | tr -d '[:space:]')
    [ -n "$nb" ] && echo "$nb" && return 0
    local dns=$(nmap -sn -Pn --host-timeout 5s "$ip" 2>/dev/null \
        | grep "Nmap scan report" | grep -oP '\(\K[^)]+')
    [ -n "$dns" ] && echo "$dns" && return 0
    return 1
}

get_mdns(){
    command -v avahi-resolve &>/dev/null || return 1
    local n=$(avahi-resolve -a "$1" 2>/dev/null | awk '{print $2}')
    [ -n "$n" ] && echo "$n" && return 0; return 1
}

# ─── SAMSUNG TV API ────────────────────────────────────────────
detect_samsung_tv(){
    local resp=$(curl -s --connect-timeout 2 "http://${1}:8001/api/v2/" 2>/dev/null)
    echo "$resp" | grep -q '"type":"Samsung SmartTV"' || return 1
    local name=$(echo  "$resp" | grep -oP '"name":"\K[^"]+'       | head -1 | sed 's/&quot;/"/g')
    local model=$(echo "$resp" | grep -oP '"modelName":"\K[^"]+'  | head -1)
    local os=$(echo    "$resp" | grep -oP '"OS":"\K[^"]+'         | head -1)
    local res=$(echo   "$resp" | grep -oP '"resolution":"\K[^"]+' | head -1)
    local pwr=$(echo   "$resp" | grep -oP '"PowerState":"\K[^"]+' | head -1)
    echo "${name}|${model}|${os}|${res}|${pwr}"
}

# ─── LG TV API ─────────────────────────────────────────────────
detect_lg_tv(){
    local ip="$1"
    local resp=$(curl -s --connect-timeout 2 "http://${ip}:3000" 2>/dev/null)
    echo "$resp" | grep -qi "webos\|lge\|lg electronics" || return 1
    local model=$(curl -s --connect-timeout 2 "http://${ip}:1925/1/system/info" 2>/dev/null \
        | grep -oP '"modelName"\s*:\s*"\K[^"]+' | head -1)
    echo "${model}"
}

# ─── UPNP/DLNA ─────────────────────────────────────────────────
detect_upnp(){
    local ip="$1"
    for port in 9197 9098 1400 49152 49153 8080 3000 1925; do
        local resp=$(curl -s --connect-timeout 1 "http://${ip}:${port}/dmr" 2>/dev/null)
        [ -z "$resp" ] && resp=$(curl -s --connect-timeout 1 \
            "http://${ip}:${port}/description.xml" 2>/dev/null)
        echo "$resp" | grep -q "deviceType" || continue
        local dtype=$(echo "$resp" | grep -oP '(?<=<deviceType>)[^<]+'   | head -1)
        local fname=$(echo "$resp" | grep -oP '(?<=<friendlyName>)[^<]+' | head -1 \
            | sed 's/&quot;/"/g')
        local maker=$(echo "$resp" | grep -oP '(?<=<manufacturer>)[^<]+' | head -1)
        local model=$(echo "$resp" | grep -oP '(?<=<modelName>)[^<]+'    | head -1)
        local tipo="Dispositivo"
        echo "$dtype" | grep -qi "MediaRenderer\|TV\|Display" && tipo="SmartTV"
        echo "$dtype" | grep -qi "MediaServer"                 && tipo="Media Server"
        echo "$dtype" | grep -qi "WLANAccessPoint\|Gateway"    && tipo="Router"
        echo "$dtype" | grep -qi "Printer"                     && tipo="Impresora"
        echo "${tipo}|${fname}|${maker}|${model}"; return 0
    done
    return 1
}

# ─── DETECTAR WINDOWS ──────────────────────────────────────────
# Devuelve vacío si no es Windows
detect_windows(){
    local ip="$1"
    local result=$(nmap -Pn --open \
        -p 135,137,139,445,3389,5985,5986 \
        --host-timeout 15s -T3 "$ip" 2>/dev/null)

    if echo "$result" | grep -qE "135/tcp|139/tcp|445/tcp"; then
        local ver=$(nmap -Pn -p 445 -sV --host-timeout 10s -T3 "$ip" 2>/dev/null \
            | grep "445/tcp")
        if   echo "$ver" | grep -qi "windows server 2022"; then echo "🖥️  Windows Server 2022|SMB"
        elif echo "$ver" | grep -qi "windows server 2019"; then echo "🖥️  Windows Server 2019|SMB"
        elif echo "$ver" | grep -qi "windows server 2016"; then echo "🖥️  Windows Server 2016|SMB"
        elif echo "$ver" | grep -qi "windows server 2012"; then echo "🖥️  Windows Server 2012|SMB"
        elif echo "$ver" | grep -qi "windows 11";          then echo "🖥️  Windows 11|SMB"
        elif echo "$ver" | grep -qi "windows 10";          then echo "🖥️  Windows 10|SMB"
        elif echo "$ver" | grep -qi "windows 7";           then echo "🖥️  Windows 7|SMB"
        elif echo "$ver" | grep -qi "windows xp";          then echo "🖥️  Windows XP|SMB ⚠️  VULNERABLE"
        elif echo "$ver" | grep -qi "windows";             then echo "🖥️  Windows|SMB"
        else echo "🖥️  Windows|SMB activo"; fi
        return 0
    fi
    echo "$result" | grep -q  "3389/tcp"           && echo "🖥️  Windows|RDP"   && return 0
    echo "$result" | grep -qE "5985/tcp|5986/tcp"  && echo "🖥️  Windows|WinRM" && return 0
    return 1
}

# ─── INFO EXTRA WINDOWS ────────────────────────────────────────
get_windows_info(){
    local ip="$1"
    local smb=$(nmap -Pn -p 445 \
        --script smb-os-discovery,smb-security-mode \
        --host-timeout 15s -T3 "$ip" 2>/dev/null \
        | grep -E "OS:|Computer name:|Domain:|message_signing" \
        | sed 's/|//g;s/  */ /g' | tr '\n' ' ')
    local shares=$(nmap -Pn -p 445 --script smb-enum-shares \
        --host-timeout 15s -T3 "$ip" 2>/dev/null \
        | grep -oP '\\\\[^\\]+\\[^\s]+' | tr '\n' ' ')
    echo "${smb}|||${shares}"
}

# ─── DETECTAR MAC vs LINUX ─────────────────────────────────────
# IMPORTANTE: Esta función SOLO se llama cuando el TTL ya dice Linux/Mac (<=64)
# Si TTL es 128 → Windows aunque no tenga puertos abiertos (firewall)
detect_linux_or_mac(){
    local ip="$1"
    local result=$(nmap -Pn --open \
        -p 22,80,443,548,5000,5001,7000,88,3283,62078,5900,8080,4444,5901,3000,8888,9090 \
        --host-timeout 15s -T3 "$ip" 2>/dev/null)

    # iOS — lockdown
    echo "$result" | grep -q "62078/tcp" \
        && echo "📱 iPhone / iPad|Puerto lockdown iOS (62078)" && return 0

    # macOS — AirPlay/AFP/ARD (puertos EXCLUSIVOS de Mac)
    if echo "$result" | grep -qE "5000/tcp|7000/tcp|548/tcp|3283/tcp"; then
        echo "🍎 Mac (macOS)|AirPlay/AFP/ARD detectado"; return 0
    fi

    # SSH — banner para distro exacta
    if echo "$result" | grep -q "22/tcp open"; then
        local banner=$(nmap -Pn -p 22 -sV --host-timeout 12s -T3 "$ip" 2>/dev/null \
            | grep "22/tcp")
        echo "$banner" | grep -qi "ubuntu"            && echo "🐧 Linux — Ubuntu|SSH banner"        && return 0
        echo "$banner" | grep -qi "debian"            && echo "🐧 Linux — Debian|SSH banner"        && return 0
        echo "$banner" | grep -qi "kali"              && echo "🐧 Linux — Kali Linux|SSH banner"    && return 0
        echo "$banner" | grep -qi "parrot"            && echo "🐧 Linux — Parrot OS|SSH banner"     && return 0
        echo "$banner" | grep -qi "fedora"            && echo "🐧 Linux — Fedora|SSH banner"        && return 0
        echo "$banner" | grep -qi "centos\|rhel"      && echo "🐧 Linux — CentOS/RHEL|SSH banner"   && return 0
        echo "$banner" | grep -qi "arch"              && echo "🐧 Linux — Arch Linux|SSH banner"    && return 0
        echo "$banner" | grep -qi "raspbian\|raspber" && echo "🐧 Linux — Raspberry Pi|SSH banner"  && return 0
        echo "$banner" | grep -qi "alpine"            && echo "🐧 Linux — Alpine|SSH banner"        && return 0
        echo "$banner" | grep -qi "manjaro"           && echo "🐧 Linux — Manjaro|SSH banner"       && return 0
        echo "$banner" | grep -qi "mint"              && echo "🐧 Linux — Linux Mint|SSH banner"    && return 0
        echo "$banner" | grep -qi "opensuse"          && echo "🐧 Linux — openSUSE|SSH banner"      && return 0
        echo "$banner" | grep -qi "openssh"           && echo "🐧 Linux (SSH)|Sin distro en banner" && return 0
        echo "🐧 Linux / 🍎 Mac|SSH abierto"; return 0
    fi

    echo "$result" | grep -q  "5900/tcp"                && echo "🐧 Linux (VNC)|Escritorio remoto"       && return 0
    echo "$result" | grep -q  "4444/tcp"                && echo "🐧 Linux — Kali|Puerto Metasploit"      && return 0
    echo "$result" | grep -q  "3000/tcp"                && echo "🐧 Linux (web app)|Puerto 3000"         && return 0
    echo "$result" | grep -q  "8888/tcp"                && echo "🐧 Linux — Jupyter|Puerto Jupyter"      && return 0
    echo "$result" | grep -qE "80/tcp|443/tcp|8080/tcp" && echo "🐧 Linux (servidor web)|HTTP/HTTPS"     && return 0

    echo "🐧 Linux / 🍎 Mac|Sin puertos abiertos"; return 1
}

# ─── PUERTOS VULNERABLES LINUX ─────────────────────────────────
get_linux_vulnports(){
    local vuln=$(nmap -Pn --open \
        -p 21,23,25,53,79,110,111,143,512,513,514,1099,1524,2049,2121,3306,4444,5432,6000,8180,9200,27017 \
        --host-timeout 12s -T3 "$1" 2>/dev/null \
        | grep "open" | awk '{print $1}' | tr '\n' ' ')
    echo "$vuln"
}

# ─── FINGERPRINT MAC ALEATORIA ─────────────────────────────────
# TTL PRIMERO, luego puertos
fingerprint_random_mac(){
    local ip="$1"
    local ttl="$2"
    local os_ttl="$3"

    # Si TTL dice Windows → es Windows (aunque no tenga puertos abiertos)
    if [ "$os_ttl" = "Windows" ]; then
        # Confirmar con puertos
        local win=$(detect_windows "$ip")
        if [ -n "$win" ]; then
            echo "$win"; return 0
        fi
        echo "🖥️  Windows|TTL=$ttl (firewall bloquea puertos)"; return 0
    fi

    # TTL dice Linux/Mac → buscar por puertos
    local result=$(nmap -Pn --open \
        -p 22,62078,80,135,139,389,443,445,548,636,3283,3389,5000,5985,7000,8080,8443 \
        --host-timeout 15s -T3 "$ip" 2>/dev/null)

    echo "$result" | grep -q  "62078/tcp"                           && echo "📱 iPhone / iPad|Puerto lockdown iOS"    && return 0
    echo "$result" | grep -qE "5000/tcp|7000/tcp|3283/tcp|548/tcp"  && echo "🍎 Mac (macOS)|AirPlay/AFP"             && return 0
    echo "$result" | grep -qE "389/tcp|636/tcp"                     && echo "🏢 Windows — Active Directory|LDAP"     && return 0
    echo "$result" | grep -qE "135/tcp|445/tcp|3389/tcp|5985/tcp"   && echo "🖥️  Windows|SMB/RDP/WinRM"             && return 0
    echo "$result" | grep -q  "22/tcp open"                         && echo "🐧 Linux|SSH abierto"                   && return 0
    echo "$result" | grep -qE "80/tcp|443/tcp|8080/tcp|8443/tcp"    && echo "🌐 Dispositivo|HTTP/HTTPS"              && return 0
    echo "❓ Desconocido|Sin puertos identificativos"; return 1
}

# ─── NMAP COMPLETO ─────────────────────────────────────────────
run_full_nmap(){
    local ip="$1"
    local nmap_file="/tmp/nmap_${ip//\./_}_${TIMESTAMP}.txt"
    echo -e "\n    ${C}[~]${NC} Escaneando ${W}$ip${NC}...\n"
    echo "══ NMAP: $ip ══" >> "$OUTFILE"
    nmap -p- --open -sS -sC -sV --min-rate 2000 -n -vvv -Pn "$ip" \
        | tee "$nmap_file" | tee -a "$OUTFILE"
    echo "" >> "$OUTFILE"
    # Mover al destino final cuando se elija
    NMAP_FILES+=("$nmap_file:$ip")
    echo -e "\n    ${G}[✓]${NC} Guardado temporalmente en ${W}$nmap_file${NC}\n"
}

# ═══════════════════════════════════════════════════════════════
#   ESCANEO PRINCIPAL
# ═══════════════════════════════════════════════════════════════
log "\n    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
log "    ${W}${BOLD}RESULTADOS${NC}"
log "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

COUNT=0
HOSTS_ENCONTRADOS=()
NMAP_FILES=()

for i in $(seq 1 254); do
    ip="${RED_BASE}.${i}"
    entrada=$(echo "$ACTIVOS" | grep "^${ip}|")
    [ -z "$entrada" ] && continue

    mac=$(echo "$entrada" | cut -d'|' -f2)
    COUNT=$((COUNT+1))
    HOSTS_ENCONTRADOS+=("$ip")
    sleep $(( (RANDOM % 3) + 2 ))

    IFS='|' read -r oui_tipo oui_fab oui_emoji <<< "$(oui_lookup $mac)"
    mac_aleatoria=false
    is_random_mac "$mac" && mac_aleatoria=true

    # ── Datos base siempre ────────────────────────────────────
    ttl=$(get_ttl "$ip")
    os_ttl=$(ttl_to_os "$ttl")
    responde_icmp=false
    ping -c 1 -W 2 "$ip" &>/dev/null && responde_icmp=true
    hostname=$(get_hostname "$ip")
    mdns=$(get_mdns "$ip")

    # ════════════════════════════════════════════════════════════
    # SAMSUNG SMARTTV
    # ════════════════════════════════════════════════════════════
    samsung=$(detect_samsung_tv "$ip")
    if [ $? -eq 0 ]; then
        IFS='|' read -r tv_name tv_model tv_os tv_res tv_pwr <<< "$samsung"
        log "    ${M}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${M}📺 Samsung SmartTV${NC}"
        log "    ${DIM}│${NC}"
        log "    ${DIM}├──${NC} Nombre     : ${W}$tv_name${NC}"
        log "    ${DIM}├──${NC} Modelo     : ${Y}$tv_model${NC}"
        log "    ${DIM}├──${NC} OS         : ${Y}$tv_os${NC}"
        log "    ${DIM}├──${NC} Resolución : $tv_res"
        log "    ${DIM}├──${NC} Estado     : $tv_pwr"
        [ -n "$hostname" ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        log "    ${DIM}└──${NC} MAC        : ${DIM}$mac${NC}"
        log ""; continue
    fi

    # ════════════════════════════════════════════════════════════
    # LG SMARTTV
    # ════════════════════════════════════════════════════════════
    lg_model=$(detect_lg_tv "$ip")
    if [ $? -eq 0 ]; then
        log "    ${M}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${M}📺 LG SmartTV${NC}"
        log "    ${DIM}│${NC}"
        log "    ${DIM}├──${NC} OS         : ${Y}WebOS${NC}"
        [ -n "$lg_model" ] && log "    ${DIM}├──${NC} Modelo     : $lg_model"
        [ -n "$hostname" ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        log "    ${DIM}└──${NC} MAC        : ${DIM}$mac${NC}"
        log ""; continue
    fi

    # ════════════════════════════════════════════════════════════
    # UPNP / DLNA
    # ════════════════════════════════════════════════════════════
    upnp=$(detect_upnp "$ip")
    if [ $? -eq 0 ]; then
        IFS='|' read -r u_tipo u_name u_maker u_model <<< "$upnp"
        log "    ${B}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${B}📡 UPnP — $u_tipo${NC}"
        log "    ${DIM}│${NC}"
        log "    ${DIM}├──${NC} Nombre     : $u_name"
        log "    ${DIM}├──${NC} Fabricante : ${Y}$u_maker${NC}"
        log "    ${DIM}├──${NC} Modelo     : $u_model"
        [ -n "$ttl"      ] && log "    ${DIM}├──${NC} OS (TTL)   : ${Y}$os_ttl${NC}  ${DIM}[TTL $ttl]${NC}"
        [ -n "$hostname" ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        [ -n "$mdns"     ] && log "    ${DIM}├──${NC} mDNS       : ${Y}$mdns${NC}"
        log "    ${DIM}└──${NC} MAC        : ${DIM}$mac${NC}"
        log ""; continue
    fi

    # ════════════════════════════════════════════════════════════
    # MAC ALEATORIA
    # TTL primero, luego puertos — evita falsos Mac/Linux en Windows
    # ════════════════════════════════════════════════════════════
    if $mac_aleatoria; then
        IFS='|' read -r dev_tipo dev_detalle <<< "$(fingerprint_random_mac $ip $ttl $os_ttl)"
        COLOR="${C}"
        [[ "$dev_tipo" == *"Windows"* ]] && COLOR="${R}"
        [[ "$dev_tipo" == *"Linux"*   ]] && COLOR="${G}"
        [[ "$dev_tipo" == *"Mac"*     ]] && COLOR="${G}"
        [[ "$dev_tipo" == *"iPhone"*  ]] && COLOR="${C}"

        log "    ${COLOR}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${COLOR}$dev_tipo${NC}  ${DIM}(MAC aleatorizada)${NC}"
        log "    ${DIM}│${NC}"
        log "    ${DIM}├──${NC} Detalle    : $dev_detalle"
        [ -n "$ttl"      ] && log "    ${DIM}├──${NC} TTL        : $ttl  ${DIM}($os_ttl)${NC}"
        [ -n "$hostname" ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        [ -n "$mdns"     ] && log "    ${DIM}├──${NC} mDNS       : ${Y}$mdns${NC}"
        log "    ${DIM}└──${NC} MAC        : ${DIM}$mac  (aleatorizada)${NC}"
        log ""; continue
    fi

    # ════════════════════════════════════════════════════════════
    # APPLE OUI REAL
    # ════════════════════════════════════════════════════════════
    if [ "$oui_fab" = "Apple" ]; then
        IFS='|' read -r dev_tipo dev_detalle <<< "$(detect_linux_or_mac $ip)"
        log "    ${G}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${G}$dev_tipo${NC}"
        log "    ${DIM}│${NC}"
        log "    ${DIM}├──${NC} Detalle    : $dev_detalle"
        [ -n "$ttl"      ] && log "    ${DIM}├──${NC} TTL        : $ttl"
        [ -n "$hostname" ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        [ -n "$mdns"     ] && log "    ${DIM}├──${NC} mDNS       : ${Y}$mdns${NC}"
        log "    ${DIM}└──${NC} MAC        : ${DIM}$mac${NC}"
        log ""; continue
    fi

    # ════════════════════════════════════════════════════════════
    # TV POR OUI
    # ════════════════════════════════════════════════════════════
    if [ "$oui_tipo" = "TV" ]; then
        log "    ${M}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${M}📺 $oui_fab${NC}"
        log "    ${DIM}│${NC}"
        [ -n "$ttl"      ] && log "    ${DIM}├──${NC} TTL        : $ttl"
        [ -n "$hostname" ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        [ -n "$mdns"     ] && log "    ${DIM}├──${NC} mDNS       : ${Y}$mdns${NC}"
        log "    ${DIM}└──${NC} MAC        : ${DIM}$mac${NC}"
        log ""; continue
    fi

    # ════════════════════════════════════════════════════════════
    # MOVIL POR OUI
    # ════════════════════════════════════════════════════════════
    if [ "$oui_tipo" = "Mobile" ]; then
        log "    ${C}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${C}$oui_emoji Smartphone — $oui_fab${NC}"
        log "    ${DIM}│${NC}"
        log "    ${DIM}├──${NC} Fabricante : ${Y}$oui_fab${NC}"
        log "    ${DIM}├──${NC} OS         : ${W}Android${NC}"
        [ -n "$hostname" ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        [ -n "$mdns"     ] && log "    ${DIM}├──${NC} mDNS       : ${Y}$mdns${NC}"
        log "    ${DIM}└──${NC} MAC        : ${DIM}$mac${NC}"
        log ""; continue
    fi

    # ════════════════════════════════════════════════════════════
    # GAMING
    # ════════════════════════════════════════════════════════════
    if [ "$oui_tipo" = "Gaming" ]; then
        log "    ${Y}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${Y}$oui_emoji $oui_fab${NC}"
        log "    ${DIM}│${NC}"
        log "    ${DIM}├──${NC} Tipo       : ${W}Consola${NC}"
        [ -n "$hostname" ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        log "    ${DIM}└──${NC} MAC        : ${DIM}$mac${NC}"
        log ""; continue
    fi

    # ════════════════════════════════════════════════════════════
    # VM
    # ════════════════════════════════════════════════════════════
    if [ "$oui_tipo" = "VM" ]; then
        # VM puede ser Windows o Linux — usar TTL + puertos
        if [ "$os_ttl" = "Windows" ]; then
            IFS='|' read -r win_tipo win_det <<< "$(detect_windows $ip)"
            [ -z "$win_tipo" ] && win_tipo="🖥️  Windows (VM)|TTL=$ttl"
            log "    ${DIM}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${DIM}💻 $oui_fab — $win_tipo${NC}"
        else
            IFS='|' read -r lm_tipo lm_det <<< "$(detect_linux_or_mac $ip)"
            log "    ${DIM}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${DIM}💻 $oui_fab — $lm_tipo${NC}"
            log "    ${DIM}│${NC}"
            log "    ${DIM}├──${NC} Detalle    : $lm_det"
        fi
        [ -n "$ttl"      ] && log "    ${DIM}├──${NC} TTL        : $ttl"
        [ -n "$hostname" ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        log "    ${DIM}└──${NC} MAC        : ${DIM}$mac${NC}"
        log ""; continue
    fi

    # ════════════════════════════════════════════════════════════
    # ROUTER / RED
    # ════════════════════════════════════════════════════════════
    if [ "$oui_tipo" = "Router" ] || [ "$oui_tipo" = "Network" ]; then
        log "    ${ORANGE}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${ORANGE}🔌 $oui_fab${NC}"
        log "    ${DIM}│${NC}"
        log "    ${DIM}├──${NC} Tipo       : ${W}Router / Dispositivo de red${NC}"
        [ -n "$ttl"      ] && log "    ${DIM}├──${NC} TTL        : $ttl"
        [ -n "$hostname" ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        [ -n "$mdns"     ] && log "    ${DIM}├──${NC} mDNS       : ${Y}$mdns${NC}"
        log "    ${DIM}└──${NC} MAC        : ${DIM}$mac${NC}"
        log ""; continue
    fi

    # ════════════════════════════════════════════════════════════
    # DETECCIÓN CLÁSICA
    # ORDEN CORRECTO:
    #   1. TTL=128 → Windows (aunque no tenga puertos)
    #   2. Puertos Windows (SMB/RDP) → Windows confirmado
    #   3. TTL=64 → Linux/Mac (ir a detect_linux_or_mac)
    # Así nunca se clasifica un Windows como Mac por HTTP/SSH
    # ════════════════════════════════════════════════════════════

    # Intentar Windows por puertos PRIMERO (más fiable que TTL solo)
    IFS='|' read -r win_tipo win_detalle <<< "$(detect_windows $ip)"

    if [[ "$win_tipo" == *"Windows"* ]]; then
        # ── Windows confirmado por puertos ────────────────────
        win_info=$(get_windows_info "$ip")
        IFS='|||' read -r smb_info shares_info <<< "$win_info"

        log "    ${R}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${R}$win_tipo${NC}"
        log "    ${DIM}│${NC}"
        log "    ${DIM}├──${NC} MAC        : ${DIM}$mac${NC}"
        [ "$oui_fab" != "Desconocido" ] && log "    ${DIM}├──${NC} Fabricante : ${DIM}$oui_fab${NC}"
        [ -n "$ttl"         ] && log "    ${DIM}├──${NC} TTL        : $ttl"
        log "    ${DIM}├──${NC} Método     : $win_detalle"
        [ -n "$hostname"    ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        [ -n "$mdns"        ] && log "    ${DIM}├──${NC} mDNS       : ${Y}$mdns${NC}"
        [ -n "$smb_info"    ] && log "    ${DIM}├──${NC} SMB Info   : ${DIM}$smb_info${NC}"
        [ -n "$shares_info" ] && log "    ${DIM}├──${NC} Recursos   : ${DIM}$shares_info${NC}"
        $responde_icmp || log "    ${DIM}├──${NC} ICMP       : ${Y}Bloqueado${NC}"

    elif [ "$os_ttl" = "Windows" ]; then
        # ── TTL=128 → Windows con firewall (sin puertos) ─────
        log "    ${R}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${R}🖥️  Windows${NC}  ${DIM}(firewall — puertos bloqueados)${NC}"
        log "    ${DIM}│${NC}"
        log "    ${DIM}├──${NC} MAC        : ${DIM}$mac${NC}"
        [ "$oui_fab" != "Desconocido" ] && log "    ${DIM}├──${NC} Fabricante : ${DIM}$oui_fab${NC}"
        log "    ${DIM}├──${NC} TTL        : $ttl  ${DIM}(TTL≤128 → Windows)${NC}"
        [ -n "$hostname" ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        log "    ${DIM}├──${NC} Detalle    : SMB/RDP bloqueados por firewall"
        $responde_icmp || log "    ${DIM}├──${NC} ICMP       : ${Y}Bloqueado${NC}"

    else
        # ── TTL≤64 → Linux o Mac ─────────────────────────────
        IFS='|' read -r lm_tipo lm_detalle <<< "$(detect_linux_or_mac $ip)"
        linux_ports=$(get_linux_vulnports "$ip")

        log "    ${G}◈${NC} ${BOLD}${W}$ip${NC}  ${DIM}│${NC}  ${G}$lm_tipo${NC}"
        log "    ${DIM}│${NC}"
        log "    ${DIM}├──${NC} MAC        : ${DIM}$mac${NC}"
        [ "$oui_fab" != "Desconocido" ] && log "    ${DIM}├──${NC} Fabricante : ${DIM}$oui_fab${NC}"
        [ -n "$ttl"         ] && log "    ${DIM}├──${NC} TTL        : $ttl"
        log "    ${DIM}├──${NC} Detalle    : $lm_detalle"
        [ -n "$hostname"    ] && log "    ${DIM}├──${NC} Hostname   : ${Y}$hostname${NC}"
        [ -n "$mdns"        ] && log "    ${DIM}├──${NC} mDNS       : ${Y}$mdns${NC}"
        [ -n "$linux_ports" ] && log "    ${DIM}├──${NC} ${R}Puertos↑   : ${Y}$linux_ports${NC}"
        $responde_icmp || log "    ${DIM}├──${NC} ICMP       : ${Y}Bloqueado${NC}"
    fi

    log ""
done

# ─── RESUMEN ───────────────────────────────────────────────────
log "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
log "    ${G}[✓]${NC} Escaneo completado — ${W}${BOLD}$COUNT hosts${NC} encontrados"
log "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ─── MENU NMAP ─────────────────────────────────────────────────
while true; do
    echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "    ${Y}[?]${NC} ${BOLD}¿Escaneo completo nmap?${NC}  ${DIM}[s/N]${NC}"
    echo -ne "    ${W}❯ ${NC}"; read -r resp_scan
    [[ ! "$resp_scan" =~ ^[sS]$ ]] && break

    echo ""
    echo -e "    ${C}[*]${NC} Hosts encontrados:\n"
    for idx in "${!HOSTS_ENCONTRADOS[@]}"; do
        echo -e "    ${DIM}[$((idx+1))]${NC} ${W}${HOSTS_ENCONTRADOS[$idx]}${NC}"
    done
    echo ""
    echo -e "    ${C}[?]${NC} ${BOLD}IP a escanear:${NC}"
    echo -ne "    ${W}❯ ${NC}"; read -r target_ip
    [[ ! "$target_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] \
        && echo -e "\n    ${R}[!]${NC} IP no válida.\n" && continue
    run_full_nmap "$target_ip"
done

# ─── DIRECTORIO DE LOGS ────────────────────────────────────────
echo ""
echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${C}[?]${NC} ${BOLD}¿Dónde guardar el log?${NC}  ${DIM}[Enter = directorio actual: $(pwd)]${NC}"
echo -ne "    ${W}❯ ${NC}"; read -r LOG_DESTINO
[ -z "$LOG_DESTINO" ] && LOG_DESTINO="$(pwd)"

if [ ! -d "$LOG_DESTINO" ]; then
    mkdir -p "$LOG_DESTINO" 2>/dev/null || { LOG_DESTINO="/tmp"; echo -e "    ${R}[!]${NC} Sin permisos, usando /tmp"; }
fi
[ ! -w "$LOG_DESTINO" ] && { LOG_DESTINO="/tmp"; echo -e "    ${R}[!]${NC} Sin permisos, usando /tmp"; }

FINAL_LOG="${LOG_DESTINO}/scan_${TIMESTAMP}.txt"
mv "$OUTFILE" "$FINAL_LOG" 2>/dev/null || cp "$OUTFILE" "$FINAL_LOG" 2>/dev/null

# Mover también los nmap si existen
for entry in "${NMAP_FILES[@]}"; do
    tmp_file="${entry%%:*}"
    ip_part="${entry##*:}"
    dest="${LOG_DESTINO}/nmap_${ip_part//\./_}_${TIMESTAMP}.txt"
    mv "$tmp_file" "$dest" 2>/dev/null
done

echo -e "\n    ${G}[✓]${NC} Log guardado en: ${W}${FINAL_LOG}${NC}\n"
echo -e "    ${G}[✓]${NC} Fin. ¡Hasta la próxima!\n"

tput cnorm
