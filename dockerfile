FROM alpine:latest

RUN apk add --no-cache qemu-system-x86_64 qemu-img novnc websockify bash

RUN mkdir -p /opt/qemu && \
    wget https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img \
    -O /opt/qemu/ubuntu.img && \
    qemu-img convert -f qcow2 -O raw /opt/qemu/ubuntu.img /opt/qemu/ubuntu.raw

RUN echo '#!/bin/bash
qemu-system-x86_64 \
    -m 256M \
    -smp 1 \
    -nographic \
    -drive file=/opt/qemu/ubuntu.raw,format=raw,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net,netdev=net0 &
websockify 6080 localhost:5900
' > /start.sh && chmod +x /start.sh

EXPOSE 6080 2222
CMD ["/start.sh"]
