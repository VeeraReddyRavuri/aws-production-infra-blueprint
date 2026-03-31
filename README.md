# AWS Production Infrastructure Blueprint

> End-to-end cloud infrastructure provisioned with Terraform, configured with Ansible, and deployed with Docker — using secure private networking, IAM least privilege, and centralized observability.

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat&logo=ansible&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat&logo=amazonaws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white)
![CloudWatch](https://img.shields.io/badge/CloudWatch-FF4F8B?style=flat&logo=amazonaws&logoColor=white)

---

## TL;DR

- Built a production-style AWS environment using Terraform, Ansible, and Docker
- Implemented secure private networking (bastion + private EC2 + NAT)
- Designed remote state with S3 + DynamoDB locking for safe team workflows
- Simulated and resolved 5 real-world failure scenarios (drift, state corruption, IAM issues)
- Validated idempotency and operational reliability across deployments

---

**Core competencies demonstrated:**
- Infrastructure as Code (Terraform) with remote state and environment isolation
- Configuration Management (Ansible) with idempotency validation
- Secure AWS networking with bastion + private subnet architecture
- IAM least-privilege policy design and debugging
- Observability via CloudWatch
- Operational debugging across 5 failure scenarios

---

## [Architecture](/docs/architecture.md)

```mermaid
flowchart TD

    Client["Client (Browser / Curl)"]

    Bastion["Bastion Host\n(Public EC2)"]

    subgraph VPC["AWS VPC (10.0.0.0/16)"]

        subgraph PublicSubnet["Public Subnet"]
            Bastion
            NAT["NAT Instance"]
        end

        subgraph PrivateSubnet["Private Subnet"]
            AppEC2["Private EC2\n(Docker + FastAPI)"]
        end

    end

    CloudWatch["CloudWatch Logs"]

    Client --> Bastion
    Bastion --> AppEC2

    AppEC2 --> NAT
    NAT --> Internet["Internet"]

    AppEC2 --> CloudWatch
```

**Security model:** The application EC2 has no public IP and accepts SSH only from the bastion's security group. The bastion accepts port 22 only from a single authorized CIDR. Outbound internet for the private EC2 routes through NAT Instance — no inbound exposure.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Infrastructure as Code | Terraform |
| Configuration Management | Ansible (role-based) |
| Cloud Provider | AWS (EC2, VPC, IAM, S3, DynamoDB, CloudWatch) |
| Application Runtime | Docker |
| Application | FastAPI (from [Previous Project](https://github.com/VeeraReddyRavuri/bug-tracker-containerized-stack)) |
| State Backend | S3 + DynamoDB (locking) |

---

## Engineering Highlights

**Secure Networking**
VPC designed with strict subnet isolation: application EC2 lives in a private subnet with no public IP. Internet access for outbound traffic (Docker pulls, package installs) routes through NAT Instance. SSH access follows a jump-host pattern: bastion → private EC2 via ProxyJump, so the app server is never directly reachable.

**IAM Least Privilege**
EC2 instance role scoped to exactly two permissions: `s3:GetObject` on the specific artifact bucket and `logs:PutLogEvents` + `logs:CreateLogStream` on the CloudWatch log group. Scoped permissions for required actions; resource-level scoping can be further refined in production. Spent time debugging a real permission error when CloudWatch agent failed silently, traced it to a missing `logs:DescribeLogStreams` permission.

**Terraform Remote State with Locking**
S3 backend configured for state persistence; DynamoDB table provides state locking to prevent concurrent apply collisions. Separate state keys per environment (`dev/terraform.tfstate`, `stage/terraform.tfstate`) enforced via `-backend-config` at init time rather than hardcoded in config keeps environments properly isolated.

**Idempotent Ansible Roles**
Playbook structured into four roles: `docker`, `nat`, `app`, `cloudwatch`. Validated idempotency by running the playbook twice and confirming zero changed tasks on the second run. Where tasks initially failed idempotency (package installs triggering changes), fixed them with proper `state: present` declarations and conditional guards.

**CloudWatch**
CloudWatch agent installed and configured via Ansible to ship system logs from the private EC2 to a log group.

---

## Design Decisions & Tradeoffs

- **NAT Instance vs NAT Gateway**
  Chose NAT Instance to understand networking internals and cost tradeoffs.
  In production, NAT Gateway would be preferred for reliability and reduced ops overhead.

- **Raw Docker on EC2 vs ECS/EKS**
  Used Docker directly to understand container lifecycle, networking, and failure modes
  before abstracting them away with orchestrators.

- **Remote State via S3 + DynamoDB**
  Enables safe collaboration and prevents concurrent state corruption — critical for team environments.

- **Bastion Host over direct access**
  Enforces strict network boundaries; no direct SSH to application layer.

---

## Failure-Driven Engineering

This project intentionally introduces and resolves failures to simulate real production scenarios.

Key principles applied:
- Infrastructure should reveal drift automatically
- State must be protected against corruption and concurrent writes
- Configuration must be idempotent and predictable
- Networking failures should be diagnosable, not silent

Each incident report documents not just the fix, but the reasoning behind it.

---

## Incident Reports

Five real failure scenarios were reproduced and documented. This section exists because debugging is what production engineering actually looks like.

| Incident | What Happened | How It Was Resolved |
|---|---|---|
| [Terraform Drift Detection](./incident_reports/terraform-drift.md) | Manually deleted a security group rule in the console, then ran `terraform plan` | Plan showed the drift as a resource to re-add. Documented detection method and why state-driven infra catches this automatically |
| [State File Corruption](./incident_reports/terraform-state-corruption.md) | Renamed the remote state file to simulate corruption, then attempted `terraform apply` | Terraform threw a backend initialization error. Recovery: restored the backup state key, re-ran `terraform init`, validated with `terraform plan` |
| [Ansible Idempotency Failure](./incident_reports/ansible-idempotency-failure.md) | Second playbook run showed changed tasks in the `docker` role | Root cause: `apt install` without `state: present`. Fixed with idempotent task declarations; second run confirmed 0 changes |
| [Terraform State Locking](./incident_reports/terraform-locking.md) | Simulated locking behavior by interrupting an active apply; observed lock persistence and need for manual unlock using `terraform force-unlock` mid-execution | Without DynamoDB, state file can be overwritten. With locking, second apply is blocked until the lock is released or force-unlocked |
| [NAT Connectivity Failure](./incident_reports/nat-connectivity-incident.md) | Private EC2 had no outbound internet access after initial provisioning | NAT Instance was in the wrong subnet. Fixed subnet association, verified with `curl` from private EC2 |

---

## Project Structure

```
aws-production-infra-blueprint/
│
├── terraform/
│   ├── main.tf             # VPC, subnets, EC2, NAT Instance, SGs
│   ├── variables.tf
│   ├── iam.tf              # Least-privilege EC2 role
│   ├── backend.tf          # S3 + DynamoDB remote state
│   ├── dev.tfvars
│   └── stage.tfvars
│
├── ansible/
│   ├── inventory.ini       # ProxyJump via bastion
│   ├── playbook.yml
│   └── roles/
│       ├── docker/         # Install + configure Docker
│       ├── nat/            # iptables
│       ├── app/            # Pull and run containerized FastAPI
│       └── cloudwatch/     # Agent install + log shipping config
│
├── incident_reports/
│   ├── terraform-drift.md
│   ├── terraform-state-corruption.md
│   ├── terraform-locking.md
│   ├── ansible-idempotency-failure.md
│   └── nat-connectivity-incident.md
│
├── docs/
│   └── architecture.md
│
├── demo/
│   └── demo.gif
│
└── README.md
```

---

## How to Run

### Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform ≥ 1.5
- Ansible ≥ 2.14
- SSH key pair added to AWS and available locally

### 1. Provision Infrastructure

```bash
cd terraform
terraform init \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="key=dev/terraform.tfstate" \
  -backend-config="region=ap-south-1"

terraform apply -var-file="dev.tfvars"
```

### 2. Configure and Deploy Application

```bash
cd ../ansible
# Update inventory.ini with bastion and private EC2 IPs from Terraform output
ansible-playbook -i inventory.ini playbook.yml
```

### 3. Validate Idempotency

```bash
ansible-playbook -i inventory.ini playbook.yml
# Expected: 0 changed tasks
```

### 4. Access Application

```bash
ssh -A -J ubuntu@<bastion-ip> ubuntu@<private-ec2-ip>
curl localhost:8080/health
```

### 5. Verify CloudWatch Logs

```
AWS Console → CloudWatch → Log Groups → dev-syslog
```

---

## Demo

![Demo](./demo/demo.gif)

Walkthrough covers: Terraform provisioning → Ansible configuration → SSH via bastion → app responding → CloudWatch log delivery

---

## Rollback Strategy

- Terraform: revert using previous state or re-apply stable configuration
- Ansible: idempotent playbooks ensure safe re-runs
- Docker: restart previous container version if needed

---

## Known Limitations

- No HTTPS / TLS termination
- No Application Load Balancer
- No autoscaling
- No secrets management (SSM Parameter Store or Secrets Manager)
- No CI/CD pipeline

## Planned Improvements

- [ ] Replace NAT instance with NAT Gateway
- [ ] Add ALB with HTTPS via ACM
- [ ] Terraform module for reusable VPC pattern
- [ ] GitHub Actions pipeline for plan + apply
- [ ] Secrets via AWS Secrets Manager
- [ ] Prometheus + Grafana for metrics beyond CloudWatch

---

## Related Projects

- [P1 — Linux Reliability Toolkit](https://github.com/VeeraReddyRavuri/linux-reliability-toolkit) — System monitoring and failure simulation
- [P2 — Bug Tracker Containerized Stack](https://github.com/VeeraReddyRavuri/bug-tracker-containerized-stack) — FastAPI + PostgreSQL + Nginx in Docker
