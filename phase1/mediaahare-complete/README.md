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
