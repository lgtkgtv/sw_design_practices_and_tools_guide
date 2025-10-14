## Context 

## 🔄 The Workflow for Terraform and Ansible 

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT WORKFLOW                           │
└─────────────────────────────────────────────────────────────────┘

PHASE 1: INFRASTRUCTURE (Terraform - Coming Next)
════════════════════════════════════════════════════
[Developer] → terraform plan → terraform apply
                                      │
                                      ├── Creates VPC
                                      ├── Creates EC2/GCE Instance
                                      ├── Creates Security Groups
                                      └── Outputs: instance_ip, ssh_key_path
                                                    │
                                                    ▼
                                              terraform.tfstate
                                                    │
                                                    ▼
                                        Extract outputs for Ansible

PHASE 2: CONFIGURATION (Ansible - You're Here!)
═══════════════════════════════════════════════
[Developer] → Update inventory with IPs
                    │
                    ▼
        ansible-playbook playbooks/site.yml
                    │
                    ├── [Role: common]
                    │    ├── OS updates
                    │    ├── User creation
                    │    ├── SSH hardening
                    │    └── Firewall setup
                    │
                    ├── [Role: docker]
                    │    ├── Install Docker
                    │    ├── Configure daemon
                    │    └── Add user to docker group
                    │
                    └── [Role: fastapi_app]
                         ├── Copy application code
                         ├── Build Docker image
                         ├── Start container
                         └── Verify health check
                                    │
                                    ▼
                    ✅ Running Application
                         │
                         ▼
          http://instance-ip:8000/health
```

---

## 🧪 Testing Your Ansible Setup (Before Terraform)

You can test these Ansible playbooks **locally** using Vagrant or Docker:   

**NOTE**:  This script `phase1/setup_complete_project.sh` will setup the entire project.  

***

***
**Ansible Playbook - Docker & FastAPI Deployment** project
***

# Ansible Playbook Tutorial: Docker & FastAPI Deployment

## Table of Contents
1. [Project Overview](#project-overview)
2. [Understanding the FastAPI Application](#understanding-the-fastapi-application)
3. [Ansible Fundamentals](#ansible-fundamentals)
4. [Project Structure Explained](#project-structure-explained)
5. [Ansible Roles Deep Dive](#ansible-roles-deep-dive)
6. [Playbooks and Orchestration](#playbooks-and-orchestration)
7. [Inventory Management](#inventory-management)
8. [Testing Strategy](#testing-strategy)
9. [Running the Deployment](#running-the-deployment)
10. [Troubleshooting Guide](#troubleshooting-guide)

---

## Project Overview

### What We Built

A **complete Infrastructure as Code (IaC) solution** that:
- Hardens a Linux server (Ubuntu 22.04)
- Installs Docker and container tools
- Deploys a FastAPI web application
- Provides health monitoring endpoints
- Is cloud-agnostic (works on AWS, GCP, or local Docker)

### End Goal

**Input:** Fresh Ubuntu server (physical, VM, or container)  
**Output:** Fully configured server running a containerized FastAPI application

### Why This Matters

Traditional deployment:
```bash
# SSH into server
ssh user@server
# Install packages manually
sudo apt install docker...
# Copy files manually
scp app.py server:/app/
# Configure everything manually
# Repeat for every server 😫
```

**With Ansible:**
```bash
ansible-playbook site.yml
# ✅ Done! Repeatable. Tested. Version-controlled.
```

---

## Understanding the FastAPI Application

### What is FastAPI?

FastAPI is a modern Python web framework for building APIs with:
- **Automatic API documentation** (Swagger UI at `/docs`)
- **Type safety** (using Python type hints)
- **High performance** (comparable to Node.js and Go)
- **Easy to learn** (if you know Python)

### Our Application Structure

```
ansible/files/fastapi_hello/
├── main.py           # Application code
├── requirements.txt  # Python dependencies
└── Dockerfile       # Container build instructions
```

### main.py - The Application Code

```python
from fastapi import FastAPI
import socket
import time

app = FastAPI(title="MediaShare API")

@app.get("/")
async def root():
    return {"message": "Welcome to MediaShare API"}

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "hostname": socket.gethostname(),
        "uptime_seconds": round(time.time() - START_TIME, 2)
    }
```

**Key concepts:**

1. **`@app.get("/health")`** - Decorator that says "when someone visits /health, run this function"
2. **`async def`** - Asynchronous function (handles multiple requests efficiently)
3. **Return dictionary** - FastAPI automatically converts to JSON

### Endpoints Explained

| Endpoint | Purpose | Used By |
|----------|---------|---------|
| `/` | Welcome message | Humans (sanity check) |
| `/health` | Detailed health status | Load balancers, monitoring tools |
| `/ready` | Kubernetes-style readiness | Container orchestrators |
| `/metadata` | Server/cloud information | Debugging, logging |
| `/docs` | Interactive API documentation | Developers testing the API |

**Example health response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-14T10:30:00",
  "hostname": "web-server-01",
  "environment": "production",
  "cloud_provider": "aws",
  "version": "1.0.0",
  "uptime_seconds": 3600.5
}
```

### Dockerfile - Multi-Stage Build

```dockerfile
# Stage 1: Builder
FROM python:3.11-slim as builder
RUN pip install --no-cache-dir uv
WORKDIR /app
COPY requirements.txt ./
RUN uv pip install --system --no-cache -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim
RUN groupadd -r appuser && useradd -r -g appuser appuser
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages ...
COPY main.py ./
USER appuser
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Why multi-stage?**
- **Stage 1** installs build tools (large image ~500MB)
- **Stage 2** copies only what's needed (final image ~150MB)
- **Result:** 70% smaller image, faster deployments

**Security features:**
1. **Non-root user** - Container runs as `appuser`, not `root`
2. **Minimal base** - Uses `slim` variant (fewer security vulnerabilities)
3. **No build tools** in final image (can't be used for attacks)

---

## Ansible Fundamentals

### Core Concepts

#### 1. Idempotency
**Definition:** Running the same operation multiple times produces the same result.

**Example:**
```yaml
- name: Create user alice
  user:
    name: alice
    state: present
