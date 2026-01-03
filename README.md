                              ![Alt text](https://avatars.githubusercontent.com/u/5128994?v=4)

          # RoboShop


# CloudMart - Cloud-Native E-Commerce Platform

A production-ready microservices-based e-commerce platform built with DevOps best practices.

## 🏗️ Architecture Overview

CloudMart is a multi-tier application demonstrating modern cloud-native architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                        Load Balancer                         │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
   ┌────▼────┐          ┌─────▼─────┐         ┌────▼────┐
   │ Frontend│          │ API Gateway│         │  Admin  │
   │  (Nginx)│          │            │         │   UI    │
   └─────────┘          └─────┬─────┘         └─────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
   ┌────▼────┐          ┌─────▼─────┐         ┌────▼────┐
   │ Product │          │   User    │         │  Cart   │
   │ Service │          │  Service  │         │ Service │
   └────┬────┘          └─────┬─────┘         └────┬────┘
        │                     │                     │
   ┌────▼────┐          ┌─────▼─────┐         ┌────▼────┐
   │ MongoDB │          │PostgreSQL │         │  Redis  │
   └─────────┘          └───────────┘         └─────────┘
```

## 📦 Components

### Frontend Layer (1)
- **frontend**: React SPA with Nginx reverse proxy

### Application Layer (6 Microservices)
1. **product-service**: Product catalog management (Node.js + MongoDB)
2. **user-service**: Authentication & user management (Node.js + PostgreSQL)
3. **cart-service**: Shopping cart operations (Node.js + Redis)
4. **order-service**: Order processing & fulfillment (Python + PostgreSQL)
5. **payment-service**: Payment gateway integration (Python)
6. **notification-service**: Email/SMS notifications (Go)

### Data Layer (4 Databases)
1. **PostgreSQL**: Relational data (users, orders, transactions)
2. **MongoDB**: Product catalog, reviews, ratings
3. **Redis**: Session management, caching, cart data
4. **Elasticsearch**: Search indexing and analytics

## 🛠️ Technology Stack

### Infrastructure
- **Cloud Provider**: AWS
- **IaC**: Terraform
- **Orchestration**: Kubernetes (EKS)
- **Container Runtime**: Docker

### CI/CD
- **Version Control**: GitHub
- **CI/CD**: GitHub Actions
- **Container Registry**: ECR
- **Artifact Storage**: S3

### Observability
- **Metrics**: Prometheus + Grafana
- **Logging**: ELK Stack (Elasticsearch, Logstash, Kibana)
- **Tracing**: Jaeger
- **Monitoring**: CloudWatch

### Security
- **Secrets**: AWS Secrets Manager
- **Network**: VPC, Security Groups, NACLs
- **TLS/SSL**: AWS Certificate Manager
- **Image Scanning**: Trivy

## 📂 Project Structure

```
cloudmart/
├── infrastructure/          # Terraform IaC
│   ├── modules/            # Reusable Terraform modules
│   │   ├── vpc/
│   │   ├── eks/
│   │   ├── rds/
│   │   └── elasticache/
│   ├── environments/       # Environment-specific configs
│   │   ├── staging/
│   │   └── production/
│   └── backend.tf          # Terraform state configuration
│
├── services/               # Microservices
│   ├── product-service/
│   ├── user-service/
│   ├── cart-service/
│   ├── order-service/
│   ├── payment-service/
│   └── notification-service/
│
├── frontend/               # React application
│
├── k8s/                    # Kubernetes manifests
│   ├── base/              # Base configurations
│   ├── overlays/          # Kustomize overlays
│   │   ├── staging/
│   │   └── production/
│   └── helm-charts/       # Helm charts
│
├── .github/               # GitHub Actions workflows
│   └── workflows/
│       ├── build-test.yml
│       ├── deploy-staging.yml
│       └── deploy-production.yml
│
├── monitoring/            # Observability stack
│   ├── prometheus/
│   ├── grafana/
│   └── elk/
│
├── databases/            # Database schemas & migrations
│   ├── postgresql/
│   ├── mongodb/
│   └── redis/
│
└── docs/                 # Documentation
    ├── architecture.md
    ├── deployment.md
    └── api-specs/
```

## 🚀 Getting Started

### Prerequisites
- AWS Account with appropriate permissions
- Terraform >= 1.5
- kubectl >= 1.28
- Docker >= 24.0
- Node.js >= 18 (for services)
- Python >= 3.11 (for services)
- Go >= 1.21 (for notification service)

### Quick Start

1. **Clone the repository**
```bash
git clone <your-repo-url>
cd cloudmart
```

2. **Set up infrastructure**
```bash
cd infrastructure/environments/staging
terraform init
terraform plan
terraform apply
```

3. **Configure kubectl**
```bash
aws eks update-kubeconfig --name cloudmart-staging --region us-east-1
```

4. **Deploy services**
```bash
cd ../../../k8s/overlays/staging
kubectl apply -k .
```

5. **Verify deployment**
```bash
kubectl get pods -n cloudmart
kubectl get svc -n cloudmart
```

## 🔄 Development Workflow

1. Create feature branch from `main`
2. Develop and test locally with Docker Compose
3. Push to GitHub - triggers CI pipeline
4. PR merged to `main` - deploys to staging
5. Tag release - deploys to production

## 📊 Monitoring & Observability

- **Grafana Dashboard**: `http://<grafana-url>:3000`
- **Kibana**: `http://<kibana-url>:5601`
- **Prometheus**: `http://<prometheus-url>:9090`
- **Jaeger UI**: `http://<jaeger-url>:16686`

## 🔐 Security Best Practices

- All secrets managed via AWS Secrets Manager
- Network isolation with VPC and security groups
- TLS encryption for all external traffic
- Container image scanning in CI pipeline
- Regular dependency updates via Dependabot
- RBAC enabled in Kubernetes
- Pod security policies enforced

## 🧪 Testing Strategy

- **Unit Tests**: Jest (Node.js), pytest (Python), go test (Go)
- **Integration Tests**: Docker Compose environment
- **Load Tests**: k6 or Locust
- **Security Tests**: OWASP ZAP, Trivy
- **End-to-End Tests**: Playwright

## 📈 Scalability

- Horizontal Pod Autoscaling (HPA) configured
- Cluster Autoscaler for node management
- Database read replicas
- Redis cluster for cache
- CDN for static assets

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License - see LICENSE file for details.

## 📧 Contact

Project Maintainer - Your Name
Project Link: https://github.com/yourusername/cloudmart

---

**Built with ❤️ as a DevOps portfolio project**
