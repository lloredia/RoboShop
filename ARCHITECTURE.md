# CloudMart Architecture Overview

## System Architecture

CloudMart is built using a microservices architecture pattern, deployed on AWS using Kubernetes (EKS) for container orchestration.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         End Users                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   CloudFront CDN                                 │
│                   (Static Assets)                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              Application Load Balancer (ALB)                     │
│                  (SSL Termination)                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
┌─────────────────┐             ┌─────────────────┐
│   API Gateway   │             │    Frontend     │
│   (Kong/AWS)    │             │  (React SPA)    │
└────────┬────────┘             └─────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EKS Cluster (Kubernetes)                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   Application Tier                        │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐         │  │
│  │  │  Product   │  │    User    │  │    Cart    │         │  │
│  │  │  Service   │  │  Service   │  │  Service   │         │  │
│  │  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘         │  │
│  │         │                │                │               │  │
│  │  ┌──────┴─────┐  ┌──────┴─────┐  ┌──────┴─────┐         │  │
│  │  │   Order    │  │  Payment   │  │Notification│         │  │
│  │  │  Service   │  │  Service   │  │  Service   │         │  │
│  │  └────────────┘  └────────────┘  └────────────┘         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     Data Tier                             │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐         │  │
│  │  │ PostgreSQL │  │  MongoDB   │  │   Redis    │         │  │
│  │  │    (RDS)   │  │(DocumentDB)│  │(ElastiCache)│        │  │
│  │  └────────────┘  └────────────┘  └────────────┘         │  │
│  │                                                            │  │
│  │  ┌────────────────────────────────────────────┐          │  │
│  │  │          Elasticsearch                      │          │  │
│  │  │        (Search & Analytics)                 │          │  │
│  │  └────────────────────────────────────────────┘          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Monitoring & Observability                   │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐         │  │
│  │  │ Prometheus │  │  Grafana   │  │ ELK Stack  │         │  │
│  │  └────────────┘  └────────────┘  └────────────┘         │  │
│  │                                                            │  │
│  │  ┌────────────────────────────────────────────┐          │  │
│  │  │           Jaeger (Tracing)                  │          │  │
│  │  └────────────────────────────────────────────┘          │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Service Details

### Frontend Service
- **Technology**: React 18, TypeScript
- **Purpose**: User interface for e-commerce operations
- **Deployment**: Nginx serving static files
- **CDN**: CloudFront for global distribution
- **Features**:
  - Product browsing and search
  - Shopping cart management
  - User authentication
  - Order placement and tracking
  - Responsive design

### Product Service
- **Technology**: Node.js, Express
- **Database**: MongoDB
- **Purpose**: Product catalog management
- **Key Features**:
  - CRUD operations for products
  - Category management
  - Inventory tracking
  - Product search with Elasticsearch
  - Image management
- **API Endpoints**:
  - GET /api/products - List products with pagination/filtering
  - GET /api/products/:id - Get product details
  - POST /api/products - Create product
  - PUT /api/products/:id - Update product
  - DELETE /api/products/:id - Soft delete product
  - PATCH /api/products/:id/stock - Update inventory

### User Service
- **Technology**: Node.js, Express
- **Database**: PostgreSQL
- **Purpose**: User management and authentication
- **Key Features**:
  - User registration and login
  - JWT token generation and validation
  - Password hashing with bcrypt
  - Profile management
  - Address management
- **API Endpoints**:
  - POST /api/users/register
  - POST /api/users/login
  - GET /api/users/profile
  - PUT /api/users/profile
  - POST /api/users/addresses

### Cart Service
- **Technology**: Node.js, Express
- **Database**: Redis
- **Purpose**: Shopping cart management
- **Key Features**:
  - Session-based cart storage
  - Real-time cart updates
  - Cart persistence
  - Price calculation
- **API Endpoints**:
  - GET /api/cart
  - POST /api/cart/items
  - PUT /api/cart/items/:id
  - DELETE /api/cart/items/:id
  - DELETE /api/cart/clear

