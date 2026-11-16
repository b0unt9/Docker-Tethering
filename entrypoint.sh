#!/bin/sh
set -e

: "${PROXY_PORT:?ERROR: PROXY_PORT environment variable is required (e.g. PROXY_PORT=1080)}"

mkdir -p /var/lib/lockdown
rm -rf /var/run/usbmuxd

socat "TCP-LISTEN:${PROXY_PORT},fork,reuseaddr" "TCP:172.20.10.1:${PROXY_PORT}" &
echo "PROXY relay started on port ${PROXY_PORT} -> 172.20.10.1:${PROXY_PORT}"

usbmuxd -f -v -U root &
USBMUXD_PID=$!
echo "usbmuxd started (PID: $USBMUXD_PID). Waiting for iPhone..."

while true; do
    if ! kill -0 "$USBMUXD_PID" 2>/dev/null; then
        echo "usbmuxd stopped. Restarting..."
        rm -rf /var/run/usbmuxd
        usbmuxd -f -v -U root &
        USBMUXD_PID=$!
    fi

    IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(enx|usb)' | head -n 1)
    if [ -n "$IFACE" ]; then
        if ! ip addr show "$IFACE" | grep -q "inet "; then
            echo "Found tethering interface: $IFACE. Requesting IP..."
            ip link set "$IFACE" up
            [ -f "/var/run/udhcpc-$IFACE.pid" ] && kill "$(cat "/var/run/udhcpc-$IFACE.pid")" 2>/dev/null || true
            udhcpc -i "$IFACE" -s /usr/local/bin/udhcpc-no-gw.sh -b -p "/var/run/udhcpc-$IFACE.pid"
        fi
    fi
    sleep 5
done