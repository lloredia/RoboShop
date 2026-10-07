<div id="top" align="center">
<img src="docs/stan.png" width="200" alt="RoboShop Mascot" />
</div>

# RoboShop E-Commerce Platform - AWS Deployment

<div align="center">

![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?style=for-the-badge&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-2.16+-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

[![CI](https://github.com/lloredia/RoboShop/actions/workflows/ci.yml/badge.svg)](https://github.com/lloredia/RoboShop/actions/workflows/ci.yml)
[![Last Commit](https://img.shields.io/github/last-commit/lloredia/RoboShop?style=flat-square)](https://github.com/lloredia/RoboShop/commits/master)
[![Issues](https://img.shields.io/github/issues/lloredia/RoboShop?style=flat-square)](https://github.com/lloredia/RoboShop/issues)
[![Stars](https://img.shields.io/github/stars/lloredia/RoboShop?style=flat-square)](https://github.com/lloredia/RoboShop/stargazers)
[![Forks](https://img.shields.io/github/forks/lloredia/RoboShop?style=flat-square)](https://github.com/lloredia/RoboShop/network/members)

**A microservices e-commerce platform on AWS, provisioned with Terraform and configured with Ansible**

</div>

---

## 🏗️ Architecture Overview

```mermaid
flowchart TB
    subgraph Internet["🌐 Internet"]
        Users((Users))
    end

    subgraph VPC["☁️ AWS VPC (10.0.0.0/16)"]
        
        IGW[🚪 Internet Gateway]
        
        subgraph PublicSubnet["Public Subnet (10.0.1.0/24)"]
            Bastion[🖥️ Bastion Host]
        end
        
        NAT[🔀 NAT Gateway]
        
        subgraph PrivateAppSubnet["Private App Subnet (10.0.10.0/24)"]
            Frontend[🌐 Frontend\nNginx]
            Catalogue[📦 Catalogue\nNode.js]
            User[👤 User\nNode.js]
            Cart[🛒 Cart\nNode.js]
            Shipping[🚚 Shipping\nJava]
            Payment[💳 Payment\nPython]
            Dispatch[📮 Dispatch\nGo]
        end
        
        subgraph PrivateDBSubnet["Private DB Subnet (10.0.20.0/24)"]
            MongoDB[(🍃 MongoDB)]
            MySQL[(🐬 MariaDB)]
            Redis[(⚡ Redis)]
            RabbitMQ[🐰 RabbitMQ]
        end
        
        subgraph DNS["Route53 Private Hosted Zone"]
            R53[📍 *.roboshop.internal]
        end
    end

    Users --> IGW
    IGW --> Bastion
    IGW -.-> NAT
    Bastion -.->|SSH| PrivateAppSubnet
    PrivateAppSubnet --> NAT
    NAT --> IGW
    
    Frontend --> Catalogue
    Frontend --> User
    Frontend --> Cart
    Frontend --> Shipping
    Frontend --> Payment
    
    Catalogue --> MongoDB
    User --> MongoDB
    User --> Redis
    Cart --> Redis
    Cart --> Catalogue
    Shipping --> MySQL
    Shipping --> Cart
    Payment --> User
    Payment --> Cart
    Payment --> RabbitMQ
    Dispatch --> RabbitMQ
    
    PrivateAppSubnet -.-> R53
    PrivateDBSubnet -.-> R53
```

### Service Communication Flow

```mermaid
flowchart LR
    subgraph FE["Frontend Layer"]
        Nginx[🌐 Nginx\nPort 80]
    end

    subgraph APP["Application Layer"]
        CAT[📦 Catalogue\n:8080]
        USR[👤 User\n:8080]
        CRT[🛒 Cart\n:8080]
        SHP[🚚 Shipping\n:8080]
        PAY[💳 Payment\n:8080]
        DIS[📮 Dispatch\nworker]
    end

    subgraph DATA["Data Layer"]
        MONGO[(MongoDB\n:27017)]
        MYSQL[(MariaDB\n:3306)]
        REDIS[(Redis\n:6379)]
        RABBIT[RabbitMQ\n:5672]
    end

    Nginx -->|/api/catalogue| CAT
    Nginx -->|/api/user| USR
    Nginx -->|/api/cart| CRT
    Nginx -->|/api/shipping| SHP
    Nginx -->|/api/payment| PAY

    CAT --> MONGO
    USR --> MONGO
    USR --> REDIS
    CRT --> REDIS
    CRT --> CAT
    SHP --> MYSQL
    SHP --> CRT
    PAY --> USR
    PAY --> CRT
    PAY --> RABBIT
    DIS --> RABBIT
```

Dispatch does not listen for HTTP. It consumes the `orders` queue that payment publishes.

### Deployment Pipeline

```mermaid
flowchart LR
    subgraph IaC["Infrastructure as Code"]
        TF[🏗️ Terraform\nProvision AWS]
        SSM[🔐 SSM\nSecureString]
        ANS[📜 Ansible\nConfigure Services]
    end

    subgraph Infra["AWS Infrastructure"]
        VPC[VPC + Subnets]
        EC2[12 EC2 Instances]
        SG[Security Groups]
        RT53[Route53 DNS]
    end

    TF -->|terraform apply| VPC
    TF -->|terraform apply| EC2
    TF -->|terraform apply| SG
    TF -->|terraform apply| RT53
    TF -->|random_password| SSM
    EC2 -->|boot scripts| SSM
    ANS -->|vault file copied from SSM| EC2
```

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Security](#security)
- [Cost](#cost)
- [What I'd do next](#what-id-do-next)

## ✨ Features

### Infrastructure
- VPC with one public subnet and two private subnets, a single NAT gateway, and a bastion
- Route53 private zone for service discovery (`mongodb.roboshop.internal` and the rest)
- One security group per service. SSH reaches the bastion only, and only from `admin_cidr`
- IMDSv2, encrypted EBS, and a customer-managed KMS key for SSM parameters

### Microservices
- **Frontend** - Nginx reverse proxy
- **Catalogue** - Node.js, MongoDB
- **User** - Node.js, MongoDB and Redis
- **Cart** - Node.js, Redis and Catalogue
- **Shipping** - Java, MariaDB and Cart
- **Payment** - Python, User, Cart, and RabbitMQ
- **Dispatch** - Go worker, RabbitMQ

### Data
- MongoDB for catalogue and user documents
- MariaDB for the shipping `cities` database
- Redis for user and cart
- RabbitMQ for the payment to dispatch queue

This stack is **12 EC2 instances**: the bastion, four data nodes, and seven application nodes. Route53 has **11** private A records (the bastion is not in the private zone).

## 🚀 Quick Start

### Prerequisites
- Terraform `>= 1.5` and `< 2`
- Ansible `>= 2.16`
- AWS CLI configured for an account you can spend money in
- An SSH key pair

### 1. Variables

```bash
ssh-keygen -t ed25519 -f ~/.ssh/roboshop-key -C "roboshop"
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Set `ssh_public_key` to the contents of `~/.ssh/roboshop-key.pub`. Set `admin_cidr` to your own `/32` (`curl -fsS ifconfig.me`). `0.0.0.0/0` is rejected. `terraform.tfvars` is gitignored.

There is no password variable. Terraform generates the MySQL and RabbitMQ passwords.

### 2. Remote state (optional)

Local state is the default so a fresh clone still validates. For anything you apply, copy `terraform/backend.hcl.example` to `backend.hcl`, uncomment it, create the S3 bucket and DynamoDB lock table, then:

```bash
terraform init -backend-config=backend.hcl
```

`backend.hcl` is gitignored. Generated passwords are stored in state as well as SSM, so the state bucket needs encryption.

### 3. Apply

```bash
terraform init -backend=false   # or with -backend-config, if you opted in
terraform plan
terraform apply
```

Apply creates the network, 12 instances, the private zone, a KMS key, and SecureString parameters under `/roboshop/dev/`. Boot scripts on the MySQL, RabbitMQ, shipping, payment, and dispatch instances read those parameters. Nothing in user-data contains a password.

**This bills immediately.** A NAT gateway alone is about $32/month before the instances. Destroy the stack when you are done. See [Cost](#cost).

### 4. Ansible

On the bastion (or any host that can SSH to the private instances and read SSM):

```bash
mkdir -p ansible/group_vars/all
cp ansible/group_vars/all.vault.yml.example ansible/group_vars/all/vault.yml
```

Fill the three values from SSM, then encrypt the file:

```bash
aws ssm get-parameter --name /roboshop/dev/mysql/root_password \
  --with-decryption --query Parameter.Value --output text
aws ssm get-parameter --name /roboshop/dev/mysql/app_password \
  --with-decryption --query Parameter.Value --output text
aws ssm get-parameter --name /roboshop/dev/rabbitmq/password \
  --with-decryption --query Parameter.Value --output text

ansible-vault encrypt ansible/group_vars/all/vault.yml
# or create it directly:
ansible-vault create ansible/group_vars/all/vault.yml
```

The vault file must match SSM. User-data and Ansible both set the same accounts. If they diverge, the next playbook run will change the passwords the running apps already loaded.

```bash
ansible-playbook -i ansible/inventory/hosts ansible/site.yml --ask-vault-pass
```

### 5. Reach the store

The frontend is on a private subnet. There is no load balancer yet.

```bash
ssh -i ~/.ssh/roboshop-key -L 8080:frontend.roboshop.internal:80 ec2-user@$(terraform output -raw bastion_public_ip)
```

Open `http://localhost:8080`.

### 6. Tear it down

```bash
cd terraform
terraform destroy
```

Confirm in the EC2 and VPC consoles that the NAT gateway, instances, and Elastic IPs are gone. NAT gateways and unattached Elastic IPs keep billing after a partial delete. `scripts/stop-roboshop.sh` stops compute, but it does not stop the NAT gateway charge.

## 📁 Project Structure

```
├── terraform/                  # Root module: instances, SSM, bastion
│   ├── backend.hcl.example     # Commented S3 + DynamoDB backend
│   ├── databases-and-apps.tf
│   ├── secrets.tf
│   └── terraform.tfvars.example
├── modules/
│   ├── vpc/
│   ├── security-groups/
│   ├── ec2-instance/
│   └── route53/
├── user-data/                  # First-boot scripts, secrets via SSM
├── ansible/
│   ├── site.yml
│   ├── inventory/hosts
│   ├── group_vars/all.yml
│   ├── group_vars/all.vault.yml.example
│   └── roles/                  # mongodb, mysql, redis, rabbitmq,
│                               # catalogue, user, cart, shipping,
│                               # payment, dispatch, frontend
├── scripts/                    # start/stop instances by tag
└── .github/workflows/ci.yml
```

## 🔐 Security

Lab defaults used to be committed (`RoboShop@123`, `roboshop123`, and a MySQL fallback of `RoboShop@1`). They are gone from the tree. They are still in git history. This change does not rewrite history.

What the stack does now:

- Terraform generates three passwords with `random_password` and stores them as SecureString parameters encrypted with a customer-managed KMS key. The values are `sensitive` and are not Terraform outputs.
- User-data reads SSM at boot. Root MySQL is `localhost` only. The script does not create `root@'%'` and does not uninstall password validation. The shipping account is `shipping` (override with `mysql_app_user`) at the app-subnet host pattern `10.0.10.%`, with `SELECT, INSERT, UPDATE, DELETE` on `cities` only.
- The upstream shipping jar hardcodes a database password. The user-data script and the Ansible role rewrite `JpaConfig.java` to `DB_USER` / `DB_PASS` before `mvn package`, and refuse to build if that lab string is still in the source.
- The shipping schema's `GRANT ... TO 'shipping'@'%'` statements are stripped before load.
- RabbitMQ's `guest` user is deleted. The application user gets the `management` tag, not `administrator`, and only the default vhost. The management port is open to the bastion security group, not the internet.
- SSH to the bastion is `admin_cidr`. Every other instance accepts SSH only from the bastion. Application ports follow the call graph above. Dispatch has no application ingress.
- The ALB security group allows HTTP and HTTPS from the internet. It is not attached yet. App and database groups do not allow `0.0.0.0/0` ingress. Egress to the internet stays open so instances can reach package mirrors through the NAT gateway.
- Instances require IMDSv2. EBS volumes are encrypted. The VPC default security group is emptied.
- Ansible secrets live in `group_vars/all/vault.yml`, which is gitignored. The committed file is `all.vault.yml.example` and contains placeholders.

Residual risk, on purpose for this lab shape:

- MongoDB and Redis have no application authentication. The security groups are the control. The Node services in the public artifacts do not send a Redis password.
- Passwords still land in Terraform state. Use the encrypted remote backend before you apply this anywhere you care about.
- Shipping's `DB_PASS` is in a root-only environment file, mode `0600`.
- Single availability zone, no ALB, and MySQL/MariaDB is an EC2 install rather than RDS.

`.checkov.yaml` lists the checks left open and why. CI does not use `--soft-fail`.

## 💰 Cost

Rough on-demand monthly cost in us-east-1 if the stack runs all month. These are list prices, not a quote.

| Resource | Quantity | About |
|----------|----------|-------|
| EC2 t3.micro | 9 | $70 |
| EC2 t3.small (MongoDB, MariaDB, shipping) | 3 | $45 |
| NAT gateway | 1 | $32 plus data |
| Detailed monitoring | 12 instances | $25 |
| EBS | ~200 GB gp3 | $16 |
| **Total** | | **about $190/month** |

Attached Elastic IPs are not billed. The NAT gateway is. Stopping instances with `scripts/stop-roboshop.sh` leaves the NAT gateway running.

`terraform destroy` is the off switch. Do it when the demo is over.

## 🎯 What I'd do next

- Put an Application Load Balancer and an Auto Scaling group in front of the frontend, and attach the security group that is already there. Health checks would replace the SSH tunnel.
- Bake AMIs (or move the Java, Python, and Go services into containers) and run them on EKS, so a Maven build is not happening on first boot of a t3.small.
- Add metrics, logs, and traces: the CloudWatch log groups exist, but no agent ships to them yet. Prometheus is already in the payment service. A collector plus dashboards would make the queue and the shipping database visible.
- Multi-AZ subnets, RDS or a managed MongoDB, and Redis AUTH once the app reads a password.
- Rotate the SSM parameters without rebuilding instances, and turn the opt-in S3 backend on by default for any shared account.

## 🧪 CI

GitHub Actions runs `terraform fmt -check`, `terraform init -backend=false`, `terraform validate`, `tflint`, `checkov`, `ansible-lint`, `yamllint`, and `shellcheck`.

## 🎯 Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible](https://docs.ansible.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [RoboShop reference application](https://github.com/instana/robot-shop)

## 🎯 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Run the same checks CI runs before opening a pull request.

## 📄 License

MIT. See [LICENSE](LICENSE).

## 💭 Author

- GitHub: [lloredia](https://github.com/lloredia)
- LinkedIn: [Amadin Oredia](https://www.linkedin.com/in/amadin-o-8b1143192/)

## 📄 Acknowledgments

- RoboShop reference architecture
- AWS, Terraform, and Ansible documentation

---

Do not commit `terraform.tfvars`, `backend.hcl`, `group_vars/all/vault.yml`, `*.pem`, or a vault password file. `.gitignore` already excludes them.