```

- First run: Creates user alice ✅ **changed**
- Second run: User exists, nothing to do ✅ **ok**
- Third run: User exists, nothing to do ✅ **ok**

**Why it matters:** Safe to re-run playbooks in production without breaking things.

#### 2. Tasks
The fundamental unit of work in Ansible.

```yaml
- name: Install nginx              # Human-readable description
  apt:                             # Module name
    name: nginx                    # Module parameters
    state: present                 # Desired state
  become: yes                      # Run with sudo
```

#### 3. Modules
Pre-built functions that do specific things.

| Module | Purpose | Example |
|--------|---------|---------|
| `apt` | Install packages (Debian/Ubuntu) | `apt: name=nginx state=present` |
| `user` | Manage users | `user: name=alice state=present` |
| `file` | Create directories/files | `file: path=/app state=directory` |
| `copy` | Copy files to remote | `copy: src=app.py dest=/app/` |
| `service` | Start/stop services | `service: name=nginx state=started` |

#### 4. Roles
A way to organize related tasks, files, and templates.

**Think of a role as a "package" of functionality:**
```
roles/docker/
├── tasks/       # What to do (install Docker)
├── handlers/    # React to changes (restart Docker)
├── templates/   # Config file templates
└── files/       # Static files to copy
```

#### 5. Playbooks
Orchestrate multiple roles to achieve a goal.

```yaml
---
- name: Deploy Web Application
  hosts: webservers
  roles:
    - common        # Harden OS
    - docker        # Install Docker
    - nginx         # Install web server
    - myapp         # Deploy application
```

**Execution flow:**
1. Run `common` role on all hosts
2. Then run `docker` role
3. Then `nginx`
4. Finally `myapp`

#### 6. Inventory
List of servers to manage.

```yaml
# Simple inventory
webservers:
  hosts:
    web1:
      ansible_host: 192.168.1.10
    web2:
      ansible_host: 192.168.1.11
```

---

## Project Structure Explained

```
mediaahare-complete/
├── ansible/
│   ├── ansible.cfg              # Ansible behavior configuration
│   ├── inventories/             # Where to deploy
│   │   ├── dev/                 # Production inventories (AWS, GCP)
│   │   └── test/                # Local Docker testing
│   ├── roles/                   # What to deploy
│   │   ├── common/              # OS hardening
│   │   ├── docker/              # Container runtime
│   │   └── fastapi_app/         # Our application
│   ├── playbooks/site.yml                   # Master playbook
└── files/fastapi_hello/main.py          # Application code
```

### Common Commands

```bash
# Full deployment
./test_docker.sh

# Test endpoints
./test_api.sh

# Clean up
./cleanup.sh

# Run playbook manually
cd ansible
ansible-playbook playbooks/site.yml -i inventories/test/docker_hosts.yml

# Test connection
ansible all -i inventories/test/docker_hosts.yml -m ping

# Run with tags
ansible-playbook site.yml --tags docker

# Dry run
ansible-playbook site.yml --check

# Verbose output
ansible-playbook site.yml -vvv
```

### Variable Precedence (Low to High)

1. `group_vars/all.yml` - Applies to all hosts
2. `group_vars/groupname.yml` - Applies to specific group
3. Inventory file group vars - Group-level variables
4. Inventory file host vars - Host-specific variables
5. Command line `-e` - Highest priority

**Example:**
```bash
# Override any variable
ansible-playbook site.yml -e "app_version=2.0.0"
```

### Task Status Meanings

| Output | What It Means | Action Needed |
|--------|---------------|---------------|
| `changed` | Task made a change | ✅ Normal on first run |
| `ok` | Already in desired state | ✅ Normal on subsequent runs |
| `failed` | Task failed | ❌ Check error message |
| `skipped` | Condition not met | ✅ Normal (e.g., firewall disabled) |
| `ignored` | Failed but playbook continues | ⚠️ Check if intentional |
| `unreachable` | Cannot connect to host | ❌ Check network/SSH |

### Ansible Module Quick Reference

```yaml
# Package management
- apt:
    name: nginx
    state: present

# User management
- user:
    name: alice
    state: present
    groups: sudo

# File/directory management
- file:
    path: /app
    state: directory
    owner: alice
    mode: '0755'

# Copy files
- copy:
    src: app.py
    dest: /app/app.py

# Run commands
- command: ls -la /app

# Service management
- service:
    name: nginx
    state: started
    enabled: yes

# Docker container
- community.docker.docker_container:
    name: myapp
    image: myapp:latest
    state: started
    ports:
      - "8000:8000"

# Wait for port
- wait_for:
    port: 8000
    delay: 5
    timeout: 60

# HTTP request
- uri:
    url: http://localhost:8000/health
    status_code: 200
```

---

## Understanding the Testing Flow

### Visual Testing Workflow

```
Developer Machine                  Test Container (Docker)
═════════════════                  ═══════════════════════

┌──────────────┐                   ┌──────────────┐
│ Run          │                   │ Fresh        │
│ ./test_      │  SSH (port 2222)  │ Ubuntu       │
│ docker.sh    ├──────────────────→│ Container    │
└──────────────┘                   └──────────────┘
       │                                   │
       │                                   │
       ▼                                   ▼
┌──────────────┐                   ┌──────────────┐
│ Ansible      │   Execute Tasks   │ Install      │
│ Playbook     ├──────────────────→│ Packages     │
│              │                   │ Configure    │
└──────────────┘                   │ Deploy App   │
       │                           └──────────────┘
       │                                   │
       │                                   │
       ▼                                   ▼