### Order Service
- **Technology**: Python, FastAPI
- **Database**: PostgreSQL
- **Purpose**: Order processing and management
- **Key Features**:
  - Order creation and validation
  - Order status tracking
  - Integration with payment service
  - Order history
  - Inventory validation
- **API Endpoints**:
  - POST /api/orders
  - GET /api/orders/:id
  - GET /api/orders/user/:userId
  - PATCH /api/orders/:id/status

### Payment Service
- **Technology**: Python, FastAPI
- **Database**: PostgreSQL
- **Purpose**: Payment processing
- **Key Features**:
  - Payment gateway integration
  - Transaction management
  - Payment verification
  - Refund processing
  - PCI compliance
- **API Endpoints**:
  - POST /api/payments/process
  - GET /api/payments/:id
  - POST /api/payments/refund
  - GET /api/payments/transaction/:transactionId

### Notification Service
- **Technology**: Go
- **Message Queue**: RabbitMQ
- **Purpose**: Asynchronous notifications
- **Key Features**:
  - Email notifications
  - SMS notifications (optional)
  - Push notifications
  - Event-driven architecture
  - Template management
- **Events Handled**:
  - User registration
  - Order confirmation
  - Order shipped
  - Payment confirmation
  - Password reset

## Data Layer

### PostgreSQL (Amazon RDS)
- **Used By**: User Service, Order Service, Payment Service
- **Schema Design**:
  - users.profiles
  - users.addresses
  - orders.orders
  - orders.order_items
  - payments.transactions
  - payments.refunds
- **Features**:
  - Multi-AZ deployment
  - Automated backups
  - Read replicas for scaling
  - Encryption at rest and in transit

### MongoDB (DocumentDB)
- **Used By**: Product Service
- **Collections**:
  - products
  - categories
  - reviews
  - product_images
- **Features**:
  - Schema flexibility for product variants
  - Horizontal scaling
  - Replica sets
  - Automated backups

### Redis (ElastiCache)
- **Used By**: All services
- **Use Cases**:
  - Session storage
  - Shopping cart data
  - Rate limiting
  - API response caching
  - Distributed locks
- **Features**:
  - In-memory performance
  - Cluster mode for scaling
  - Automatic failover
  - Snapshot backups

### Elasticsearch
- **Used By**: Product Service, Search Service
- **Purpose**:
  - Full-text product search
  - Analytics and aggregations
  - Log aggregation
  - Real-time indexing
- **Features**:
  - Distributed search
  - Relevance scoring
  - Faceted search
  - Auto-complete suggestions

## Infrastructure Components

### Networking
- **VPC**: 10.0.0.0/16
- **Public Subnets**: 3 across different AZs (for ALB, NAT)
- **Private Subnets**: 3 across different AZs (for EKS nodes)
- **Database Subnets**: 3 across different AZs (for RDS, DocumentDB)
- **NAT Gateways**: 3 (one per AZ) for HA
- **Internet Gateway**: 1 for public internet access

### Compute
- **EKS Cluster**: Kubernetes 1.28
- **Node Groups**:
  - General: t3.medium (2-5 nodes)
  - Spot: t3.medium/t3a.medium (0-3 nodes)
- **Auto Scaling**: HPA based on CPU/Memory

### Storage
- **EBS**: For persistent volumes
- **S3**: For static assets, backups, logs
- **ECR**: For Docker images

### Security
- **Security Groups**: Least privilege access
- **IAM Roles**: IRSA for pod-level permissions
- **Secrets Manager**: For credentials
- **KMS**: For encryption keys
- **Network Policies**: Pod-to-pod communication rules

## Observability

### Metrics (Prometheus + Grafana)
- **System Metrics**: CPU, memory, disk, network
- **Application Metrics**: Request rate, latency, errors
- **Business Metrics**: Orders, revenue, conversions
- **Custom Dashboards**: Per-service and system-wide views

### Logging (ELK Stack)
- **Elasticsearch**: Log storage and indexing
- **Logstash**: Log processing and enrichment
- **Kibana**: Log visualization and search
- **Filebeat**: Log shipping from containers

