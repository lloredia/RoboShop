# RoboShop Phase 2 & 3 Deployment Guide

This guide used to live in `roboshop-phase2-3/`. That directory duplicated the root modules and user-data scripts, so it was removed. The root Terraform stack, Ansible playbook, and `user-data/` scripts are the deployment. Passwords are generated into SSM. Do not paste credentials into `terraform.tfvars`.

The sections below are the original lab notes, updated where they contradicted the current stack.

## Overview

This guide covers deploying **Phase 2 (Databases)** and **Phase 3 (Applications)** for the RoboShop e-commerce platform.

### What You're Deploying

**Phase 2 - Database Tier:**
- MongoDB (Catalogue & User data)
- MySQL (Shipping data)
- Redis (Cart sessions)
- RabbitMQ (Payment queue)

**Phase 3 - Application Tier:**
- Frontend (Nginx reverse proxy)
- Catalogue (Node.js microservice)
- User (Node.js microservice)
- Cart (Node.js microservice)
- Shipping (Java microservice)
- Payment (Python microservice)
- Dispatch (Go microservice)

**Additional Components:**
- Route53 Private Hosted Zone for service discovery
- CloudWatch logging and monitoring
- Automated backups for all databases

## Prerequisites

✅ Phase 1 completed (VPC, Security Groups, Bastion)
✅ AWS CLI configured
✅ Terraform >= 1.0 installed
✅ SSH key pair configured

## Project Structure

```
roboshop-terraform-aws/
├── modules/
│   ├── ec2-instance/          # NEW: Generic EC2 module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── route53/               # NEW: Private DNS module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── vpc/                   # EXISTING from Phase 1
│   └── security-groups/       # EXISTING from Phase 1
├── user-data/                 # NEW: Installation scripts
│   ├── mongodb.sh
│   ├── mysql.sh
│   ├── redis.sh
│   ├── rabbitmq.sh
│   ├── frontend.sh
│   └── nodejs-service.sh
└── terraform/
    ├── main.tf                # UPDATE: Add Phase 2 & 3 resources
    ├── variables.tf           # UPDATE: Add new variables
    └── outputs.tf             # UPDATE: Add new outputs
```

## Installation Steps

### Step 1: Copy New Modules

```bash
cd roboshop-terraform-aws

# Copy the new ec2-instance module
cp -r /path/to/modules/ec2-instance modules/

# Copy the new route53 module
cp -r /path/to/modules/route53 modules/

# Copy user-data scripts
mkdir -p user-data
cp /path/to/user-data/*.sh user-data/
chmod +x user-data/*.sh
```

### Step 2: Update Terraform Configuration

Add the Phase 2 & 3 resources to your `terraform/main.tf`:

```hcl
# Copy content from terraform-phase2-3.tf to your main.tf
# Or include it as a separate file:
# terraform/databases.tf
# terraform/applications.tf
```

### Step 3: Add New Variables

Add to your `terraform/variables.tf`:

```hcl
# Copy content from variables-phase2-3.tf
```

Update your `terraform/terraform.tfvars`:

```hcl
# Passwords are not variables. Terraform writes them to SSM.
# See the README Quick Start for the vault step.
rabbitmq_user  = "roboshop"
mysql_app_user = "shipping"

# Private domain
private_domain = "roboshop.internal"

# Application artifacts (use default S3 URLs or your own)
frontend_artifact_url  = "https://roboshop-artifacts.s3.amazonaws.com/frontend.zip"
catalogue_artifact_url = "https://roboshop-artifacts.s3.amazonaws.com/catalogue.zip"
user_artifact_url      = "https://roboshop-artifacts.s3.amazonaws.com/user.zip"
cart_artifact_url      = "https://roboshop-artifacts.s3.amazonaws.com/cart.zip"
```

### Step 4: Validate Configuration

```bash
cd terraform

# Initialize new modules
terraform init -upgrade

# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Review the plan
terraform plan
```

### Step 5: Deploy Phase 2 (Databases First)

**Strategy:** Deploy databases before applications so apps can connect on first boot.

```bash
# Deploy ONLY databases first
terraform apply -target=module.mongodb \
                -target=module.mysql \
                -target=module.redis \
                -target=module.rabbitmq \
                -target=module.route53
```

**Wait:** 10-15 minutes for database installations to complete.

**Verify databases are ready:**

```bash
# SSH to bastion
ssh -i ~/.ssh/roboshop ec2-user@$(terraform output -raw bastion_public_ip)

# From bastion, test each database
# MongoDB
mongo --host mongodb.roboshop.internal --eval "db.version()"

# MySQL
mysql -h mysql.roboshop.internal -uroot -p -e "SELECT VERSION();"

# Redis
redis-cli -h redis.roboshop.internal ping

# RabbitMQ
curl -u roboshop http://rabbitmq.roboshop.internal:15672/api/overview
```

### Step 6: Deploy Phase 3 (Applications)

```bash
# Deploy applications
terraform apply -target=module.frontend \
                -target=module.catalogue \
                -target=module.user \
                -target=module.cart
```

**Wait:** 5-10 minutes for application deployments.

### Step 7: Verify Everything