┌──────────────┐                   ┌──────────────┐
│ Test API     │   HTTP Request    │ FastAPI      │
│ ./test_      ├──────────────────→│ Application  │
│ api.sh       │                   │ Running      │
└──────────────┘                   └──────────────┘
       │                                   │
       │                                   │
       ▼                                   ▼
┌──────────────┐                   ┌──────────────┐
│ ✅ Success   │                   │ Responds     │
│ All tests    │                   │ with JSON    │
│ passed!      │                   │              │
└──────────────┘                   └──────────────┘
```

### Step-by-Step Execution

```bash
# Step 1: Build Docker test image
$ ./test_docker.sh
🔨 Building Docker test image...
[+] Building 30.7s
```
**What happens:**
- Creates Ubuntu 22.04 container
- Installs SSH server
- Creates `ubuntu` user with password
- Exposes ports 22 and 8000

---

```bash
# Step 2: Start container
🚀 Starting container...
✅ Container started
⏳ Waiting for SSH...
```
**What happens:**
- Container starts in background
- SSH server initializes
- Waits 5 seconds for stability

---

```bash
# Step 3: Run Ansible playbook
🎯 Running Ansible playbook...

PLAY [Complete MediaShare Deployment]

TASK [Gathering Facts]
ok: [docker_test_vm]
```
**What happens:**
- Ansible connects via SSH (port 2222)
- Collects system information (OS, CPU, memory, etc.)
- Stores in `ansible_facts` variable

---

```bash
TASK [common : Update apt cache]
ok: [docker_test_vm]

TASK [common : Install essential packages]
changed: [docker_test_vm]
```
**What happens:**
- Updates package list (`apt update`)
- Installs required packages
- Shows `changed` because packages are new

---

```bash
TASK [docker : Install Docker]
changed: [docker_test_vm]

TASK [docker : Start Docker service]
changed: [docker_test_vm]
```
**What happens:**
- Installs Docker CE from official repo
- Starts Docker daemon
- Adds user to docker group

---

```bash
TASK [fastapi_app : Build Docker image]
changed: [docker_test_vm]
```
**What happens:**
- Copies Dockerfile, main.py, requirements.txt
- Runs `docker build` inside container
- Creates image `mediaahare/fastapi:test`
- Takes 2-3 minutes (downloads Python base image)

---

```bash
TASK [fastapi_app : Start FastAPI container]
changed: [docker_test_vm]

TASK [fastapi_app : Wait for health check]
FAILED - RETRYING: Wait for health check (12 retries left)
ok: [docker_test_vm]
```
**What happens:**
- Starts container from built image
- Application takes 5-10 seconds to start
- Retries health check every 5 seconds
- Succeeds when `/health` returns 200 OK

---

```bash
PLAY RECAP
docker_test_vm: ok=31 changed=17 failed=0
✅ Deployment complete!
```
**What this means:**
- ✅ All 31 tasks completed
- ✅ 17 made changes (first run)
- ✅ 0 failures
- ✅ Application is running

---

### Testing the Application

```bash
$ ./test_api.sh
1️⃣  Health Check:
{
    "status": "healthy",
    "timestamp": "2025-10-14T10:30:00",
    "hostname": "871a3d1a20e3",
    "environment": "testing",
    "cloud_provider": "docker-test",
    "version": "1.0.0-test",
    "uptime_seconds": 45.2
}
```

**What each field means:**

| Field | Meaning | Used By |
|-------|---------|---------|
| `status` | Application health | Load balancers, monitoring |
| `timestamp` | Current time (UTC) | Debugging, logging |
| `hostname` | Container ID | Identifying which instance |
| `environment` | dev/test/prod | Configuration selection |
| `cloud_provider` | aws/gcp/docker | Cloud-specific logic |
| `version` | App version | Deployment tracking |
| `uptime_seconds` | Time since startup | Performance monitoring |

---

## Advanced Topics

### 1. Understanding Ansible Variables

#### Where Variables Come From

```yaml
# 1. Inventory file
hosts:
  web1:
    ansible_host: 192.168.1.10
    custom_var: value1           # Host variable

# 2. Group vars file (group_vars/all.yml)
app_directory: /opt/myapp

# 3. Role defaults (roles/myrole/defaults/main.yml)
app_port: 8000

# 4. Role vars (roles/myrole/vars/main.yml)
internal_config: secret

# 5. Playbook vars
- hosts: all
  vars:
    app_version: 1.0.0

# 6. Command line
ansible-playbook site.yml -e "app_version=2.0.0"
```

#### Using Variables in Tasks

```yaml
- name: Create directory
  file:
    path: "{{ app_directory }}/logs"    # Variable interpolation
    state: directory

- name: Install package
  apt:
    name: "{{ item }}"                  # Loop variable
  loop:
    - nginx
    - postgresql

- name: Debug variable
  debug:
    msg: "Installing version {{ app_version | default('1.0.0') }}"
    #                                    ^^^^^^^^^^^^^^^^
    #                                    Filter: use default if undefined
```

---

### 2. Handlers in Detail

**Problem:** Service needs restart after config change

**Bad approach:**
```yaml
- name: Update nginx config
  copy:
    src: nginx.conf
    dest: /etc/nginx/nginx.conf

- name: Restart nginx
  service:
    name: nginx
    state: restarted    # Restarts EVERY time, even if config unchanged
```

**Good approach (handlers):**
```yaml
# tasks/main.yml
- name: Update nginx config
  copy:
    src: nginx.conf
    dest: /etc/nginx/nginx.conf
  notify: restart nginx    # Only notifies if file changed

# handlers/main.yml
- name: restart nginx
  service:
    name: nginx
    state: restarted       # Only runs if notified
