# CloudMart Quick Start Guide

Get up and running with CloudMart in under 30 minutes!

## 🎯 What You'll Build

A working local e-commerce platform with:
- Product catalog service (API)
- MongoDB database
- PostgreSQL database
- Redis cache
- Nginx API gateway
- Monitoring with Prometheus & Grafana

## 📋 Prerequisites

Before starting, ensure you have:

```bash
# Check Docker
docker --version
# Should be >= 20.10

# Check Docker Compose
docker-compose --version
# Should be >= 2.0

# Check Git
git --version

# Check Node.js (optional, for local development)
node --version
# Should be >= 18.0
```

If you don't have these installed:

**Docker & Docker Compose:**
```bash
# Linux
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in

# macOS
brew install --cask docker

# Windows
# Download Docker Desktop from docker.com
```

**Node.js:**
```bash
# Using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18
```

## 🚀 Quick Start (5 Minutes)

### 1. Clone and Navigate

```bash
# Clone the repository
git clone <your-repo-url>
cd cloudmart

# Or if you're starting fresh
mkdir cloudmart
cd cloudmart
# Copy the project files here
```

### 2. Start All Services

```bash
# Start everything with Docker Compose
docker-compose up -d

# This starts:
# - MongoDB on port 27017
# - PostgreSQL on port 5432
# - Redis on port 6379
# - Product Service on port 3001
# - Nginx Gateway on port 8080
# - Prometheus on port 9090
# - Grafana on port 3000
```

### 3. Verify Services

```bash
# Check all containers are running
docker-compose ps

# Should show 8 services running:
# mongodb, postgres, redis, product-service, nginx, prometheus, grafana
```

### 4. Test the API

```bash
# Health check
curl http://localhost:8080/api/products/health

# Create a sample product
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Wireless Mouse",
    "description": "Ergonomic wireless mouse with USB receiver",
    "price": 29.99,
    "category": "Electronics",
    "stock": 100,
    "sku": "WM-001"
  }'

# Get all products
curl http://localhost:8080/api/products

# Search products
curl "http://localhost:8080/api/products?category=Electronics&limit=10"
```

### 5. Access Monitoring

**Grafana** (Visualization):
- URL: http://localhost:3000
- Username: `admin`
- Password: `admin`

**Prometheus** (Metrics):
- URL: http://localhost:9090

## 📊 Sample Data Setup

Let's add some products to make it interesting:

```bash
# Create a script to add sample data
cat > add-sample-data.sh << 'EOF'
#!/bin/bash

BASE_URL="http://localhost:8080/api/products"

# Electronics
curl -X POST $BASE_URL -H "Content-Type: application/json" -d '{
  "name": "Laptop", "description": "15-inch laptop with 16GB RAM",
  "price": 899.99, "category": "Electronics", "stock": 50, "sku": "LT-001"
}'

curl -X POST $BASE_URL -H "Content-Type: application/json" -d '{
  "name": "Smartphone", "description": "Latest model with 5G",
  "price": 699.99, "category": "Electronics", "stock": 100, "sku": "SP-001"
}'

curl -X POST $BASE_URL -H "Content-Type: application/json" -d '{
  "name": "Headphones", "description": "Noise-cancelling wireless headphones",
  "price": 199.99, "category": "Electronics", "stock": 75, "sku": "HP-001"
}'

# Books
curl -X POST $BASE_URL -H "Content-Type: application/json" -d '{
  "name": "The DevOps Handbook", "description": "Guide to DevOps practices",
  "price": 29.99, "category": "Books", "stock": 200, "sku": "BK-001"
}'

curl -X POST $BASE_URL -H "Content-Type: application/json" -d '{
  "name": "Clean Code", "description": "A handbook of agile software craftsmanship",
  "price": 34.99, "category": "Books", "stock": 150, "sku": "BK-002"
}'

# Clothing
curl -X POST $BASE_URL -H "Content-Type: application/json" -d '{
  "name": "T-Shirt", "description": "Cotton crew neck t-shirt",
  "price": 19.99, "category": "Clothing", "stock": 300, "sku": "CL-001"
}'

echo "✅ Sample data added!"
EOF

chmod +x add-sample-data.sh
./add-sample-data.sh
```

## 🔍 Explore the Data

```bash
# View all products
curl http://localhost:8080/api/products | jq

# Filter by category
curl "http://localhost:8080/api/products?category=Electronics" | jq

# Search
curl "http://localhost:8080/api/products?search=laptop" | jq

# Price range
curl "http://localhost:8080/api/products?minPrice=20&maxPrice=100" | jq

# Pagination
curl "http://localhost:8080/api/products?page=1&limit=5" | jq
```

## 🛠️ Development Workflow

### Making Changes to Product Service

