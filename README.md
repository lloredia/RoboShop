<div id="top">

<!-- HEADER STYLE: CLASSIC -->
<div align="center">

# ROBOSHOP ON AWS

<em>Production-Grade Microservices Deployment with Terraform & Ansible</em>

<br/>

<img src="docs/stan.png" width="180" alt="RoboShop Mascot" />

<br/><br/>

<!-- BADGES -->
<img src="https://img.shields.io/github/last-commit/lloredia/RoboShop?style=flat&logo=git&logoColor=white&color=0080ff" alt="last-commit">
<img src="https://img.shields.io/github/languages/top/lloredia/RoboShop?style=flat&color=0080ff" alt="repo-top-language">
<img src="https://img.shields.io/github/languages/count/lloredia/RoboShop?style=flat&color=0080ff" alt="repo-language-count">
<img src="https://img.shields.io/github/repo-size/lloredia/RoboShop?style=flat&color=0080ff" alt="repo-size">

<br/><br/>

<em>Built with the tools and technologies:</em>

<br/>

<img src="https://img.shields.io/badge/Terraform-844FBA.svg?style=flat&logo=Terraform&logoColor=white" alt="Terraform">
<img src="https://img.shields.io/badge/Ansible-EE0000.svg?style=flat&logo=Ansible&logoColor=white" alt="Ansible">
<img src="https://img.shields.io/badge/AWS-FF9900.svg?style=flat&logo=Amazon-AWS&logoColor=white" alt="AWS">
<img src="https://img.shields.io/badge/Linux-000000.svg?style=flat&logo=Linux&logoColor=white" alt="Linux">
<img src="https://img.shields.io/badge/Bash-121011.svg?style=flat&logo=GNU-Bash&logoColor=white" alt="Bash">
<img src="https://img.shields.io/badge/YAML-CB171E.svg?style=flat&logo=YAML&logoColor=white" alt="YAML">

</div>
<br>

---













































# RoboShop on AWS — Terraform + Ansible

<p align="center">
  <img src="docs/stan.png" width="180" alt="RoboShop Mascot" />
</p>

<p align="center">
  <b>Production-style RoboShop deployment on AWS using Terraform (IaC) + Ansible (config mgmt).</b><br/>
  Private networking, service discovery, and automated provisioning of EC2-based microservices + data tier.

<p align="center">
  <img alt="Terraform" src="https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform&logoColor=white" />
  <img alt="Ansible" src="https://img.shields.io/badge/Ansible-Config%20Mgmt-EE0000?logo=ansible&logoColor=white" />
  <img alt="AWS" src="https://img.shields.io/badge/AWS-EC2%20%7C%20VPC%20%7C%20Route53-FF9900?logo=amazonaws&logoColor=white" />
  <img alt="Linux" src="https://img.shields.io/badge/Linux-Amazon%20Linux-000000?logo=linux&logoColor=white" />
  <img alt="License" src="https://img.shields.io/badge/License-MIT-green.svg" />
</p>

---


## What this repo does

This repository deploys a microservices-based e-commerce platform on AWS using:
- **Terraform** to provision the infrastructure (VPC, subnets, EC2, Route53 private DNS, security groups)
- **Ansible** to configure servers and install/run services

It’s built around a secure network pattern:
- **Public subnet:** Bastion Host + Internet Gateway
- **Private subnets:** App tier + DB tier behind a NAT Gateway
- **Service discovery:** Route53 Private Hosted Zone (e.g., `*.roboshop.internal`)


---







rweaefafwkjoenmfujinaweiunbrfuiefyuoaweryurfyuhbrgyuebfgyibergyvbyfegyrbgbrf
















# RoboShop E-Commerce Platform - AWS Deployment

A complete microservices-based e-commerce platform deployed on AWS using Infrastructure as Code (Terraform) and Configuration Management (Ansible).