```

**Benefits:**
- ✅ Only restarts when needed (idempotent)
- ✅ Multiple tasks can notify same handler (restarts once)
- ✅ Handlers run at end (all config applied before restart)

---

### 3. Conditional Execution

```yaml
# Run only on Ubuntu
- name: Install package
  apt:
    name: nginx
  when: ansible_os_family == "Debian"

# Run only in production
- name: Enable firewall
  ufw:
    state: enabled
  when: environment == "production"

# Run only if file exists
- name: Backup config
  copy:
    src: /etc/app/config.yml
    dest: /backup/
  when: ansible_stat.exists
  
# Multiple conditions (AND)
- name: Complex condition
  debug:
    msg: "Running on production Ubuntu"
  when:
    - ansible_os_family == "Debian"
    - environment == "production"
    - app_version is version('2.0', '>=')
```

---

### 4. Loops and Iteration

```yaml
# Simple loop
- name: Create users
  user:
    name: "{{ item }}"
    state: present
  loop:
    - alice
    - bob
    - charlie

# Loop with dictionaries
- name: Create users with details
  user:
    name: "{{ item.name }}"
    groups: "{{ item.groups }}"
    shell: "{{ item.shell }}"
  loop:
    - { name: alice, groups: sudo, shell: /bin/bash }
    - { name: bob, groups: docker, shell: /bin/zsh }

# Loop with register (capture results)
- name: Check multiple ports
  wait_for:
    port: "{{ item }}"
    timeout: 5
  loop: [80, 443, 8000]
  register: port_check
  ignore_errors: yes

- name: Show which ports are open
  debug:
    msg: "Port {{ item.item }} is {{ 'open' if item.failed == false else 'closed' }}"
  loop: "{{ port_check.results }}"
```

---

### 5. Templates (Jinja2)

Templates allow dynamic configuration files.

**Example: docker-compose.yml.j2**

```yaml
version: '3.8'

services:
  app:
    image: {{ docker_image_name }}:{{ docker_image_tag }}
    container_name: {{ container_name }}
    ports:
      - "{{ fastapi_port }}:8000"
    environment:
      - ENVIRONMENT={{ environment }}
      - CLOUD_PROVIDER={{ cloud_provider }}
    {% if enable_debug %}
      - DEBUG=true
    {% endif %}
    
    deploy:
      resources:
        limits:
          cpus: '{{ container_cpu_limit }}'
          memory: {{ container_memory_limit }}
```

**Usage:**
```yaml
- name: Create docker-compose file
  template:
    src: docker-compose.yml.j2
    dest: /opt/app/docker-compose.yml
```

**Variables get replaced:**
- `{{ docker_image_name }}` → `mediaahare/fastapi`
- `{{ fastapi_port }}` → `8000`
- Conditional blocks only included if true

---

### 6. Error Handling

```yaml
# Ignore errors and continue
- name: Try to stop service
  service:
    name: oldapp
    state: stopped
  ignore_errors: yes

# Fail with custom message
- name: Check if file exists
  stat:
    path: /etc/app/config.yml
  register: config_file
  failed_when: not config_file.stat.exists

# Changed when (control when task reports "changed")
- name: Run script
  command: /usr/local/bin/deploy.sh
  register: result
  changed_when: "'Updated' in result.stdout"

# Block with rescue (try/catch)
- block:
    - name: Try to deploy
      command: deploy.sh
  rescue:
    - name: Rollback on failure
      command: rollback.sh
  always:
    - name: Send notification
      debug:
        msg: "Deployment attempted"
```

---

## Real-World Scenarios

### Scenario 1: Updating Application Code

**Problem:** You fixed a bug in `main.py` and want to deploy.

**Solution:**
```bash
# 1. Edit the code
vim ansible/files/fastapi_hello/main.py

# 2. Re-run deployment
cd ansible
ansible-playbook playbooks/site.yml -i inventories/test/docker_hosts.yml

# What happens:
# - Most tasks show "ok" (already done)
# - "Copy application files" shows "changed"
# - Docker image rebuilds (force_source: yes)
# - Container restarts with new code
# - Health check verifies it's working
```

**Time:** ~2 minutes (vs 10 minutes for full deployment)

---

### Scenario 2: Adding a New Package

**Problem:** Application now needs `redis-tools`.

**Solution:**
```yaml
# Edit roles/common/tasks/main.yml
- name: Install essential packages
  apt:
    name:
      - curl
      - wget
      - redis-tools    # Add this line
    state: present
```

```bash
# Re-run playbook
ansible-playbook site.yml -i inventories/test/docker_hosts.yml

# Only the "Install packages" task will show "changed"
```

---

### Scenario 3: Testing on Multiple Servers

**Problem:** Need to deploy to 3 servers.

**Solution:**
```yaml
# inventories/prod/hosts.yml
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 192.168.1.10
        web2:
          ansible_host: 192.168.1.11
        web3:
          ansible_host: 192.168.1.12
```

```bash
# Deploy to all at once
ansible-playbook site.yml -i inventories/prod/hosts.yml

# Or deploy to one at a time (safer)
ansible-playbook site.yml --limit web1
ansible-playbook site.yml --limit web2
ansible-playbook site.yml --limit web3
```

---

### Scenario 4: Different Config for Dev vs Prod

**Problem:** Dev uses port 8000, prod uses port 80.

**Solution:**
```yaml
# group_vars/dev.yml
fastapi_port: 8000
enable_firewall: false
app_version: latest

# group_vars/prod.yml
fastapi_port: 80
enable_firewall: true
app_version: 1.0.0
```

Same playbook, different variables based on inventory.

---

## Best Practices

### 1. Role Organization

✅ **Good:**
```
roles/myapp/
├── tasks/
│   ├── main.yml        # Main entry point
│   ├── install.yml     # Installation tasks
│   └── configure.yml   # Configuration tasks
├── handlers/
│   └── main.yml
├── templates/
│   └── config.yml.j2
├── files/
│   └── app.tar.gz
└── defaults/
    └── main.yml        # Default variables
