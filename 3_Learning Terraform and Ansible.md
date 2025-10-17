# Prompt for Learning Terraform and Ansible: 

## Terrform (Infrastructure Provisioning) 
```
Use Cases:
  Building a VPC, 
  creating an AWS RDS database, 
  provisioning a Google Compute Engine VM.

Use Terraform for Infrastructure Provisioning:
  Provision the AWS or GCP environment (VPC, subnets, security groups, load balancers).
  Create your compute resources (e.g., EC2 instances or Google Compute Engine VMs).
  Provision supporting services (Database, Secret Manager, S3 buckets, etc.).

Result: 
  Empty, networked, and secure-by-default cloud resources.
```

## Ansible (Install, configure, and manage the software and environment inside the resource) 
```
Use Cases:
  Installing Python/uv, deploying your FASTAPI code, configuring firewall rules, restarting a service.

Use Ansible for Software Configuration and Hardening:

  Target the VMs provisioned by Terraform.
  Install necessary operating system packages and dependencies.
  Use your preferred tool, uv, to set up the Python environment and install your FastAPI dependencies.
  Deploy the application code and configure the web server (e.g., Gunicorn/Uvicorn behind Nginx).
  Configure logging and set up monitoring agents.

Result: A running, fully configured, and secure FastAPI application
```

## Requirements:

I want to design a cloud based RESTful "Photo/Video/Blog/Documents Sharing" Web Application Service involving user authentication, admin accounts and the actual content sharing application.    

Want to develop a standards based, secure and scalable service.  

I favor using FastAPI, Postgres, Redis at the backend and a NEXTJS/React based fronend. Use these as guidelines, but you as an expert can decide to use better architecture, better frameworks, better design patterns. Explain me your thinking and the design patterns/architecture you decide to choose. Performance, Hosting Cost, Security, Scaling, Code Maintainability, Code Simplicity etc metrix comes to mind.    

Document the infrastructure needs during different product lifecycles like app development, testing, deployment and maintainance.  

You will present me 2 designs, One for AWS and another one for Google Cloud. This is because I want to deploy both to AWS and Google Cloud.   

Make appropriate assumptions and document them for VPC, subnets, security groups, load balancers, API Gateways, Secure Vault / Secret management, and use of docker/kubernetes etc.   

For both AWS and Google Cloud based designs, you will explain to me the infrstructure requirements and corresponding configuration management requirements.   

Once these requirements are refined, let us create two  tutorials     
  1) Tutorial explaining - How to provision the infrastructure using Terrform for both AWS and GCP.  
  2) Tutorial explaining - How to configure and security harden the infrstructure and the software using Ansible.   

NOTE: 
* Will like to have common Terrform and Ansible scripts to work with either the AWS or GCP cloud and also work on a local Ubuntu instance for developer testing.  
* When possible, explain the differences between the AWS and GCP solutions in a side by side manner for easy corelation.  



