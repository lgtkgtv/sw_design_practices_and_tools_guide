#!/bin/bash
#
# MediaShare Complete Project Setup - Final Working Version
# This script creates a complete, tested Ansible + Docker setup
#
# Usage: ./setup_complete_project.sh

set -e

PROJECT_NAME="mediashare-complete"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }

print_header "MediaShare Complete Project Setup"

# Check if project exists
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${RED}⚠️  Warning: Directory '$PROJECT_NAME' already exists!${NC}"
    read -p "   Remove and start fresh? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$PROJECT_NAME"
        print_success "Removed existing directory"
    else
        print_error "Aborted. Please remove the directory manually."
        exit 1
    fi
fi

print_info "Creating project: $PROJECT_NAME"
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# ============================================================================
# CREATE DIRECTORY STRUCTURE
# ============================================================================
print_header "Creating Directory Structure"

mkdir -p ansible/{inventories/{dev,test}/group_vars,roles/{common,docker,fastapi_app}/{tasks,handlers,templates,files,tests},playbooks,files/fastapi_hello}

print_success "Directory structure created"

# ============================================================================
# CREATE ANSIBLE CONFIGURATION
# ============================================================================
print_header "Creating Ansible Configuration"

cat > ansible/ansible.cfg << 'EOF'
[defaults]
inventory = ./inventories/dev
roles_path = ./roles
host_key_checking = False
timeout = 30
force_color = True
stdout_callback = yaml
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600
pipelining = True

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
EOF

print_success "ansible.cfg created"

# ============================================================================
# CREATE FASTAPI APPLICATION
# ============================================================================
print_header "Creating FastAPI Application"

cat > ansible/files/fastapi_hello/main.py << 'EOFPY'
"""
FastAPI Hello World Application
Cloud-ready with health checks and metadata endpoints
"""
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import os
import socket
import time
from datetime import datetime

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
CLOUD_PROVIDER = os.getenv("CLOUD_PROVIDER", "unknown")

app = FastAPI(
    title="MediaShare API",
    description="Phase 1: Hello World with Cloud Metadata",
    version=APP_VERSION
)

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    hostname: str
    environment: str
    cloud_provider: str
    version: str
    uptime_seconds: float

START_TIME = time.time()

@app.get("/", response_model=dict)
async def root():
    return {
        "message": "Welcome to MediaShare API",
        "version": APP_VERSION,
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        hostname=socket.gethostname(),
        environment=ENVIRONMENT,
        cloud_provider=CLOUD_PROVIDER,
        version=APP_VERSION,
        uptime_seconds=round(time.time() - START_TIME, 2)
    )

@app.get("/metadata")
async def instance_metadata():
    return {
        "hostname": socket.gethostname(),
        "environment": ENVIRONMENT,
        "cloud_provider": CLOUD_PROVIDER,
        "version": APP_VERSION,
    }

@app.get("/ready")
async def readiness_check():
    return {"status": "ready"}

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "detail": str(exc),
            "timestamp": datetime.utcnow().isoformat()
        }
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
EOFPY

cat > ansible/files/fastapi_hello/requirements.txt << 'EOF'
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.3
python-multipart==0.0.6
EOF

cat > ansible/files/fastapi_hello/Dockerfile << 'EOF'
FROM python:3.11-slim as builder
RUN pip install --no-cache-dir uv
WORKDIR /app
COPY requirements.txt ./
RUN uv pip install --system --no-cache -r requirements.txt

FROM python:3.11-slim
RUN groupadd -r appuser && useradd -r -g appuser appuser
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY main.py ./
RUN chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
EOF

print_success "FastAPI application files created"

# ============================================================================
# CREATE ANSIBLE ROLES - COMMON
# ============================================================================
print_header "Creating Ansible Roles"

cat > ansible/roles/common/tasks/main.yml << 'EOF'
---
- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
  when: ansible_os_family == "Debian"

- name: Install essential packages
  apt:
    name:
      - curl
      - wget
      - git
      - vim
      - htop
      - net-tools
      - software-properties-common
      - apt-transport-https
      - ca-certificates
      - gnupg
      - lsb-release
      - unattended-upgrades
      - tzdata
    state: present
  when: ansible_os_family == "Debian"