```

❌ **Bad:**
```
roles/myapp/
└── tasks/
    └── main.yml        # Everything in one huge file
```

---

### 2. Variable Naming

✅ **Good:**
```yaml
app_port: 8000                # Clear, namespaced
mysql_root_password: secret   # Component prefix
enable_monitoring: true       # Boolean clearly named
```

❌ **Bad:**
```yaml
port: 8000                    # Too generic (conflicts possible)
password: secret              # Which password?
monitoring: yes               # Ambiguous (enabled? installed?)
```

---

### 3. Task Names

✅ **Good:**
```yaml
- name: Install nginx web server
- name: Create application user account
- name: Start Docker daemon service
```

❌ **Bad:**
```yaml
- name: Install package
- name: Create user
- name: Start service
```

Task names should be **specific** and **descriptive**.

---

### 4. Idempotency

✅ **Good (Idempotent):**
```yaml
- name: Ensure nginx is installed
  apt:
    name: nginx
    state: present    # "Make sure it exists"

- name: Ensure service is running
  service:
    name: nginx
    state: started    # "Make sure it's running"
```

❌ **Bad (Not Idempotent):**
```yaml
- name: Install nginx
  command: apt install nginx    # Fails if already installed!

- name: Start nginx
  command: service nginx start  # Always runs, always "changed"
```

**Rule:** Use modules (apt, service, file) instead of command when possible.

---

### 5. Security

✅ **Good:**
```yaml
# Store secrets in vault
# ansible-vault encrypt secrets.yml

# Use variables for sensitive data
mysql_password: "{{ vault_mysql_password }}"

# Don't commit secrets to git
# Add to .gitignore:
# *vault*
# *.pem
```

❌ **Bad:**
```yaml
# Hardcoded passwords
mysql_password: "SuperSecret123!"

# Passwords in git history
# SSH keys in repository
```

---

## Glossary

**Ansible** - Automation tool for configuration management, deployment, and orchestration.

**Idempotency** - Property where running the same operation multiple times has the same effect as running it once.

**Inventory** - File listing servers (hosts) that Ansible manages.

**Module** - Pre-built Ansible function that performs a specific task (e.g., `apt`, `copy`, `service`).

**Playbook** - YAML file containing a series of plays (sets of tasks).

**Role** - Organized collection of tasks, handlers, templates, and files for a specific purpose.

**Task** - Single unit of work (e.g., "install nginx", "copy file").

**Handler** - Special task that only runs when notified by another task.

**Facts** - System information automatically collected by Ansible (OS, IP address, memory, etc.).

**Template** - File with variables that Ansible fills in (uses Jinja2 syntax).

**Vault** - Ansible feature for encrypting sensitive data.

**Become** - Ansible privilege escalation (like `sudo`).

---

## Summary

### What We Built

A **production-ready deployment system** that:
- ✅ Provisions servers from scratch
- ✅ Installs and configures Docker
- ✅ Deploys containerized FastAPI application
- ✅ Provides health monitoring
- ✅ Is repeatable and testable
- ✅ Works across clouds (AWS, GCP, Azure)

### Key Principles

1. **Infrastructure as Code** - Everything in version control
2. **Idempotency** - Safe to run multiple times
3. **Modularity** - Reusable roles
4. **Testing** - Validate locally before production
5. **Security** - Least privilege, automated updates

### Your Progress

✅ Phase 1 Complete: Ansible deployment working  
⏭️  Phase 2 Next: Terraform infrastructure provisioning

---

## Ready for Next Phase?

You now understand:
- How Ansible works (roles, tasks, playbooks)
- How the FastAPI application is structured
- How testing validates deployments
- How to troubleshoot common issues

**Next:** We'll create Terraform modules to provision the infrastructure (VPC, EC2, RDS) that this Ansible playbook will configure.

The workflow will be:
```
Terraform → Creates infrastructure (servers, networks, databases)
    ↓
Ansible → Configures servers and deploys application
```

Ready to proceed with **Option A: Terraform**? 🚀               # How to orchestrate
│   │   └── site.yml             # Master playbook
│   └── files/                   # Application code
│       └── fastapi_hello/
├── test_docker.sh               # One-command test
├── test_api.sh                  # Verify endpoints
└── cleanup.sh                   # Clean Docker resources
```

### ansible.cfg - Configuration File

```ini
[defaults]
inventory = ./inventories/dev       # Default inventory location
roles_path = ./roles                # Where to find roles
host_key_checking = False           # Don't verify SSH fingerprints
timeout = 30                        # SSH timeout
stdout_callback = yaml              # Pretty output format

[privilege_escalation]
become = True                       # Use sudo
become_method = sudo                # How to elevate privileges
```

**Key settings explained:**

- **`host_key_checking = False`** - In development, servers come and go. In production, set to `True` for security.
- **`roles_path = ./roles`** - Tells Ansible where to find role directories
- **`become = True`** - Most tasks need root privileges (installing packages, etc.)

---

## Ansible Roles Deep Dive

### Role 1: common - OS Hardening

**Purpose:** Prepare a fresh Ubuntu server with security and baseline configuration.

**Location:** `ansible/roles/common/tasks/main.yml`

#### Task Breakdown

```yaml
- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
```
**What it does:** Runs `apt update` (refreshes package list)  
**Why cache_valid_time:** Only updates if cache is older than 1 hour (efficiency)

---

```yaml
- name: Install essential packages
  apt:
    name:
      - curl
      - wget
      - git
      - vim
      - unattended-upgrades    # Automatic security updates
      - tzdata                 # Timezone data
    state: present
```
**What it does:** Installs common tools and security packages  
**Idempotent:** If already installed, does nothing

---

