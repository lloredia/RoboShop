# CloudMart - Complete Setup Guide

This guide will walk you through setting up the CloudMart e-commerce platform from scratch.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [AWS Infrastructure Setup](#aws-infrastructure-setup)
3. [Database Setup](#database-setup)
4. [Service Deployment](#service-deployment)
5. [Monitoring Setup](#monitoring-setup)
6. [CI/CD Configuration](#cicd-configuration)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
```bash
# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform_1.6.6_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### AWS Account Setup
```bash
# Configure AWS credentials
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json

# Verify credentials
aws sts get-caller-identity
```

## AWS Infrastructure Setup

### Step 1: Deploy VPC and Networking

```bash
cd infrastructure/terraform/environments/dev

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Save important outputs
terraform output -json > terraform-outputs.json
```

Expected resources created:
- VPC with CIDR 10.0.0.0/16
- 3 Public subnets
- 3 Private subnets
- 3 Database subnets
- Internet Gateway
- NAT Gateways (3)
- Route tables
- VPC Flow Logs

### Step 2: Deploy EKS Cluster

The EKS cluster is created in the same Terraform apply above. Wait for completion (15-20 minutes).

```bash
# Configure kubectl to use the new cluster
aws eks update-kubeconfig --region us-east-1 --name cloudmart-dev-eks

# Verify cluster access
kubectl get nodes
kubectl cluster-info
```

### Step 3: Deploy Databases

RDS PostgreSQL and ElastiCache Redis are created by Terraform. Verify:

```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier cloudmart-dev-postgres

# Check ElastiCache status
aws elasticache describe-cache-clusters --cache-cluster-id cloudmart-dev-redis

# Get database endpoints
terraform output rds_endpoint
terraform output redis_endpoint
```

## Database Setup

### PostgreSQL Schema Setup

```bash
# Get DB credentials from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id cloudmart/dev/database/postgres \
  --query SecretString \
  --output text | jq -r

# Connect to PostgreSQL (replace with actual endpoint)
psql -h <RDS_ENDPOINT> -U cloudmart_admin -d cloudmart

# Create schemas
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS orders;
CREATE SCHEMA IF NOT EXISTS payments;

# Create users table
CREATE TABLE users.profiles (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  username VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

# Create orders table
CREATE TABLE orders.orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users.profiles(id),
  total_amount DECIMAL(10, 2) NOT NULL,
  status VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### MongoDB Setup

MongoDB will be deployed as DocumentDB or as a StatefulSet in Kubernetes. For development, use a StatefulSet:

```bash
# Apply MongoDB StatefulSet
kubectl apply -f databases/mongodb/mongodb-statefulset.yaml

# Wait for MongoDB to be ready
kubectl wait --for=condition=ready pod -l app=mongodb -n cloudmart --timeout=300s

# Initialize replica set (if using replica set)
kubectl exec -it mongodb-0 -n cloudmart -- mongosh --eval "rs.initiate()"
```

## Service Deployment

### Step 1: Create Kubernetes Secrets

```bash
# Create namespace
kubectl apply -f infrastructure/kubernetes/namespaces/cloudmart.yaml

# Create MongoDB secret
kubectl create secret generic mongodb-credentials \
  -n cloudmart \
  --from-literal=connection-string="mongodb://mongodb-0.mongodb.cloudmart.svc.cluster.local:27017/cloudmart"

# Create PostgreSQL secret
kubectl create secret generic postgres-credentials \
  -n cloudmart \
  --from-literal=host="<RDS_ENDPOINT>" \
  --from-literal=database="cloudmart" \
  --from-literal=username="cloudmart_admin" \
  --from-literal=password="<PASSWORD>"

# Create Redis secret
kubectl create secret generic redis-credentials \
  -n cloudmart \
  --from-literal=host="<REDIS_ENDPOINT>" \
  --from-literal=port="6379"
```

### Step 2: Build and Push Service Images

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build Product Service
cd services/product-service
docker build -f docker/Dockerfile -t cloudmart/product-service:v1.0.0 .

# Tag and push
ECR_REGISTRY=<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
docker tag cloudmart/product-service:v1.0.0 $ECR_REGISTRY/cloudmart/product-service:v1.0.0
docker push $ECR_REGISTRY/cloudmart/product-service:v1.0.0

# Repeat for other services...
```

### Step 3: Deploy Services to Kubernetes

```bash
# Update deployment files with correct image URIs
export ECR_REGISTRY=<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
export IMAGE_TAG=v1.0.0

# Deploy Product Service
envsubst < infrastructure/kubernetes/deployments/product-service.yaml | kubectl apply -f -

# Verify deployment
kubectl get pods -n cloudmart
kubectl get svc -n cloudmart

# Check logs
kubectl logs -f deployment/product-service -n cloudmart
```

## Monitoring Setup

### Prometheus and Grafana

```bash
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace cloudmart-monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Install Grafana (included in above)
# Get Grafana password
kubectl get secret --namespace cloudmart-monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port forward to access Grafana
kubectl port-forward -n cloudmart-monitoring svc/prometheus-grafana 3000:80
# Access at http://localhost:3000 (admin / <password from above>)
```

### ELK Stack

```bash
# Add Elastic Helm repo
helm repo add elastic https://helm.elastic.co
helm repo update

# Install Elasticsearch
helm install elasticsearch elastic/elasticsearch \
  --namespace cloudmart-monitoring \
  --set replicas=1 \
  --set minimumMasterNodes=1

# Install Kibana
helm install kibana elastic/kibana \
  --namespace cloudmart-monitoring

# Install Filebeat
helm install filebeat elastic/filebeat \
  --namespace cloudmart-monitoring
```

## CI/CD Configuration

### GitHub Secrets Setup

Add these secrets to your GitHub repository:

```
AWS_ACCESS_KEY_ID: <Your AWS Access Key>
AWS_SECRET_ACCESS_KEY: <Your AWS Secret Key>
ECR_REGISTRY: <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
SLACK_WEBHOOK: <Optional Slack webhook for notifications>
```

### Trigger First Deployment

```bash
# Make a change and push
git add .
git commit -m "Initial deployment"
git push origin develop

# GitHub Actions will automatically:
# 1. Run tests
# 2. Security scans
# 3. Build Docker images
# 4. Push to ECR
# 5. Deploy to dev environment
```

## Testing

### Health Checks

```bash
# Test Product Service
kubectl port-forward -n cloudmart svc/product-service 8080:80

# In another terminal
curl http://localhost:8080/health
curl http://localhost:8080/ready
curl http://localhost:8080/metrics
```

### API Testing

```bash
# Create a product
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "description": "A test product",
    "price": 29.99,
    "category": "electronics",
    "stock": 100,
    "sku": "TEST-001"
  }'

# Get all products
curl http://localhost:8080/api/products

# Get specific product
curl http://localhost:8080/api/products/<ID>
```

### Load Testing

```bash
# Install k6
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# Run load test
k6 run tests/load/product-service-load-test.js
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n cloudmart

# Describe pod for events
kubectl describe pod <POD_NAME> -n cloudmart

# Check logs
kubectl logs <POD_NAME> -n cloudmart

# Check previous container logs if crashed
kubectl logs <POD_NAME> -n cloudmart --previous
```

### Database Connection Issues

```bash
# Test from within cluster
kubectl run -it --rm debug --image=busybox --restart=Never -n cloudmart -- sh

# Test DNS resolution
nslookup mongodb-0.mongodb.cloudmart.svc.cluster.local

# Test connectivity
telnet <RDS_ENDPOINT> 5432
```

### Image Pull Errors

```bash
# Verify ECR permissions
aws ecr get-login-password --region us-east-1

# Check if image exists
aws ecr describe-images --repository-name cloudmart/product-service

# Verify node IAM role has ECR permissions
kubectl describe node
```

### Service Not Accessible

```bash
# Check service
kubectl get svc -n cloudmart

# Check endpoints
kubectl get endpoints -n cloudmart

# Port forward to test
kubectl port-forward -n cloudmart svc/product-service 8080:80
```

## Next Steps

1. **Add More Services**: Follow the same pattern for User, Cart, Order, Payment, and Notification services
2. **Setup API Gateway**: Deploy Kong or AWS API Gateway for external access
3. **Configure Domain**: Setup Route53 and SSL certificates
4. **Implement Authentication**: Add JWT auth with OAuth2
5. **Add Caching**: Implement Redis caching strategies
6. **Setup Backups**: Configure automated database backups
7. **Disaster Recovery**: Implement multi-region failover
8. **Cost Optimization**: Review and optimize resource usage

## Support

For issues or questions:
- GitHub Issues: <repository-url>/issues
- Documentation: `docs/` directory
- Runbooks: `docs/runbooks/`

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.