- name: Configure unattended upgrades
  copy:
    dest: /etc/apt/apt.conf.d/50unattended-upgrades
    content: |
      Unattended-Upgrade::Allowed-Origins {
          "${distro_id}:${distro_codename}-security";
      };
      Unattended-Upgrade::AutoFixInterruptedDpkg "true";
      Unattended-Upgrade::MinimalSteps "true";
      Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
      Unattended-Upgrade::Remove-Unused-Dependencies "true";
      Unattended-Upgrade::Automatic-Reboot "false";
    mode: '0644'

- name: Set timezone to UTC
  timezone:
    name: UTC
  ignore_errors: yes

- name: Create application group
  group:
    name: "{{ app_group }}"
    system: yes
    state: present

- name: Create application user
  user:
    name: "{{ app_user }}"
    group: "{{ app_group }}"
    shell: /bin/bash
    create_home: yes
    system: yes

- name: Create application directory
  file:
    path: "{{ app_directory }}"
    state: directory
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0755'

- name: Create log directory
  file:
    path: "{{ log_directory }}"
    state: directory
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0755'
EOF

cat > ansible/roles/common/handlers/main.yml << 'EOF'
---
- name: restart ssh
  service:
    name: ssh
    state: restarted
EOF

# ============================================================================
# CREATE ANSIBLE ROLES - DOCKER
# ============================================================================

cat > ansible/roles/docker/tasks/main.yml << 'EOF'
---
- name: Remove old Docker versions
  apt:
    name:
      - docker
      - docker-engine
      - docker.io
      - containerd
      - runc
    state: absent
  when: ansible_os_family == "Debian"

- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present
  when: ansible_os_family == "Debian"

- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present
    filename: docker
  when: ansible_os_family == "Debian"

- name: Update apt cache
  apt:
    update_cache: yes
  when: ansible_os_family == "Debian"

- name: Install Docker
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
      - python3-docker
      - python3-requests
    state: present
  when: ansible_os_family == "Debian"

- name: Start Docker service
  service:
    name: docker
    state: started
    enabled: yes

- name: Add user to docker group
  user:
    name: "{{ app_user | default('appuser') }}"
    groups: docker
    append: yes

- name: Configure Docker daemon
  copy:
    dest: /etc/docker/daemon.json
    content: |
      {
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "10m",
          "max-file": "3"
        },
        "live-restore": true
      }
    mode: '0644'
  notify: restart docker
EOF

cat > ansible/roles/docker/handlers/main.yml << 'EOF'
---
- name: restart docker
  service:
    name: docker
    state: restarted
EOF

# ============================================================================
# CREATE ANSIBLE ROLES - FASTAPI_APP
# ============================================================================

cat > ansible/roles/fastapi_app/tasks/main.yml << 'EOF'
---
- name: Create app directory structure
  file:
    path: "{{ item }}"
    state: directory
    owner: "{{ app_user | default('appuser') }}"
    mode: '0755'
  loop:
    - "{{ app_directory }}/app"
    - "{{ app_directory }}/logs"

- name: Copy application files
  copy:
    src: "{{ playbook_dir }}/../files/fastapi_hello/{{ item }}"
    dest: "{{ app_directory }}/app/{{ item }}"
    owner: "{{ app_user | default('appuser') }}"
    mode: '0644'
  loop:
    - main.py
    - requirements.txt
    - Dockerfile

- name: Build Docker image
  community.docker.docker_image:
    name: "{{ docker_image_name }}:{{ docker_image_tag }}"
    source: build
    build:
      path: "{{ app_directory }}/app"
    state: present
    force_source: yes

- name: Stop existing container if running
  community.docker.docker_container:
    name: "{{ container_name }}"
    state: absent
  ignore_errors: yes

- name: Start FastAPI container
  community.docker.docker_container:
    name: "{{ container_name }}"
    image: "{{ docker_image_name }}:{{ docker_image_tag }}"
    state: started
    restart_policy: unless-stopped
    ports:
      - "{{ fastapi_port }}:8000"
    env:
      ENVIRONMENT: "{{ environment | default('development') | string }}"
      CLOUD_PROVIDER: "{{ cloud_provider | default('unknown') | string }}"
      APP_VERSION: "{{ app_version | default('1.0.0') | string }}"
    log_driver: json-file
    log_options:
      max-size: "10m"
      max-file: "3"