```yaml
- name: Create application group
  group:
    name: appuser
    system: yes
    state: present

- name: Create application user
  user:
    name: appuser
    group: appuser
    shell: /bin/bash
    create_home: yes
    system: yes
```
**What it does:** Creates a dedicated user for running the application  
**Why not root?** Security principle of least privilege  
**system: yes** - Creates a system account (UID < 1000)

---

```yaml
- name: Create application directory
  file:
    path: /opt/mediaahare
    state: directory
    owner: appuser
    group: appuser
    mode: '0755'
```
**What it does:** Creates `/opt/mediaahare` directory  
**Permissions (0755):**
- Owner (appuser): read, write, execute (7)
- Group (appuser): read, execute (5)
- Others: read, execute (5)

---

### Role 2: docker - Container Runtime

**Purpose:** Install Docker CE and configure it for production use.

**Location:** `ansible/roles/docker/tasks/main.yml`

#### Task Breakdown

```yaml
- name: Remove old Docker versions
  apt:
    name:
      - docker
      - docker-engine
      - docker.io
    state: absent
```
**What it does:** Removes conflicting old Docker packages  
**Why:** Ubuntu repos have outdated Docker; we want the official version

---

```yaml
- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present
```
**What it does:** Adds Docker's official signing key  
**Why:** Verifies package authenticity (prevents malicious packages)

---

```yaml
- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present
```
**What it does:** Adds Docker's official package repository  
**`{{ ansible_distribution_release }}`** - Ansible variable (e.g., "jammy" for Ubuntu 22.04)

---

```yaml
- name: Install Docker
  apt:
    name:
      - docker-ce                    # Docker engine
      - docker-ce-cli                # Docker command-line
      - docker-compose-plugin        # Docker Compose v2
      - python3-docker               # Python Docker SDK (for Ansible)
      - python3-requests             # HTTP library (dependency)
    state: present
```
**What it does:** Installs Docker and dependencies  
**python3-docker:** Required for Ansible's `docker_container` module

---

```yaml
- name: Add user to docker group
  user:
    name: appuser
    groups: docker
    append: yes
```
**What it does:** Allows `appuser` to run Docker commands without sudo  
**append: yes** - Adds to group without removing from other groups

---

```yaml
- name: Configure Docker daemon
  copy:
    dest: /etc/docker/daemon.json
    content: |
      {
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "10m",
          "max-file": "3"
        }
      }
  notify: restart docker
```
**What it does:** Configures Docker log rotation  
**Log rotation:** Prevents logs from filling disk (max 3 files × 10MB = 30MB)  
**`notify: restart docker`** - If file changes, trigger handler to restart Docker

---

#### Handlers

**Location:** `ansible/roles/docker/handlers/main.yml`

```yaml
- name: restart docker
  service:
    name: docker
    state: restarted
```

**What are handlers?**
- Special tasks that only run when "notified"
- Run at the end of the playbook (after all tasks)
- Prevent unnecessary service restarts

**Flow:**
1. Task changes `/etc/docker/daemon.json`
2. Task notifies `restart docker` handler
3. All tasks complete
4. Handler runs (Docker restarts once)

**Why not restart immediately?**
- Multiple tasks might change config
- Only restart once at the end (efficiency)

---

### Role 3: fastapi_app - Application Deployment

**Purpose:** Build Docker image and deploy the FastAPI application.

**Location:** `ansible/roles/fastapi_app/tasks/main.yml`

#### Task Breakdown

```yaml
- name: Copy application files
  copy:
    src: "{{ playbook_dir }}/../files/fastapi_hello/{{ item }}"
    dest: "/opt/mediaahare/app/{{ item }}"
    owner: appuser
    mode: '0644'
  loop:
    - main.py
    - requirements.txt
    - Dockerfile
```
**What it does:** Copies application files from local machine to server  
**`{{ playbook_dir }}`** - Ansible variable: directory containing the playbook  
**`loop:`** - Runs task once for each item in list  
**mode: '0644'** - Read/write for owner, read-only for others

---

```yaml
- name: Build Docker image
  community.docker.docker_image:
    name: mediaahare/fastapi:test
    source: build
    build:
      path: /opt/mediaahare/app
    state: present
    force_source: yes
```
**What it does:** Builds Docker image from Dockerfile  
**`force_source: yes`** - Rebuild even if image exists (captures code changes)  
**Module:** `community.docker.docker_image` (from community.docker collection)

---

```yaml
- name: Start FastAPI container
  community.docker.docker_container:
    name: fastapi_app
    image: mediaahare/fastapi:test
    state: started
    restart_policy: unless-stopped
    ports:
      - "8000:8000"
    env:
      ENVIRONMENT: "testing"
      CLOUD_PROVIDER: "docker-test"
```
**What it does:** Runs the Docker container  
**`restart_policy: unless-stopped`** - Container auto-restarts after reboot  
**`ports: "8000:8000"`** - Maps host port 8000 to container port 8000  
**`env:`** - Sets environment variables inside container

---

```yaml
- name: Wait for health check
  uri:
    url: "http://localhost:8000/health"
    status_code: 200
  register: result
  until: result.status == 200
  retries: 12
  delay: 5
```
**What it does:** Waits for application to start successfully  
**Retries:** Tries up to 12 times, waiting 5 seconds between attempts (60 seconds total)  
**Why:** Application takes time to start (download packages, initialize)

---

## Playbooks and Orchestration

### Master Playbook: site.yml

**Location:** `ansible/playbooks/site.yml`

```yaml
---
- name: Complete MediaShare Deployment
  hosts: all                    # Run on all hosts in inventory
  become: yes                   # Use sudo
  gather_facts: yes             # Collect system information
  
  pre_tasks:
    - name: Display deployment info
      debug:
        msg:
          - "Deploying to: {{ inventory_hostname }}"
    
    - name: Wait for connection
      wait_for_connection:
        timeout: 300
  
  roles:
    - common                    # Step 1: OS hardening
    - docker                    # Step 2: Install Docker
    - fastapi_app               # Step 3: Deploy app
  
  post_tasks:
    - name: Wait for Docker to stabilize
      pause:
        seconds: 10
    
    - name: Final health check
      uri:
        url: "http://localhost:8000/health"
      register: health
      retries: 12
      until: health.status == 200
```

