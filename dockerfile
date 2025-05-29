FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-utils \
    cloud-image-utils \
    genisoimage \
    novnc \
    websockify \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /opt/qemu

# Download minimal cloud image
RUN curl -L https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img \
    -o /opt/qemu/ubuntu.img

# Convert image to raw format during build
RUN qemu-img convert -f qcow2 -O raw /opt/qemu/ubuntu.img /opt/qemu/ubuntu.raw && \
    qemu-img resize /opt/qemu/ubuntu.raw 10G

# Create start script
RUN echo '#!/bin/sh
# Start QEMU with minimal resources
qemu-system-x86_64 \
    -m 512M \
    -smp 1 \
    -drive file=/opt/qemu/ubuntu.raw,format=raw,if=virtio \
    -boot order=c \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net,netdev=net0 \
    -vnc :0 \
    -daemonize

# Start noVNC
websockify --web=/novnc 6080 localhost:5900
' > /start.sh && chmod +x /start.sh

EXPOSE 6080 2222
CMD ["/start.sh"]
