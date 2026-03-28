# AWS Production Infrastructure Blueprint (Terraform + Ansible + Docker)

This project demonstrates how to provision and operate a production-style cloud environment on AWS using Terraform and Ansible, and deploy a containerized application using Docker.

It extends a containerized application (Project 2) into a real-world infrastructure setup, including secure networking, automation, and centralized logging.

Focus areas:
- Infrastructure as Code
- Configuration Management
- Secure Networking (Bastion + Private Subnet)
- Idempotent Automation
- Observability with CloudWatch

## Architecture

User → Bastion Host → Private EC2 → Dockerized Application
                           ↓
                    CloudWatch Logs

## Tech Stack

### Infrastructure
- AWS (EC2, VPC, IAM, CloudWatch)
- Terraform (Infrastructure as Code)

### Configuration
- Ansible (Role-based automation)

### Application
- Docker
- FastAPI (from Project 2)

### Networking
- Public & Private Subnets
- NAT Instance
- Bastion Host


## Engineering Highlights

- **Private Subnet Architecture** — Application runs in private EC2 with no direct internet access
- **Bastion Host Access** — Secure SSH access via jump host
- **NAT Instance Configuration** — Enabled outbound internet for private instances using iptables
- **Idempotent Ansible Roles** — Structured automation into nat, docker, app, and cloudwatch roles
- **Dockerized Deployment** — Pulled and deployed containerized FastAPI app on EC2
- **CloudWatch Integration** — Centralized log collection from EC2 instances
- **IAM Debugging** — Resolved real-world permission issues for CloudWatch logging
- **Environment Separation** — Managed dev/stage environments using Terraform state isolation


## Project Structure

terraform/
ansible/
  roles/
    nat/
    docker/
    app/
    cloudwatch/

## Deployment Flow

### 1. Provision Infrastructure
terraform init
terraform apply -var-file="dev.tfvars"

### 2. Configure and Deploy
ansible-playbook -i inventory.ini playbook.yml

### 3. Verify Application
curl localhost:8080

## Demo

![Demo](/demo/demo.gif)

Shows:
- Terraform provisioning
- Ansible automation
- SSH via bastion
- Application running
- CloudWatch logs

## Failure Scenarios & Debugging

- NAT misconfiguration → Private EC2 had no internet access
- IAM permission errors → CloudWatch logs not delivered
- Port conflicts → Docker container failed to start
- Terraform state confusion → Wrong environment modified

Each issue was debugged and resolved during setup.

## Limitations

- No CI/CD pipeline
- No HTTPS / TLS
- No load balancer (ALB)
- No autoscaling
- No secrets management

## Future Improvements

- Add Application Load Balancer (ALB)
- Introduce CI/CD pipeline (GitHub Actions)
- Replace NAT instance with NAT Gateway
- Add monitoring (Prometheus + Grafana)
- Deploy using Kubernetes (EKS)
- Add Terraform modules for scalability

## What This Project Demonstrates

- End-to-end infrastructure provisioning and deployment
- Secure cloud networking design
- Idempotent configuration management
- Debugging real-world cloud issues
- Operating applications in private environments

## Summary

This project focuses on understanding how systems are built, connected, and operated in a real cloud environment.

It demonstrates the transition from a containerized application to a production-style infrastructure setup using Terraform and Ansible.