### Execution Flow

```
┌─────────────────────────────────────────────┐
│  ansible-playbook site.yml                  │
└─────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│  1. PRE-TASKS                                │
│     ├─ Display deployment info               │
│     └─ Wait for SSH connection               │
└─────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│  2. ROLE: common                             │
│     ├─ Update packages                       │
│     ├─ Install essentials                    │
│     ├─ Create user/group                     │
│     └─ Create directories                    │
└─────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│  3. ROLE: docker                             │
│     ├─ Remove old Docker                     │
│     ├─ Add Docker repository                 │
│     ├─ Install Docker                        │
│     └─ Configure daemon                      │
└─────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│  4. ROLE: fastapi_app                        │
│     ├─ Copy application files                │
│     ├─ Build Docker image                    │
│     ├─ Start container                       │
│     └─ Wait for health check                 │
└─────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│  5. HANDLERS (if notified)                   │
│     └─ Restart Docker                        │
└─────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│  6. POST-TASKS                               │
│     ├─ Wait for stability                    │
│     ├─ Final health check                    │
│     └─ Display success message               │
└─────────────────────────────────────────────┘
```

---

## Inventory Management

### Test Inventory (Docker)

**Location:** `ansible/inventories/test/docker_hosts.yml`

```yaml
all:
  children:
    docker_instances:
      hosts:
        docker_test_vm:
          ansible_host: localhost        # Connect to localhost
          ansible_port: 2222              # SSH on port 2222
          ansible_user: ubuntu            # Login as ubuntu
          ansible_password: ubuntu        # Password auth (testing only!)
          cloud_provider: docker-test
          environment: testing
      
      vars:                               # Variables for all hosts
        app_directory: /opt/mediaahare
        fastapi_port: 8000
        enable_firewall: false            # Don't enable in Docker
```

**Structure explained:**

```
all                        # Root group (contains everything)
└── children
    └── docker_instances   # Group of Docker test VMs
        ├── hosts          # Individual servers
        │   └── docker_test_vm
        └── vars           # Variables shared by all hosts in group
```

### Production Inventory (AWS)

**Location:** `ansible/inventories/dev/aws_hosts.yml`

```yaml
all:
  children:
    aws_instances:
      hosts:
        aws_app_server:
          ansible_host: REPLACE_WITH_EC2_IP
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/mediaahare-aws.pem
          cloud_provider: aws
          aws_region: us-east-1
      vars:
        environment: production
        enable_firewall: true              # Enable in production!
```

**Key differences from test:**
- Uses SSH key instead of password
- Firewall enabled
- Different variables (production vs testing)

### Group Variables

**Location:** `ansible/inventories/dev/group_vars/all.yml`

```yaml
---
app_name: mediaahare
app_user: appuser
app_directory: /opt/mediaahare
enable_firewall: true
```

**What are group_vars?**
- Variables applied to all hosts in a group
- Shared configuration
- Can be overridden in inventory or command line

**Precedence (lowest to highest):**
1. group_vars/all.yml
2. group_vars/groupname.yml
3. inventory host_vars
4. inventory host variables
5. Command line `-e` extra vars

---

## Testing Strategy

### Local Testing with Docker

**Why test locally first?**
- ✅ **Fast**: Seconds to create/destroy test VMs
- ✅ **Free**: No cloud costs
- ✅ **Safe**: Can't break production
- ✅ **Repeatable**: Identical environment every time

### Test Scripts

#### 1. test_docker.sh - Complete Deployment Test

```bash
#!/bin/bash
# 1. Build test container image
docker build -t ansible-test-ubuntu ...

# 2. Start test container
docker run -d --name ansible-test-vm ...

# 3. Run Ansible playbook
cd ansible
ansible-playbook playbooks/site.yml -i inventories/test/docker_hosts.yml
```

**What it tests:**
- ✅ All tasks execute successfully
- ✅ Roles work in correct order
- ✅ Application starts and passes health check
- ✅ No syntax errors or missing dependencies

#### 2. test_api.sh - Endpoint Verification

```bash
#!/bin/bash
curl http://localhost:8000/health
curl http://localhost:8000/
curl http://localhost:8000/metadata
curl http://localhost:8000/ready
```

**What it tests:**
- ✅ Application is responding
- ✅ All endpoints return expected data
- ✅ No 500 errors
- ✅ JSON formatting is correct

#### 3. cleanup.sh - Clean Test Environment

```bash
#!/bin/bash
docker stop ansible-test-vm
docker rm ansible-test-vm
docker rmi ansible-test-ubuntu
```

**When to use:**
- Before starting fresh test
- After completing testing
- When troubleshooting issues

### Testing Checklist

```
□ Run ./cleanup.sh to start fresh
□ Run ./test_docker.sh (should take 5-10 minutes)
□ Verify no fatal errors in output
□ Run ./test_api.sh to test endpoints
□ Check all endpoints return 200 OK
□ Re-run ansible-playbook to test idempotency
□ Verify second run shows mostly "ok" not "changed"
```

---

## Running the Deployment

### First-Time Setup

```bash
# 1. Navigate to project
cd mediaahare-complete

# 2. Clean any previous tests
./cleanup.sh

# 3. Run complete deployment
./test_docker.sh

# Expected output:
# ✅ Image built
# ✅ Container started
# ✅ Ansible playbook completes (31 tasks)
# ✅ Deployment complete!
```

### Subsequent Runs (Testing Idempotency)

```bash
cd ansible
ansible-playbook playbooks/site.yml -i inventories/test/docker_hosts.yml

# Expected on second run:
# - Most tasks show "ok" instead of "changed"
# - Completes much faster (~2 minutes vs 10 minutes)
# - No errors
```

