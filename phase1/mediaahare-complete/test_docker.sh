#!/bin/bash
set -e

CONTAINER_NAME="ansible-test-vm"
IMAGE_NAME="ansible-test-ubuntu"

echo "🔨 Building Docker test image..."
docker build -t $IMAGE_NAME -f - . << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y openssh-server sudo python3 curl wget vim iproute2 systemd && \
    apt-get clean
RUN useradd -m -s /bin/bash ubuntu && \
    echo 'ubuntu:ubuntu' | chpasswd && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN mkdir -p /var/run/sshd
EXPOSE 22 8000
CMD ["/usr/sbin/sshd", "-D"]
DOCKERFILE

echo "✅ Image built"
echo "🚀 Starting container..."
docker run -d \
    --name $CONTAINER_NAME \
    --privileged \
    -p 2222:22 \
    -p 8000:8000 \
    $IMAGE_NAME

echo "⏳ Waiting for SSH..."
sleep 5

echo "✅ Container started"
echo ""
echo "🎯 Running Ansible playbook..."
cd ansible
ansible-playbook playbooks/site.yml -i inventories/test/docker_hosts.yml

echo ""
echo "✅ Deployment complete!"
