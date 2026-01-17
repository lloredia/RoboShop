# RoboShop Setup Guide

## Prerequisites

### 1. AWS Account Setup
- Create or use existing AWS account
- Configure billing alerts (recommended)
- Note: This project will incur AWS costs (~$30-150/month depending on usage)

### 2. Install Required Tools

```bash
# Terraform
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify
terraform version

# AWS CLI
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify
aws --version
```

### 3. Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: us-east-1
# - Default output format: json

# Test configuration
aws sts get-caller-identity
```

## Project Setup

### Step 1: Clone Repository

```bash
# If using your own repo
git clone https://github.com/yourusername/roboshop-terraform-aws.git
cd roboshop-terraform-aws

# Or if starting fresh
mkdir roboshop-terraform-aws
cd roboshop-terraform-aws
# Copy all files from this project
```

### Step 2: Generate SSH Key

```bash
# Generate new SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/roboshop -C "your-email@example.com"

# View public key (you'll need this for terraform.tfvars)
cat ~/.ssh/roboshop.pub
```

### Step 3: Configure Terraform Variables

```bash
cd terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars  # or vim, code, etc.
```

**Required changes in terraform.tfvars:**

1. **allowed_ssh_cidr**: Your public IP address
   ```bash
   # Find your IP
   curl ifconfig.me
   
   # Update in terraform.tfvars
   allowed_ssh_cidr = ["YOUR_IP/32"]
   ```

2. **ssh_public_key**: Content of ~/.ssh/roboshop.pub
   ```bash
   cat ~/.ssh/roboshop.pub
   # Copy entire output and paste in terraform.tfvars
   ```

3. **tags**: Update with your information
   ```hcl
   tags = {
     Project     = "RoboShop"
     Environment = "Development"
     ManagedBy   = "Terraform"
     Owner       = "Your Name"  # Change this
   }
   ```

### Step 4: Initialize Terraform

```bash
# Initialize Terraform
terraform init

# You should see:
# Terraform has been successfully initialized!
```

### Step 5: Validate Configuration

```bash
# Check for syntax errors
terraform validate

# Format code
terraform fmt -recursive

# Review what will be created
terraform plan
```

## First Deployment

### Deploy Infrastructure

```bash
# Apply configuration
terraform apply

# Review the plan
# Type 'yes' when prompted

# Wait 5-10 minutes for completion
```

### What Gets Created (Phase 1):

✅ VPC with CIDR 10.0.0.0/16
✅ 3 Subnets (Public, Private App, Private DB)
✅ Internet Gateway
✅ NAT Gateway
✅ Route Tables
✅ 13 Security Groups
✅ Bastion Host (with Elastic IP)
✅ SSH Key Pair

### Verify Deployment

```bash
# Get outputs
terraform output

# You should see:
# - VPC ID
# - Subnet IDs
# - Bastion Public IP
# - Security Group IDs
# - SSH connection command
```

### Connect to Bastion

```bash
# Use the SSH command from terraform output
ssh -i ~/.ssh/roboshop ec2-user@<BASTION_PUBLIC_IP>

# Or copy the exact command from output:
terraform output ssh_connection_command
```

## Cost Management

### Current Phase 1 Costs

**Monthly (24/7 operation):**
- Bastion (t3.micro): ~$7.50
- NAT Gateway: ~$32
- Elastic IP: ~$3.60
- **Total: ~$43/month**

### Cost Savings Tips

1. **Auto-Shutdown Script**
   ```bash
   # Stop instances when not in use
   aws ec2 stop-instances --instance-ids $(terraform output -raw bastion_instance_id)
   
   # Start when needed
   aws ec2 start-instances --instance-ids $(terraform output -raw bastion_instance_id)
   ```

2. **Destroy When Not Needed**
   ```bash
   # Complete teardown
   terraform destroy
   
   # Costs: $0/month
   # Re-deploy in 10 minutes when needed
   ```

3. **Use Scheduled Actions**
   - Stop instances at night (6 PM - 8 AM)
   - Stop on weekends
   - Save ~70% of costs

## Next Steps

### Phase 2: Add Database Servers

1. Create MongoDB instance
2. Create MySQL instance
3. Create Redis instance
4. Create RabbitMQ instance

### Phase 3: Add Application Servers

1. Frontend (Nginx)
2. Catalogue (Node.js)
3. User (Node.js)
4. Cart (Node.js)
5. Shipping (Java)
6. Payment (Python)
7. Dispatch (Go)

### Phase 4: Add Load Balancer

1. Application Load Balancer
2. Target Groups
3. Health Checks
4. Route53 DNS

## Troubleshooting

### Issue: "Error: creating EC2 Key Pair"

**Cause**: SSH key name already exists

**Solution**:
```bash
# Delete existing key
aws ec2 delete-key-pair --key-name roboshop-dev-key

# Or change project_name in terraform.tfvars
```

### Issue: "Error: creating VPC"

**Cause**: CIDR overlap or quota limit

**Solution**:
```bash
# Check existing VPCs
aws ec2 describe-vpcs

# Delete unused VPCs or change CIDR in terraform.tfvars
```

### Issue: "Error: creating NAT Gateway"

**Cause**: Elastic IP limit reached (default: 5)

**Solution**:
```bash
# Check EIP usage
aws ec2 describe-addresses

# Release unused EIPs or request limit increase
```

### Issue: Can't SSH to Bastion

**Cause**: Wrong IP in allowed_ssh_cidr

**Solution**:
```bash
# Check your current IP
curl ifconfig.me

# Update terraform.tfvars
# Re-apply
terraform apply
```

## Clean Up

### Destroy Everything

```bash
cd terraform

# Destroy all resources
terraform destroy

# Type 'yes' when prompted

# Verify everything is deleted
aws ec2 describe-instances --filters "Name=tag:Project,Values=RoboShop"
```

### Delete State Files (if starting fresh)

```bash
# Remove local state
rm -rf .terraform
rm terraform.tfstate*

# Re-initialize
terraform init
```

## Getting Help

1. **Check Terraform Logs**
   ```bash
   # Enable debug logging
   export TF_LOG=DEBUG
   terraform apply
   ```

2. **AWS Console**
   - Check EC2 Dashboard for instances
   - Check VPC Dashboard for network resources
   - Check CloudWatch for logs

3. **Common Commands**
   ```bash
   # Show state
   terraform show
   
   # List resources
   terraform state list
   
   # Get specific output
   terraform output vpc_id
   
   # Refresh state
   terraform refresh
   ```

## Next Document

After successful Phase 1 deployment, proceed to:
- **DEPLOYMENT.md** - Deploy applications and databases
- **ARCHITECTURE.md** - Understand design decisions
- **TROUBLESHOOTING.md** - Advanced debugging

---

**🎉 Congratulations! You've deployed the RoboShop foundation!**