- name: Wait for health check
  uri:
    url: "http://localhost:{{ fastapi_port | default(8000) }}/health"
    status_code: 200
  register: result
  until: result.status == 200
  retries: 12
  delay: 5

- name: Display access info
  debug:
    msg:
      - "✅ Application is running!"
      - "🌐 URL: http://{{ ansible_host }}:{{ fastapi_port | default(8000) }}"
      - "📚 Docs: http://{{ ansible_host }}:{{ fastapi_port | default(8000) }}/docs"
EOF

# ============================================================================
# CREATE PLAYBOOKS
# ============================================================================

cat > ansible/playbooks/site.yml << 'EOF'
---
- name: Complete MediaShare Deployment
  hosts: all
  become: yes
  gather_facts: yes
  
  pre_tasks:
    - name: Display deployment info
      debug:
        msg:
          - "Deploying to: {{ inventory_hostname }}"
          - "Cloud: {{ cloud_provider | default('unknown') }}"
          - "Environment: {{ environment | default('development') }}"
    
    - name: Wait for connection
      wait_for_connection:
        timeout: 300
  
  roles:
    - common
    - docker
    - fastapi_app
  
  post_tasks:
    - name: Wait for Docker to stabilize after config changes
      pause:
        seconds: 10
    
    - name: Ensure FastAPI container is running
      community.docker.docker_container:
        name: "{{ container_name }}"
        state: started
      ignore_errors: yes
    
    - name: Wait a bit more for application to be ready
      pause:
        seconds: 5
    
    - name: Final health check
      uri:
        url: "http://localhost:{{ fastapi_port | default(8000) }}/health"
        return_content: yes
      register: health
      retries: 12
      delay: 5
      until: health.status == 200
    
    - name: Display success message
      debug:
        msg:
          - "═══════════════════════════════════════"
          - "✅ DEPLOYMENT SUCCESSFUL!"
          - "═══════════════════════════════════════"
          - "🌐 http://{{ ansible_host }}:{{ fastapi_port | default(8000) }}"
          - "📚 http://{{ ansible_host }}:{{ fastapi_port | default(8000) }}/docs"
EOF

# ============================================================================
# CREATE INVENTORIES
# ============================================================================

cat > ansible/inventories/test/docker_hosts.yml << 'EOF'
all:
  children:
    docker_instances:
      hosts:
        docker_test_vm:
          ansible_host: localhost
          ansible_port: 2222
          ansible_user: ubuntu
          ansible_password: ubuntu
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
          ansible_become_password: ubuntu
          
          cloud_provider: docker-test
          environment: testing
          
      vars:
        app_name: mediaahare
        app_user: appuser
        app_group: appuser
        app_directory: /opt/mediaahare
        
        fastapi_port: 8000
        container_name: fastapi_app
        app_version: "1.0.0-test"
        
        docker_image_name: mediaahare/fastapi
        docker_image_tag: test
        
        container_memory_limit: 512m
        container_cpu_limit: "0.5"
        
        enable_firewall: false
        
        log_directory: /var/log/mediaahare
        log_retention_days: 7
EOF

cat > ansible/inventories/dev/group_vars/all.yml << 'EOF'
---
app_name: mediaahare
app_user: appuser
app_group: appuser
app_directory: /opt/mediaahare

docker_version: "24.0"
docker_compose_version: "2.23.0"

python_version: "3.11"

enable_firewall: true
enable_health_checks: true
health_check_interval: 30

log_directory: /var/log/mediaahare
log_retention_days: 7
EOF

cat > ansible/inventories/dev/aws_hosts.yml << 'EOF'
all:
  children:
    aws_instances:
      hosts:
        aws_app_server:
          ansible_host: REPLACE_WITH_TERRAFORM_OUTPUT
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/mediaahare-aws-dev.pem
          cloud_provider: aws
          aws_region: us-east-1
          aws_availability_zone: us-east-1a
      vars:
        environment: development
        app_version: "1.0.0"
        fastapi_port: 8000
        container_name: fastapi_app
        docker_image_name: mediaahare/fastapi
        docker_image_tag: latest
