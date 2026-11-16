#!/bin/sh
set -e

: "${PROXY_PORT:?ERROR: PROXY_PORT environment variable is required (e.g. PROXY_PORT=1080)}"
export PROXY_PORT

mkdir -p /var/lib/lockdown
rm -rf /var/run/usbmuxd

find_tether_iface() {
    for netdir in /sys/class/net/*; do
        [ -e "$netdir" ] || continue
        iface=$(basename "$netdir")
        drv=$(basename "$(readlink "$netdir/device/driver" 2>/dev/null)" 2>/dev/null || true)
        case "$drv" in
            ipheth|rndis_host|cdc_ncm)
                echo "$iface"
                return 0
                ;;
        esac
    done
}

usbmuxd -f -v -U root &
USBMUXD_PID=$!
echo "usbmuxd started (PID: $USBMUXD_PID). Waiting for device..."

while true; do
    if ! kill -0 "$USBMUXD_PID" 2>/dev/null; then
        echo "usbmuxd stopped. Restarting..."
        rm -rf /var/run/usbmuxd
        usbmuxd -f -v -U root &
        USBMUXD_PID=$!
    fi

    IFACE=$(find_tether_iface)
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