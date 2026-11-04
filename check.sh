
#!/usr/bin/env bash

while true; do

    clear

    set -euo pipefail

    # Fecha y hostname
    FECHA=$(date '+%Y-%m-%d %H:%M:%S')
    HOSTNAME=$(hostname)

    # Obtener IP principal
    IP=$(hostname -I | awk '{print $1}')
    IP=${IP:-"N/A"}

    # Número de CPUs lógicas
    NUM_CPU=$(nproc)

    # CPU: medir uso entre dos muestras
    read -r _ USER NICE SYSTEM IDLE IOWAIT IRQ SOFTIRQ STEAL _ < /proc/stat
    CPU_IDLE1=$((IDLE + IOWAIT))
    CPU_TOTAL1=$((USER + NICE + SYSTEM + IDLE + IOWAIT + IRQ + SOFTIRQ + STEAL))

    sleep 1

    read -r _ USER NICE SYSTEM IDLE IOWAIT IRQ SOFTIRQ STEAL _ < /proc/stat
    CPU_IDLE2=$((IDLE + IOWAIT))
    CPU_TOTAL2=$((USER + NICE + SYSTEM + IDLE + IOWAIT + IRQ + SOFTIRQ + STEAL))

    TOTAL_DIFF=$((CPU_TOTAL2 - CPU_TOTAL1))
    IDLE_DIFF=$((CPU_IDLE2 - CPU_IDLE1))

    if (( TOTAL_DIFF > 0 )); then
        CPU=$(awk -v t="$TOTAL_DIFF" -v i="$IDLE_DIFF" \
            'BEGIN {printf "%.2f", (t-i)*100/t}')
    else
        CPU="0.00"
    fi

    # Load Average
    read -r LOAD_1M LOAD_5M LOAD_15M _ < /proc/loadavg

    # RAM y SWAP
    RAM_TOTAL=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
    RAM_AVAILABLE=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
    SWAP_TOTAL=$(awk '/SwapTotal:/ {print $2}' /proc/meminfo)
    SWAP_FREE=$(awk '/SwapFree:/ {print $2}' /proc/meminfo)

    RAM_USED=$((RAM_TOTAL - RAM_AVAILABLE))
    if (( RAM_TOTAL > 0 )); then
        RAM=$(awk -v u="$RAM_USED" -v t="$RAM_TOTAL" \
            'BEGIN {printf "%.2f", u*100/t}')
    else
        RAM="0.00"
    fi

    SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
    if (( SWAP_TOTAL > 0 )); then
        SWAP=$(awk -v u="$SWAP_USED" -v t="$SWAP_TOTAL" \
            'BEGIN {printf "%.2f", u*100/t}')
    else
        SWAP="0.00"
    fi

    # Disco: porcentaje usado de todos los discos montados
    DISK=$(df -P -x tmpfs -x devtmpfs -x squashfs | awk '
    NR > 1 {
        gsub("%", "", $5)
        printf "%s%s (%s)", separator, $5 "%", $6
        separator = " "
    }')

    # Salida
    echo "FECHA: $FECHA"
    echo "HOSTNAME: $HOSTNAME $IP"
    echo "NUM_CPU: $NUM_CPU"
    echo "CPU: ${CPU}%"
    echo "LOAD_AVERAGE: $LOAD_1M/$LOAD_5M/$LOAD_15M"
    echo "RAM: ${RAM}%"
    echo "SWAP: ${SWAP}%"
    echo "DISK: ${DISK}%"

    sleep 20
done