## Architecture Overview
```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└────────────────────┬────────────────────────────────────────┘
                     │
            ┌────────▼────────┐
            │  Internet Gateway│
            └────────┬────────┘
                     │
        ┌────────────▼────────────┐
        │    Public Subnet        │
        │  ┌──────────────────┐  │
        │  │  Bastion Host    │  │
        │  └──────────────────┘  │
        └────────────┬────────────┘
                     │
        ┌────────────▼──────────────────────────┐
        │         NAT Gateway                    │
        └────────────┬──────────────────────────┘
                     │
     ┌───────────────┴──────────────────┐
     │                                   │
┌────▼─────────────┐          ┌─────────▼──────────┐
│ Private App      │          │ Private DB         │
│ Subnet           │          │ Subnet             │
│                  │          │                    │
│ - Frontend       │          │ - MongoDB          │
│ - Catalogue      │          │ - MySQL            │
│ - User           │          │ - Redis            │
│ - Cart           │          │ - RabbitMQ         │
└──────────────────┘          └────────────────────┘
         │                             │
         └──────────┬──────────────────┘
                    │
         ┌──────────▼──────────┐
         │  Route53 Private    │
         │  Hosted Zone        │
         │  *.roboshop.internal│
         └─────────────────────┘
---

## Tech stack (with icons)

### Infrastructure / Automation
- <img src="https://skillicons.dev/icons?i=terraform" height="18" /> Terraform (HCL)
- <img src="https://skillicons.dev/icons?i=ansible" height="18" /> Ansible (YAML playbooks)
- <img src="https://skillicons.dev/icons?i=aws" height="18" /> AWS (EC2, VPC, Route53, IGW, NAT)
- <img src="https://skillicons.dev/icons?i=bash" height="18" /> Shell / Bash (bootstrap + ops scripts)

### Platform services
- <img src="https://skillicons.dev/icons?i=nginx" height="18" /> Nginx (frontend / reverse proxy)
- <img src="https://skillicons.dev/icons?i=nodejs" height="18" /> Node.js (microservices runtime)
- <img src="https://skillicons.dev/icons?i=mongodb" height="18" /> MongoDB
- <img src="https://skillicons.dev/icons?i=mysql" height="18" /> MySQL/MariaDB
- <img src="https://skillicons.dev/icons?i=redis" height="18" /> Redis
- <img src="https://skillicons.dev/icons?i=rabbitmq" height="18" /> RabbitMQ


---



         
```

##  Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

## ✨ Features

### Infrastructure
- **VPC with Public/Private Subnets** - Secure network architecture
- **NAT Gateway** - Enables private instances to access internet
- **Bastion Host** - Secure SSH access to private instances
- **Route53 Private DNS** - Service discovery via internal DNS names
- **Security Groups** - Network segmentation and access control

### Microservices
- **Frontend** - Nginx web server with reverse proxy
- **Catalogue Service** - Product catalog API (Node.js)
- **User Service** - User management API (Node.js)
- **Cart Service** - Shopping cart API (Node.js)

### Databases & Messaging
- **MongoDB** - NoSQL database for catalogue and user data
- **MySQL (MariaDB)** - Relational database for shipping
- **Redis** - In-memory cache for sessions
- **RabbitMQ** - Message queue for async processing

## ��� Prerequisites

### Software Requirements
- **Terraform** >= 1.0
- **Ansible** >= 2.9
- **AWS CLI** configured with credentials
- **Git**
- **SSH client**

### AWS Requirements
- AWS Account with appropriate permissions
- AWS CLI configured: `aws configure`
- SSH key pair for EC2 access

### Local Tools
- Text editor (VS Code recommended)
- Terminal/Command line access

## ���️ Technology Stack

| Category | Technology | Purpose |
|----------|------------|---------|
| IaC | Terraform | Infrastructure provisioning |
| Config Mgmt | Ansible | Server configuration |
| Cloud Provider | AWS | Infrastructure hosting |
| Web Server | Nginx | Frontend & reverse proxy |
| Application | Node.js | Microservices runtime |
| Databases | MongoDB, MySQL, Redis | Data persistence |
| Message Queue | RabbitMQ | Async communication |
| DNS | Route53 | Service discovery |

## ��� Project Structure
```
roboshop-terraform-aws/
├── terraform/
│   ├── main.tf                 # Main infrastructure
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── terraform.tfvars        # Variable values (DO NOT COMMIT)
│   ├── databases-and-apps.tf   # EC2 instances
│   └── route53.tf              # DNS configuration
├── modules/
│   ├── vpc/                    # VPC module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security-groups/        # Security groups module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── route53/                # Route53 module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── ansible/
│   ├── site.yml                # Main playbook
│   ├── inventory/
│   │   └── hosts               # Inventory file
│   ├── group_vars/
│   │   └── all.yml             # Global variables
│   └── roles/
│       ├── mongodb/            # MongoDB role
│       ├── mysql/              # MySQL role
│       ├── redis/              # Redis role
│       ├── rabbitmq/           # RabbitMQ role
│       ├── frontend/           # Frontend role
│       ├── catalogue/          # Catalogue service role
│       ├── user/               # User service role
│       └── cart/               # Cart service role
├── README.md                   # This file
└── .gitignore                  # Git ignore rules
```

## ��� Getting Started

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd roboshop-terraform-aws
```

### 2. Configure AWS Credentials
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-east-1)
```

### 3. Generate SSH Key Pair
```bash
# Generate a new SSH key for EC2 instances
ssh-keygen -t rsa -b 4096 -f ~/.ssh/roboshop-key -C "roboshop-infrastructure"

# View the public key (you'll need this for terraform.tfvars)
cat ~/.ssh/roboshop-key.pub
```

