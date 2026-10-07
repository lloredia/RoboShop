# RoboShop Terraform AWS Deployment - Portfolio Project

The live footprint is 12 EC2 instances (bastion, four data services, seven application services). The README is the source of truth. This plan is the original design note.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                          VPC (10.0.0.0/16)                      │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Public Subnet (10.0.1.0/24)                 │  │
│  │                                                          │  │
│  │  ┌──────────────┐         ┌─────────────────┐          │  │
│  │  │   Bastion    │         │  ALB (Frontend) │          │  │
│  │  │   Host       │         │                 │          │  │
│  │  └──────────────┘         └─────────────────┘          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            Private Subnet 1 (10.0.10.0/24)               │  │
│  │         Application Tier - Microservices                 │  │
│  │                                                          │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │  │
│  │  │ Frontend │  │Catalogue │  │   User   │  │  Cart   │ │  │
│  │  │  (Nginx) │  │ (Node.js)│  │(Node.js) │  │(Node.js)│ │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │  │
│  │                                                          │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐              │  │
│  │  │ Shipping │  │ Payment  │  │ Dispatch │              │  │
│  │  │  (Java)  │  │ (Python) │  │   (Go)   │              │  │
│  │  └──────────┘  └──────────┘  └──────────┘              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            Private Subnet 2 (10.0.20.0/24)               │  │
│  │              Database/Cache Tier                         │  │
│  │                                                          │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │  │
│  │  │ MongoDB  │  │  MySQL   │  │  Redis   │  │RabbitMQ │ │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Infrastructure Components

### Network Layer
- VPC with CIDR 10.0.0.0/16
- 3 Subnets:
  - Public (10.0.1.0/24) - Bastion, ALB
  - Private App (10.0.10.0/24) - Application servers
  - Private DB (10.0.20.0/24) - Databases
- Internet Gateway
- NAT Gateway (for private subnet internet access)
- Route Tables

### Compute Layer
- **9 EC2 Instances** (t3.small or t3.micro):
  1. Frontend (Nginx)
  2. Catalogue (Node.js)
  3. User (Node.js)
  4. Cart (Node.js)
  5. Shipping (Java)
  6. Payment (Python)
  7. Dispatch (Go)
  8. MongoDB
  9. MySQL
  10. Redis
  11. RabbitMQ
  12. Bastion Host

### Security
- Security Groups per service
- IAM roles for EC2 instances
- SSH key pairs
- Network ACLs

### DNS (Optional)
- Route53 private hosted zone
- Internal DNS records (mongodb.roboshop.internal, etc.)

## Project Structure

```
roboshop-terraform-aws/
├── README.md
├── .gitignore
├── terraform/
│   ├── main.tf                    # Root module
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── terraform.tfvars          # Variable values (gitignored)
│   ├── terraform.tfvars.example  # Example variable values
│   ├── backend.tf                # S3 backend configuration
│   ├── provider.tf               # AWS provider config
│   └── data.tf                   # Data sources
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security-groups/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2-app/                  # Application server module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── user-data/            # Startup scripts
│   │       ├── frontend.sh
│   │       ├── catalogue.sh
│   │       ├── user.sh
│   │       ├── cart.sh
│   │       ├── shipping.sh
│   │       ├── payment.sh
│   │       └── dispatch.sh
│   ├── ec2-database/             # Database server module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── user-data/
│   │       ├── mongodb.sh
│   │       ├── mysql.sh
│   │       ├── redis.sh
│   │       └── rabbitmq.sh
│   ├── alb/                      # Application Load Balancer
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── route53/                  # DNS records
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── scripts/
│   ├── common.sh                 # Shared functions for user-data
│   ├── install-nodejs.sh
│   ├── install-java.sh
│   ├── install-python.sh
│   ├── install-golang.sh
│   └── setup-monitoring.sh
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml    # PR validation
│       ├── terraform-apply.yml   # Deploy to environments
│       └── destroy.yml           # Cleanup workflow
└── docs/
    ├── SETUP.md
    ├── DEPLOYMENT.md
    └── ARCHITECTURE.md
```