```bash
# Get frontend private IP
terraform output

# From bastion, test applications
curl http://frontend.roboshop.internal/health
curl http://catalogue.roboshop.internal:8080/health
curl http://user.roboshop.internal:8080/health
curl http://cart.roboshop.internal:8080/health
```

## Deployment Timeline

| Step | Component | Time | Cumulative |
|------|-----------|------|------------|
| 1 | MongoDB | 5 min | 5 min |
| 2 | MySQL | 6 min | 11 min |
| 3 | Redis | 3 min | 14 min |
| 4 | RabbitMQ | 5 min | 19 min |
| 5 | Route53 | 1 min | 20 min |
| 6 | Frontend | 4 min | 24 min |
| 7 | Catalogue | 5 min | 29 min |
| 8 | User | 5 min | 34 min |
| 9 | Cart | 5 min | 39 min |

**Total deployment time: ~40 minutes**

## Architecture After Phase 2 & 3

```
Internet
    │
    ▼
  [ALB] (Public Subnet)
    │
    ▼
[Frontend:80] ──────────────┐
    │                       │
    │                       ▼
    │              [Catalogue:8080] ──► [MongoDB:27017]
    │                       │
    │              [User:8080] ──────► [MongoDB:27017]
    │                       │
    │              [Cart:8080] ──────► [Redis:6379]
    │                       │
    │              [Shipping:8080] ──► [MySQL:3306]
    │                       │
    │              [Payment:8080] ───► [RabbitMQ:5672]
    │                       │
    └──────────────────────► [Dispatch:8080]

All services communicate via internal DNS:
- mongodb.roboshop.internal
- mysql.roboshop.internal
- redis.roboshop.internal
- rabbitmq.roboshop.internal
```

## Cost Breakdown

**Phase 2 & 3 Monthly Costs (24/7):**

| Component | Instance Type | Quantity | Monthly Cost |
|-----------|---------------|----------|--------------|
| MongoDB | t3.small | 1 | $15 |
| MySQL | t3.small | 1 | $15 |
| Redis | t3.micro | 1 | $7.50 |
| RabbitMQ | t3.micro | 1 | $7.50 |
| Frontend | t3.micro | 1 | $7.50 |
| Catalogue | t3.micro | 1 | $7.50 |
| User | t3.micro | 1 | $7.50 |
| Cart | t3.micro | 1 | $7.50 |
| **Phase 1** | (Bastion, NAT) | - | $43 |
| **Total** | | | **$118/month** |

**Development cost with auto-shutdown:** ~$25-30/month

## Monitoring & Logs

### CloudWatch Logs

All services write logs to CloudWatch:

```bash
# View MongoDB logs
aws logs tail /aws/ec2/roboshop-dev-mongodb --follow

# View Catalogue service logs
aws logs tail /aws/ec2/roboshop-dev-catalogue --follow
```

### Service Health Checks

```bash
# From bastion host
/usr/local/bin/redis-monitor.sh
/usr/local/bin/rabbitmq-monitor.sh

# Check service status
ssh bastion
ssh frontend.roboshop.internal
systemctl status nginx
journalctl -u nginx -f
```

### Database Backups

Automated backups run daily at 2 AM:
- MongoDB: `/backup/mongodb/`
- MySQL: `/backup/mysql/`
- Redis: `/backup/redis/`
- RabbitMQ: `/backup/rabbitmq/`

## Troubleshooting

### Issue: Service won't start

```bash
# SSH to the service
ssh bastion
ssh <service>.roboshop.internal

# Check logs
journalctl -u <service> -n 50
tail -f /var/log/roboshop-<service>-install.log

# Check service status
systemctl status <service>

# Restart service
sudo systemctl restart <service>
```

### Issue: Can't resolve internal DNS

```bash
# Test DNS resolution
nslookup mongodb.roboshop.internal

# Check Route53 records
aws route53 list-resource-record-sets \
    --hosted-zone-id $(terraform output -raw route53_zone_id)
```

### Issue: Application can't connect to database

```bash
# From application server, test connectivity
telnet mongodb.roboshop.internal 27017
telnet mysql.roboshop.internal 3306
telnet redis.roboshop.internal 6379
```

### Issue: High CPU/Memory usage

```bash
# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=<instance-id> \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average
```

## Next Steps

### Phase 4: Load Balancer (Coming Next)
- Application Load Balancer for frontend
- Target groups with health checks
- Auto-scaling groups (optional)

### Phase 5: Monitoring & Alerting
- SNS notifications
- Custom CloudWatch dashboards
- Application Performance Monitoring

### Phase 6: CI/CD Pipeline
- GitHub Actions for automated deployment
- Blue/green deployments
- Automated testing

## Clean Up

```bash
# Destroy Phase 3 (Applications)
terraform destroy -target=module.cart \
                  -target=module.user \
                  -target=module.catalogue \
                  -target=module.frontend

# Destroy Phase 2 (Databases)
terraform destroy -target=module.rabbitmq \
                  -target=module.redis \
                  -target=module.mysql \
                  -target=module.mongodb \
                  -target=module.route53

# Or destroy everything
terraform destroy
```

## Support

- Check installation logs: `/var/log/roboshop-<service>-install.log`
- Service logs: `journalctl -u <service> -f`
- CloudWatch logs: AWS Console → CloudWatch → Log Groups

---

**🎉 Congratulations! You've deployed a complete microservices architecture!**
