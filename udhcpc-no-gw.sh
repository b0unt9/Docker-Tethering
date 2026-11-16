#!/bin/sh
set -e

case "$1" in
    deconfig)
        ip addr flush dev "$interface" 2>/dev/null || true
        ;;
    bound|renew)
        ip addr replace "$ip/${mask:-28}" dev "$interface"
        ;;
esac