## Implementation Phases

### Phase 1: Foundation (Week 1)
- [x] Project structure setup
- [ ] VPC module with subnets, IGW, NAT
- [ ] Security groups for all services
- [ ] SSH key pair management
- [ ] Bastion host setup

### Phase 2: Database Layer (Week 1-2)
- [ ] MongoDB EC2 instance + installation script
- [ ] MySQL EC2 instance + installation script
- [ ] Redis EC2 instance + installation script
- [ ] RabbitMQ EC2 instance + installation script
- [ ] Route53 private hosted zone for internal DNS

### Phase 3: Application Layer (Week 2-3)
- [ ] Frontend (Nginx) EC2 + deployment script
- [ ] Catalogue service (Node.js)
- [ ] User service (Node.js)
- [ ] Cart service (Node.js)
- [ ] Shipping service (Java)
- [ ] Payment service (Python)
- [ ] Dispatch service (Go)

### Phase 4: Load Balancing & DNS (Week 3)
- [ ] Application Load Balancer for frontend
- [ ] Target groups and health checks
- [ ] Route53 public DNS (optional)

### Phase 5: Monitoring & Automation (Week 4)
- [ ] CloudWatch metrics and alarms
- [ ] SNS notifications
- [ ] GitHub Actions CI/CD pipeline
- [ ] Automated testing

### Phase 6: Documentation & Polish (Week 4)
- [ ] Comprehensive README
- [ ] Architecture diagrams
- [ ] Deployment guide
- [ ] Troubleshooting guide
- [ ] Cost analysis
- [ ] Demo screenshots/video

## Key Features for Portfolio

✅ **Infrastructure as Code**: Full Terraform implementation
✅ **Modular Design**: Reusable Terraform modules
✅ **Multi-Tier Architecture**: Web, App, Database tiers
✅ **Microservices**: 7 different microservices in different languages
✅ **Security Best Practices**: Security groups, private subnets, bastion host
✅ **High Availability**: Multi-AZ deployment (optional)
✅ **Automation**: User-data scripts for automatic service deployment
✅ **CI/CD**: GitHub Actions for infrastructure deployment
✅ **Monitoring**: CloudWatch integration
✅ **Cost Optimization**: Right-sized instances, auto-shutdown scripts
✅ **Documentation**: Production-ready documentation

## Estimated AWS Costs

**Monthly Cost Estimate (US-East-1):**
- 12x t3.micro instances (24/7): ~$90/month
- 1x NAT Gateway: ~$32/month
- Application Load Balancer: ~$16/month
- Data transfer: ~$10/month
- **Total: ~$150/month**

**Cost Savings:**
- Use t3.micro for most services (~$7.50/month each)
- Implement auto-shutdown for non-prod hours (save 70%)
- Use Terraform destroy when not in use
- **Development Cost: ~$30-50/month** (with smart scheduling)

## Success Metrics

This portfolio project demonstrates:
1. **Terraform Expertise**: Modular IaC design
2. **AWS Knowledge**: VPC, EC2, Security Groups, ALB, Route53
3. **Microservices Architecture**: Multi-language, distributed systems
4. **DevOps Practices**: Automation, CI/CD, monitoring
5. **Security Awareness**: Network segmentation, security groups
6. **Problem Solving**: Debugging distributed systems
7. **Documentation**: Clear, professional documentation

## Next Steps

1. **Create GitHub repository**: `roboshop-terraform-aws`
2. **Set up AWS account**: Free tier eligible for initial testing
3. **Configure Terraform backend**: S3 + DynamoDB for state
4. **Start with VPC module**: Foundation for everything
5. **Deploy incrementally**: Test each component individually
6. **Document as you go**: README, architecture diagrams
7. **Add to portfolio**: LinkedIn, resume, GitHub showcase

Let's start building! 🚀
