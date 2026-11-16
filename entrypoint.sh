#!/bin/sh
set -e

mkdir -p /var/lib/lockdown /var/run/usbmuxd

usbmuxd -v -U root &
USBMUXD_PID=$!
echo "usbmuxd started (PID: $USBMUXD_PID). Waiting for iPhone..."

while true; do
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