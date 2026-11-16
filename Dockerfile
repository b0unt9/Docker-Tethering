FROM alpine:latest

RUN apk add --no-cache \
    usbmuxd \
    libimobiledevice-progs \
    iproute2

COPY udhcpc-no-gw.sh /usr/local/bin/udhcpc-no-gw.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/udhcpc-no-gw.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]