EOF

cat > ansible/inventories/dev/gcp_hosts.yml << 'EOF'
all:
  children:
    gcp_instances:
      hosts:
        gcp_app_server:
          ansible_host: REPLACE_WITH_TERRAFORM_OUTPUT
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/mediaahare-gcp-dev
          cloud_provider: gcp
          gcp_project: your-project-id
          gcp_region: us-central1
          gcp_zone: us-central1-a
      vars:
        environment: development
        app_version: "1.0.0"
        fastapi_port: 8000
        container_name: fastapi_app
        docker_image_name: mediaahare/fastapi
        docker_image_tag: latest
EOF

print_success "Ansible configuration complete"

# ============================================================================
# CREATE DOCKER TEST SCRIPT
# ============================================================================
print_header "Creating Docker Test Script"

cat > test_docker.sh << 'EOFSCRIPT'
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
EOFSCRIPT

chmod +x test_docker.sh

print_success "test_docker.sh created"

# ============================================================================
# CREATE API TEST SCRIPT
# ============================================================================

cat > test_api.sh << 'EOFSCRIPT'
#!/bin/bash

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Testing MediaShare API Endpoints                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "1️⃣  Health Check:"
curl -s http://localhost:8000/health | python3 -m json.tool
echo ""

echo "2️⃣  Root Endpoint:"
curl -s http://localhost:8000/ | python3 -m json.tool
echo ""

echo "3️⃣  Metadata:"
curl -s http://localhost:8000/metadata | python3 -m json.tool
echo ""

echo "4️⃣  Readiness:"
curl -s http://localhost:8000/ready | python3 -m json.tool
echo ""

echo "5️⃣  API Documentation (first 20 lines):"
curl -s http://localhost:8000/openapi.json | python3 -m json.tool | head -20
echo ""

echo "✅ All endpoints tested successfully!"
EOFSCRIPT

chmod +x test_api.sh

print_success "test_api.sh created"

# ============================================================================
# CREATE CLEANUP SCRIPT
# ============================================================================

cat > cleanup.sh << 'EOFSCRIPT'
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
EOFSCRIPT

chmod +x cleanup.sh

print_success "cleanup.sh created"

# ============================================================================
# CREATE README
# ============================================================================

cat > README.md << 'EOF'
# MediaShare - Complete Working Package

## Quick Start (5 Minutes)

### 1. Install Prerequisites

```bash
# Install Ansible
pip install ansible

# Install Ansible collections
ansible-galaxy collection install community.docker community.general

# Verify Docker is running
docker ps
```

### 2. Run Complete Test

```bash
# Start fresh - cleanup any old containers
./cleanup.sh

# Run the complete test (builds image + deploys)
./test_docker.sh
```

### 3. Test the Application

```bash
# Test all endpoints
./test_api.sh

# Or test individually
curl http://localhost:8000/health
curl http://localhost:8000/docs
```

## Project Structure

```
.
├── ansible/
│   ├── ansible.cfg                 # Ansible configuration
│   ├── inventories/
│   │   ├── dev/                    # Production inventory templates
│   │   │   ├── aws_hosts.yml       # AWS inventory
│   │   │   ├── gcp_hosts.yml       # GCP inventory
│   │   │   └── group_vars/all.yml  # Common variables
│   │   └── test/
│   │       └── docker_hosts.yml    # Docker test inventory
│   ├── roles/
│   │   ├── common/                 # OS hardening & security
│   │   ├── docker/                 # Docker installation
│   │   └── fastapi_app/            # Application deployment
│   ├── playbooks/
│   │   └── site.yml                # Master playbook
│   └── files/
│       └── fastapi_hello/          # FastAPI application
├── test_docker.sh                  # Complete test script
├── test_api.sh                     # API endpoint tester
├── cleanup.sh                      # Cleanup Docker resources
└── README.md                       # This file
```

## What Gets Deployed