### Understanding Ansible Output

```yaml
TASK [docker : Install Docker]
changed: [docker_test_vm]
```

**Status meanings:**

| Status | Meaning | First Run | Second Run |
|--------|---------|-----------|------------|
| **changed** | Made a change | Common | Rare |
| **ok** | Already correct | Some | Most |
| **failed** | Task failed | ❌ Stop | ❌ Stop |
| **skipped** | Condition not met | Some | Some |
| **ignored** | Failed but continued | Rare | Rare |

**Good first run:**
```
PLAY RECAP
docker_test_vm: ok=31 changed=17 unreachable=0 failed=0 skipped=0 ignored=1
```

**Good second run:**
```
PLAY RECAP
docker_test_vm: ok=30 changed=1 unreachable=0 failed=0 skipped=0 ignored=1
```

### Manual Commands

```bash
# Test single role
ansible-playbook site.yml --tags docker

# Skip a role
ansible-playbook site.yml --skip-tags common

# Dry run (check mode)
ansible-playbook site.yml --check

# Very verbose output (debugging)
ansible-playbook site.yml -vvv

# Run on specific host
ansible-playbook site.yml --limit docker_test_vm
```

---

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. "Cannot connect to Docker daemon"

**Error:**
```
Error: Cannot connect to the Docker daemon
```

**Solution:**
```bash
# Start Docker
sudo systemctl start docker

# Verify it's running
docker ps

# If still fails, restart Docker Desktop (macOS/Windows)
```

---

#### 2. "Ansible connection failed"

**Error:**
```
fatal: [docker_test_vm]: UNREACHABLE! => 
  msg: Failed to connect to the host via ssh
```

**Solutions:**
```bash
# 1. Wait for SSH to start
sleep 10

# 2. Test SSH manually
ssh -p 2222 ubuntu@localhost
# Password: ubuntu

# 3. Check container is running
docker ps | grep ansible-test-vm

# 4. Restart container
docker restart ansible-test-vm
```

---

#### 3. "Port already in use"

**Error:**
```
Error: bind: address already in use (port 8000)
```

**Solution:**
```bash
# Find what's using the port
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or clean up everything
./cleanup.sh
```

---

#### 4. "Module not found: community.docker"

**Error:**
```
ERROR! couldn't resolve module/action 'community.docker.docker_container'
```

**Solution:**
```bash
# Install Ansible collections
ansible-galaxy collection install community.docker community.general

# Verify installation
ansible-galaxy collection list | grep docker
```

---

#### 5. "Permission denied (publickey)"

**Error:**
```
Permission denied (publickey,password)
```

**Solutions:**
```bash
# For Docker testing - verify password in inventory
# inventories/test/docker_hosts.yml should have:
ansible_password: ubuntu

# For production - verify SSH key
chmod 600 ~/.ssh/mediaahare-aws.pem
ssh -i ~/.ssh/mediaahare-aws.pem ubuntu@<IP>
```

---

#### 6. "Health check failed"

**Error:**
```
TASK [Wait for health check]
fatal: [docker_test_vm]: FAILED! => 
  msg: Connection refused
```

**Debugging steps:**
```bash
# 1. Check if container is running
docker exec ansible-test-vm docker ps

# 2. Check application logs
docker exec ansible-test-vm docker logs fastapi_app

# 3. Try curl inside container
docker exec ansible-test-vm curl http://localhost:8000/health

# 4. Check if port is mapped
docker port ansible-test-vm
```

---

### Debugging Commands

```bash
# View Ansible facts
ansible all -i inventories/test/docker_hosts.yml -m setup

# Test single task
ansible all -i inventories/test/docker_hosts.yml -m ping

# Check syntax
ansible-playbook playbooks/site.yml --syntax-check

# List all tasks
ansible-playbook playbooks/site.yml --list-tasks

# List all hosts
ansible-playbook playbooks/site.yml --list-hosts

# See which files will be used
ansible-playbook playbooks/site.yml --list-tags
```

---

## Key Takeaways

### What You've Learned

✅ **Ansible Fundamentals**
- Roles, tasks, handlers, playbooks
- Inventory management
- Idempotency and why it matters

✅ **Infrastructure as Code**
- Version-controlled infrastructure
- Repeatable deployments
- Documentation through code

✅ **Docker Deployment**
- Multi-stage builds
- Container security (non-root user)
- Health checks and monitoring

✅ **FastAPI Applications**
- RESTful API design
- Automatic documentation
- Production-ready patterns

✅ **Testing Strategies**
- Local testing before cloud
- Idempotency verification
- Endpoint testing

### Production Readiness Checklist

Before deploying to production:

```
□ Test playbook locally (Docker)
□ Verify idempotency (run twice, check "ok" vs "changed")
□ Test all API endpoints
□ Update inventories with production IPs
□ Change passwords/use SSH keys
□ Enable firewall (enable_firewall: true)
□ Review security settings
□ Set up monitoring and alerts
□ Document any custom configurations
□ Test rollback procedures
```

### Next Steps

Now that you understand Ansible deployment, you're ready for:

1. **Terraform** - Provision the infrastructure (VPC, EC2, RDS)
2. **Database Integration** - Add PostgreSQL and Redis
3. **CI/CD** - Automate testing and deployment
4. **Monitoring** - Add CloudWatch/Stackdriver
5. **Scaling** - Load balancers, auto-scaling groups

---

## Quick Reference

### File Locations

```
ansible/
├── ansible.cfg                          # Configuration
├── inventories/test/docker_hosts.yml    # Test inventory
├── roles/common/tasks/main.yml          # OS hardening
├── roles/docker/tasks/main.yml          # Docker install
├── roles/fastapi_app/tasks/main.yml     # App deployment
├── playbooks/