### 4. Configure Terraform Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # or use your preferred editor
```

Update the following in `terraform.tfvars`:
```hcl
# AWS Configuration
aws_region    = "us-east-1"
environment   = "dev"
project_name  = "roboshop"

# Network Configuration
vpc_cidr                = "10.0.0.0/16"
public_subnet_cidr      = "10.0.1.0/24"
private_app_subnet_cidr = "10.0.10.0/24"
private_db_subnet_cidr  = "10.0.20.0/24"
availability_zone       = "us-east-1a"

# SSH Configuration
ssh_public_key = "ssh-rsa AAAAB3... your-public-key-here"
allowed_ssh_cidr = ["YOUR_IP/32"]  # Your public IP for SSH access

# Database Configuration
mysql_root_password = "YourSecurePassword123!"
rabbitmq_user      = "roboshop"
rabbitmq_password  = "roboshop123"

# Domain Configuration
private_domain = "roboshop.internal"
```

## ��� Deployment

### Phase 1: Infrastructure Deployment (Terraform)
```bash
cd terraform

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply

# Save the bastion public IP from outputs
export BASTION_IP=$(terraform output -raw bastion_public_ip)
```

**Expected Resources Created:**
- 1 VPC
- 3 Subnets (1 public, 2 private)
- 1 Internet Gateway
- 1 NAT Gateway
- 1 Elastic IP (for NAT)
- 3 Route Tables
- 13 Security Groups
- 8 EC2 Instances
- 1 Route53 Private Hosted Zone
- 8 Route53 DNS Records

### Phase 2: Configuration Management (Ansible)
```bash
# Copy SSH key to bastion
scp -i ~/.ssh/roboshop-key ~/.ssh/roboshop-key ec2-user@$BASTION_IP:~/.ssh/

# SSH to bastion
ssh -i ~/.ssh/roboshop-key ec2-user@$BASTION_IP

# On the bastion: Install Ansible
sudo amazon-linux-extras install ansible2 -y

# Clone/copy your ansible directory to bastion
# (Or recreate it following the project structure)

cd ~/roboshop-ansible

# Fix key permissions
chmod 600 ~/.ssh/roboshop-key

# Load SSH key
eval $(ssh-agent -s)
ssh-add ~/.ssh/roboshop-key

# Test connectivity
ansible all -i inventory/hosts -m ping

# Deploy all services
ansible-playbook -i inventory/hosts site.yml
```

**Deployment Time:** ~15-20 minutes

### Phase 3: Verification
```bash
# On bastion: Check all services
cat > check-services.sh << 'SCRIPT'
#!/bin/bash
echo "=== DATABASES ==="
echo "MongoDB:"
ssh -o StrictHostKeyChecking=no ec2-user@mongodb.roboshop.internal "sudo systemctl is-active mongod"
echo "MySQL:"
ssh -o StrictHostKeyChecking=no ec2-user@mysql.roboshop.internal "sudo systemctl is-active mariadb"
echo "Redis:"
ssh -o StrictHostKeyChecking=no ec2-user@redis.roboshop.internal "sudo systemctl is-active redis"
echo "RabbitMQ:"
ssh -o StrictHostKeyChecking=no ec2-user@rabbitmq.roboshop.internal "sudo systemctl is-active rabbitmq-server"
echo ""
echo "=== APPLICATIONS ==="
echo "Frontend:"
ssh -o StrictHostKeyChecking=no ec2-user@frontend.roboshop.internal "sudo systemctl is-active nginx"
echo "Catalogue:"
ssh -o StrictHostKeyChecking=no ec2-user@catalogue.roboshop.internal "sudo systemctl is-active catalogue"
echo "User:"
ssh -o StrictHostKeyChecking=no ec2-user@user.roboshop.internal "sudo systemctl is-active user"
echo "Cart:"
ssh -o StrictHostKeyChecking=no ec2-user@cart.roboshop.internal "sudo systemctl is-active cart"
SCRIPT

chmod +x check-services.sh
./check-services.sh
```

All services should show `active`.

## ��� Testing

### Access the Application

**Option 1: SSH Tunnel (Recommended for testing)**

On your local machine:
```bash
# Create SSH tunnel
ssh -i ~/.ssh/roboshop-key -L 8080:frontend.roboshop.internal:80 ec2-user@$BASTION_IP

# Open browser to http://localhost:8080
```

**Option 2: Deploy Application Load Balancer (Production)**

Add ALB configuration to Terraform for public access.

### Test Microservices

1. **Homepage** - Should display product categories
2. **Browse Products** - Click on categories (tests Catalogue service)
3. **Add to Cart** - Add items to cart (tests Cart + Redis)
4. **User Registration** - Create account (tests User + MongoDB)

### Verify Service Communication
```bash
# On bastion
# Test frontend → catalogue
curl http://frontend.roboshop.internal/api/catalogue/categories

