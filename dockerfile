FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install minimal packages
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

# Use minimal cloud image
RUN curl -L https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img \
    -o /opt/qemu/ubuntu.img

# Create optimized start script
RUN echo '#!/bin/sh
# Convert image to raw format (more efficient for QEMU)
qemu-img convert -f qcow2 -O raw /opt/qemu/ubuntu.img /opt/qemu/ubuntu.raw

# Start QEMU with minimal resources
qemu-system-x86_64 \
    -m 256M \
    -smp 1 \
    -drive file=/opt/qemu/ubuntu.raw,format=raw,if=virtio \
    -drive file=/opt/qemu/seed.iso,format=raw,media=cdrom \
    -boot order=c \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net,netdev=net0 \
    -nographic \
    -vnc :0 \
    -daemonize

# Start noVNC with minimal footprint
websockify --web=/novnc 6080 localhost:5900
' > /start.sh && chmod +x /start.sh

EXPOSE 6080
CMD ["/start.sh"]
