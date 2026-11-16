FROM alpine:latest

ENV PROXY_PORT=""

RUN apk add --no-cache \
    usbmuxd \
    libimobiledevice-progs \
    iproute2 \
    socat \
    vnstat

COPY udhcpc-no-gw.sh /udhcpc-no-gw.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /udhcpc-no-gw.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]