# Test catalogue → mongodb
ssh ec2-user@catalogue.roboshop.internal \
  "curl -s http://localhost:8080/health"

# Test user → redis
ssh ec2-user@user.roboshop.internal \
  "curl -s http://localhost:8080/health"
```

## ��� Troubleshooting

### Common Issues

#### 1. SSH Permission Denied
```bash
# Ensure key is loaded
ssh-add -l

# If empty, add key
eval $(ssh-agent -s)
ssh-add ~/.ssh/roboshop-key
```

#### 2. Service Not Active
```bash
# Check service logs
ssh ec2-user@<service>.roboshop.internal "sudo journalctl -u <service-name> -n 50"

# Restart service
ssh ec2-user@<service>.roboshop.internal "sudo systemctl restart <service-name>"
```

#### 3. Cannot Reach Services
```bash
# Check security groups in AWS Console
# Verify DNS resolution
nslookup <service>.roboshop.internal

# Test connectivity
telnet <service>.roboshop.internal <port>
```

#### 4. Terraform State Issues
```bash
# Refresh state
terraform refresh

# If corrupted, restore from backup
mv terraform.tfstate.backup terraform.tfstate
```

## ��� Architecture Decisions

### Why This Architecture?

1. **Multi-Tier Design** - Separation of web, app, and data layers
2. **Private Subnets** - Enhanced security for applications and databases
3. **Bastion Host** - Secure access point without exposing instances
4. **Service Discovery** - DNS-based routing eliminates hard-coded IPs
5. **Security Groups** - Fine-grained network access control
6. **IaC + Config Mgmt** - Terraform for infra, Ansible for configuration

### Trade-offs

| Decision | Benefit | Trade-off |
|----------|---------|-----------|
| Single AZ | Cost savings | No HA |
| NAT Gateway | Managed service | Higher cost vs NAT instance |
| Bastion | Security | Extra hop for access |
| MariaDB | Drop-in MySQL replacement | Not official MySQL |
| Node.js 16 | Stable, compatible | Not latest version |

## ��� Security Considerations

### Implemented
✅ Private subnets for all services  
✅ Security groups with least privilege  
✅ SSH key-based authentication  
✅ No public IPs on app/db instances  
✅ Bastion host for secure access  

### Recommended Additions
- [ ] AWS Secrets Manager for credentials
- [ ] VPC Flow Logs for network monitoring
- [ ] CloudTrail for audit logging
- [ ] WAF for application protection
- [ ] SSL/TLS certificates
- [ ] IMDSv2 enforcement
- [ ] Regular security scanning

## ��� Cost Estimation

**Monthly AWS Costs (us-east-1):**

| Resource | Quantity | Monthly Cost |
|----------|----------|--------------|
| EC2 t3.micro | 8 instances | ~$60 |
| NAT Gateway | 1 | ~$32 |
| Elastic IP | 2 | ~$7.50 |
| EBS (gp2) | 64 GB | ~$6.40 |
| Data Transfer | Minimal | ~$5 |
| **Total** | | **~$110/month** |

��� **Cost Optimization:**
- Use t3.nano for testing (~$3.80/month each)
- Stop instances when not in use
- Use NAT instance instead of NAT Gateway (~$3.50/month)
- Consider Reserved Instances for production

## ��� Next Steps

### Short Term
- [ ] Add Application Load Balancer for production access
- [ ] Implement SSL/TLS with ACM certificates
- [ ] Set up CloudWatch monitoring and alarms
- [ ] Configure automated backups for databases
- [ ] Add health checks and auto-recovery

### Medium Term
- [ ] Deploy remaining services (Shipping, Payment, Dispatch)
- [ ] Implement auto-scaling for application tier
- [ ] Set up CI/CD pipeline with GitHub Actions
- [ ] Add centralized logging (ELK/CloudWatch Logs)
- [ ] Implement blue-green deployment

### Long Term
- [ ] Multi-AZ deployment for high availability
- [ ] Multi-region setup for disaster recovery
- [ ] Kubernetes migration for container orchestration
- [ ] Service mesh implementation (Istio/App Mesh)
- [ ] Advanced monitoring with Prometheus/Grafana

## ��� Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [RoboShop Original Project](https://github.com/instana/robot-shop)

## ��� Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## ��� License

This project is for educational purposes.

## ��� Author

**Your Name**
- GitHub: [@yourusername](https://github.com/yourusername)
- LinkedIn: [Your Profile](https://linkedin.com/in/yourprofile)

## ��� Acknowledgments

- RoboShop reference architecture
- AWS documentation and best practices
- Terraform and Ansible communities

---

**Note:** Remember to never commit sensitive information like:
- `terraform.tfvars` (contains secrets)
- `*.pem` files (SSH private keys)
- AWS credentials
- Database passwords

Use `.gitignore` to exclude these files.
