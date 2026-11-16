#!/bin/sh
set -e

case "$1" in
    deconfig)
        ip addr flush dev "$interface" 2>/dev/null || true
        [ -f /var/run/socat.pid ] && kill "$(cat /var/run/socat.pid)" 2>/dev/null || true
        rm -f /var/run/socat-gw
        ;;
    bound|renew)
        ip addr replace "$ip/${mask:-28}" dev "$interface"

        if [ -n "$router" ]; then
            GW=$(echo "$router" | awk '{print $1}')
            CURRENT_GW=$(cat /var/run/socat-gw 2>/dev/null || true)

            if [ "$GW" != "$CURRENT_GW" ] || ! kill -0 "$(cat /var/run/socat.pid 2>/dev/null)" 2>/dev/null; then
                [ -f /var/run/socat.pid ] && kill "$(cat /var/run/socat.pid)" 2>/dev/null || true
                socat "TCP-LISTEN:${PROXY_PORT},fork,reuseaddr" "TCP:${GW}:${PROXY_PORT}" &
                echo $! > /var/run/socat.pid
                echo "$GW" > /var/run/socat-gw
                echo "SOCKS5 relay started: port ${PROXY_PORT} -> ${GW}:${PROXY_PORT}"
            fi
        fi
        ;;
esac