### Tracing (Jaeger)
- **Distributed Tracing**: Request flow across services
- **Performance Analysis**: Latency bottlenecks
- **Dependency Mapping**: Service relationships

### Alerting
- **Prometheus AlertManager**: Alert routing
- **PagerDuty**: On-call management
- **Slack**: Team notifications

## CI/CD Pipeline

### GitHub Actions
1. **Code Checkout**
2. **Dependency Installation**
3. **Linting & Code Quality**
4. **Unit Tests**
5. **Integration Tests**
6. **Security Scanning**:
   - Trivy for vulnerabilities
   - npm/pip audit for dependencies
   - SAST with SonarQube
7. **Docker Build**
8. **Image Scanning**
9. **Push to ECR**
10. **Deploy to Dev**
11. **Deploy to Staging**
12. **Manual Approval**
13. **Deploy to Production**
14. **Smoke Tests**
15. **Notifications**

### Deployment Strategy
- **Development**: Immediate deployment on merge to develop
- **Staging**: Automatic on merge to main
- **Production**: Manual approval + blue-green deployment

## Scalability

### Horizontal Scaling
- **Kubernetes HPA**: Auto-scale pods based on CPU/memory
- **Cluster Autoscaler**: Auto-scale nodes based on pod demands
- **Database Read Replicas**: Scale read operations

### Caching Strategy
- **Level 1**: Browser caching (static assets)
- **Level 2**: CloudFront CDN
- **Level 3**: Redis (application cache)
- **Level 4**: Database query cache

### Performance Optimizations
- **Connection Pooling**: Database connections
- **Lazy Loading**: Frontend components
- **Image Optimization**: WebP format, compression
- **API Response Compression**: gzip
- **Database Indexing**: Optimized queries

## Security

### Authentication & Authorization
- **JWT Tokens**: Stateless authentication
- **OAuth2**: Third-party login
- **RBAC**: Kubernetes role-based access
- **API Keys**: Service-to-service auth

### Data Protection
- **Encryption at Rest**: All databases
- **Encryption in Transit**: TLS/SSL everywhere
- **Secrets Management**: AWS Secrets Manager
- **PII Protection**: Data masking, encryption

### Network Security
- **WAF**: Web Application Firewall
- **DDoS Protection**: AWS Shield
- **Network Policies**: Pod communication rules
- **Security Groups**: Ingress/egress rules

## Disaster Recovery

### Backup Strategy
- **RDS**: Automated daily snapshots, 7-day retention
- **DocumentDB**: Point-in-time recovery
- **Redis**: Daily snapshots
- **Application State**: S3 versioning

### Recovery Objectives
- **RTO (Recovery Time Objective)**: 4 hours
- **RPO (Recovery Point Objective)**: 1 hour

### Multi-Region (Future)
- **Active-Passive**: Standby region for DR
- **Data Replication**: Cross-region database replication
- **DNS Failover**: Route53 health checks

## Cost Optimization

### Current Estimates (Development)
- **EKS**: ~$73/month (cluster) + node costs
- **RDS**: ~$30/month (db.t3.micro)
- **ElastiCache**: ~$15/month (cache.t3.micro)
- **NAT Gateways**: ~$100/month (3 gateways)
- **ECR**: ~$1/month
- **Total**: ~$250-350/month

### Optimization Strategies
- **Spot Instances**: For non-critical workloads
- **Reserved Instances**: For predictable workloads
- **Right-Sizing**: Monitor and adjust instance types
- **S3 Lifecycle**: Move old data to cheaper tiers
- **CloudWatch Logs**: Set retention policies

## Future Enhancements

1. **Service Mesh**: Istio for advanced traffic management
2. **GraphQL Gateway**: Unified API layer
3. **Event Sourcing**: CQRS pattern for orders
4. **Machine Learning**: Recommendation engine
5. **Mobile Apps**: Native iOS/Android
6. **Multi-Region**: Global deployment
7. **Serverless**: Lambda for specific workloads
8. **GitOps**: ArgoCD for deployments
