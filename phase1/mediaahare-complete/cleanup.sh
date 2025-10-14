#!/bin/bash

echo "🧹 Cleaning up Docker resources..."

# Stop and remove container
docker stop ansible-test-vm 2>/dev/null || true
docker rm ansible-test-vm 2>/dev/null || true

# Remove image
docker rmi ansible-test-ubuntu 2>/dev/null || true

# Remove any containers created by Ansible
docker ps -a | grep fastapi_app | awk '{print $1}' | xargs docker rm -f 2>/dev/null || true

# Remove any images created by Ansible
docker images | grep mediaahare/fastapi | awk '{print $3}' | xargs docker rmi -f 2>/dev/null || true

echo "✅ Cleanup complete!"