```bash
# The service uses hot-reload, so changes are automatic

# Edit the file
vim services/product-service/index.js

# Watch logs
docker-compose logs -f product-service

# Restart if needed
docker-compose restart product-service
```

### Direct Database Access

**MongoDB:**
```bash
# Connect to MongoDB
docker-compose exec mongodb mongosh cloudmart

# List products
db.products.find().pretty()

# Count products
db.products.countDocuments()

# Exit
exit
```

**PostgreSQL:**
```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U cloudmart_admin -d cloudmart

# List tables
\dt

# Query users (once user service is implemented)
SELECT * FROM users;

# Exit
\q
```

**Redis:**
```bash
# Connect to Redis
docker-compose exec redis redis-cli

# View keys
KEYS *

# Get value
GET cart:user123

# Exit
exit
```

## 📈 Monitoring & Metrics

### View Product Service Metrics

```bash
# Raw Prometheus metrics
curl http://localhost:3001/metrics

# Specific metrics
curl http://localhost:3001/metrics | grep http_request
```

### Grafana Dashboard

1. Go to http://localhost:3000
2. Login with `admin` / `admin`
3. Add Prometheus data source:
   - Configuration → Data Sources → Add data source
   - Select Prometheus
   - URL: `http://prometheus:9090`
   - Save & Test
4. Import dashboard:
   - Create → Import
   - Use dashboard ID: `1860` (Node Exporter Full)

## 🧪 Running Tests

```bash
# Run tests for Product Service
cd services/product-service
npm install
npm test

# Run with coverage
npm test -- --coverage

# Watch mode for development
npm run test:watch
```

## 🐛 Troubleshooting

### Containers Not Starting

```bash
# Check logs
docker-compose logs

# Check specific service
docker-compose logs product-service

# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Port Already in Use

```bash
# Find what's using port 8080
lsof -i :8080
# or
netstat -tulpn | grep 8080

# Kill the process or change port in docker-compose.yml
```

### Database Connection Issues

```bash
# Check if MongoDB is running
docker-compose ps mongodb

# Restart MongoDB
docker-compose restart mongodb

# Check MongoDB logs
docker-compose logs mongodb
```

### Clear All Data and Start Fresh

```bash
# Stop and remove everything
docker-compose down -v

# Remove all volumes (this deletes all data!)
docker volume prune -f

# Start fresh
docker-compose up -d
```

## 🔄 Common Tasks

### Update a Service

```bash
# Make changes to code
vim services/product-service/index.js

# Rebuild and restart
docker-compose up -d --build product-service
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f product-service

# Last 100 lines
docker-compose logs --tail=100 product-service
```

### Stop Everything

```bash
# Stop all services
docker-compose stop

# Stop and remove containers
docker-compose down

# Stop and remove containers + volumes (deletes data!)
docker-compose down -v
```

### Health Checks

```bash
# Create a health check script
cat > health-check.sh << 'EOF'
#!/bin/bash

echo "🔍 Checking service health..."

services=(
  "http://localhost:8080:Nginx Gateway"
  "http://localhost:3001/health:Product Service"
  "http://localhost:9090:Prometheus"
  "http://localhost:3000:Grafana"
)

for service in "${services[@]}"; do
  url="${service%%:*}"
  name="${service#*:}"
  
  if curl -sf "$url" > /dev/null 2>&1; then
    echo "✅ $name"
  else
    echo "❌ $name"
  fi
done
EOF

chmod +x health-check.sh
./health-check.sh
```

## 🎓 Learning Path

Now that you have it running locally, here's what to explore next:

1. **Week 1**: Understand the Product Service code
   - Read `services/product-service/index.js`
   - Modify endpoints
   - Add new features

2. **Week 2**: Build the User Service
   - Copy Product Service as template
   - Implement authentication
   - Connect to PostgreSQL

3. **Week 3**: Build the Cart Service
   - Implement Redis caching
   - Session management
   - Cart operations

4. **Week 4**: Deploy to AWS
   - Follow `docs/SETUP.md`
   - Deploy infrastructure with Terraform
   - Deploy to EKS

5. **Week 5**: Advanced topics
   - Service mesh
   - Advanced monitoring
   - Security hardening

## 📚 Additional Resources

- [Product Service API Docs](./services/product-service/README.md)
- [Full Setup Guide](./docs/SETUP.md)
- [Development Roadmap](./docs/ROADMAP.md)
- [Architecture Overview](./README.md)

## 🆘 Getting Help

If you run into issues:

1. Check the troubleshooting section above
2. Review logs: `docker-compose logs`
3. Verify prerequisites are met
4. Check GitHub Issues (if repository is public)

---

**Next Step**: Once comfortable with local development, move to [AWS Deployment Guide](./docs/SETUP.md) to deploy to production! 🚀