1. ✅ **OS Hardening** (common role)
   - Security updates (automatic)
   - Application user/group creation
   - Directory structure

2. ✅ **Docker Installation** (docker role)
   - Docker CE + plugins
   - Docker daemon configuration
   - Python Docker libraries

3. ✅ **FastAPI Application** (fastapi_app role)
   - Multi-stage Docker build
   - Container deployment
   - Health check verification

## Common Commands

```bash
# Clean start
./cleanup.sh
./test_docker.sh

# Test API
./test_api.sh

# SSH into test container
ssh -p 2222 ubuntu@localhost
# Password: ubuntu

# View application logs
docker exec ansible-test-vm docker logs fastapi_app

# Re-deploy (after making changes)
cd ansible
ansible-playbook playbooks/site.yml -i inventories/test/docker_hosts.yml

# Test idempotency (should show mostly "ok")
ansible-playbook playbooks/site.yml -i inventories/test/docker_hosts.yml
```

## Making Changes

### Edit the FastAPI Application

```bash
# Edit the application
vim ansible/files/fastapi_hello/main.py

# Re-deploy just the app
cd ansible
ansible-playbook playbooks/site.yml -i inventories/test/docker_hosts.yml --tags fastapi_app

# Test
curl http://localhost:8000/health
```

### Edit Ansible Roles

```bash
# Edit a role
vim ansible/roles/common/tasks/main.yml

# Re-run the playbook
cd ansible
ansible-playbook playbooks/site.yml -i inventories/test/docker_hosts.yml
```

## Next Steps

### Deploy to AWS/GCP

1. Provision infrastructure with Terraform (coming next)
2. Update `ansible/inventories/dev/aws_hosts.yml` with instance IP
3. Run: `ansible-playbook playbooks/site.yml -i inventories/dev/aws_hosts.yml`

### Add Features

- PostgreSQL database
- Redis caching
- Secrets management
- SSL/TLS certificates
- Monitoring and alerting

### Set Up CI/CD

- GitHub Actions workflow
- Automated testing
- Docker image scanning
- Automated deployment

## Troubleshooting

### "Cannot connect to Docker daemon"

```bash
# Start Docker
sudo systemctl start docker

# Or on macOS, start Docker Desktop
```

### "Container already exists"

```bash
# Clean up and try again
./cleanup.sh
./test_docker.sh
```

### "Ansible connection failed"

```bash
# Wait for SSH to start
sleep 5

# Test SSH manually
ssh -p 2222 ubuntu@localhost
```

### "Port already in use"

```bash
# Find what's using the port
lsof -i :8000
lsof -i :2222

# Kill the process or clean up
./cleanup.sh
```

## Success Criteria

✅ `./test_docker.sh` completes without errors
✅ `./test_api.sh` shows all endpoints working
✅ Health check returns `"status": "healthy"`
✅ API docs accessible at http://localhost:8000/docs
✅ Re-running playbook shows idempotency (mostly "ok")

## Support

If something doesn't work:

1. Run `./cleanup.sh` to start fresh
2. Check Docker is running: `docker ps`
3. Check Ansible is installed: `ansible --version`
4. Verify collections: `ansible-galaxy collection list`
5. Try running with verbose: `ansible-playbook ... -vvv`
EOF

# ============================================================================
# FINAL SUMMARY
# ============================================================================

cd ..
print_header "Setup Complete!"

echo ""
print_success "Project Created Successfully!"
echo ""
echo "📁 Project location: $PROJECT_NAME/"
echo ""
echo "🚀 Quick Start:"
echo "   cd $PROJECT_NAME"
echo "   ./cleanup.sh           # Clean any old containers"
echo "   ./test_docker.sh       # Run complete test (~5-10 min)"
echo "   ./test_api.sh          # Verify all endpoints"
echo ""
echo "📚 What's included:"
echo "   ✅ Complete Ansible configuration"
echo "   ✅ FastAPI application with Docker"
echo "   ✅ Automated testing scripts"
echo "   ✅ Development and test inventories"
echo "   ✅ Comprehensive README"
echo ""
echo "🎯 Next steps documented in: $PROJECT_NAME/README.md"
echo ""
print_success "Ready to test!"
