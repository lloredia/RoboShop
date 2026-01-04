# Service Template Guide

Use this template to create new microservices following CloudMart patterns.

## Creating a New Service

### 1. Directory Structure

```bash
services/your-service/
├── src/
│   └── index.js (or main.py, main.go)
├── tests/
│   ├── unit/
│   └── integration/
├── docker/
│   ├── Dockerfile
│   └── .dockerignore
├── .github/
│   └── workflows/
│       └── ci-cd.yml
├── package.json (or requirements.txt, go.mod)
├── .env.example
└── README.md
```

### 2. Service Template (Node.js)

```javascript
// services/your-service/src/index.js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const promClient = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3000;

// Prometheus setup
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const httpRequestCounter = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status'],
  registers: [register]
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Health endpoints
app.get('/health', (req, res) => {
  res.status(200).json({
    uptime: process.uptime(),
    message: 'OK',
    timestamp: Date.now()
  });
});

app.get('/ready', async (req, res) => {
  // Add dependency checks (DB, cache, etc.)
  res.status(200).json({ status: 'ready' });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Your API routes here
app.get('/api/your-resource', async (req, res) => {
  try {
    // Your logic
    res.json({ message: 'Success' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

const server = app.listen(PORT, () => {
  console.log(`Service running on port ${PORT}`);
});

module.exports = app;
```

### 3. Service Template (Python/FastAPI)

```python
# services/your-service/src/main.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
import uvicorn
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Your Service",
    description="Service description",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus metrics
Instrumentator().instrument(app).expose(app)

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.get("/ready")
async def ready():
    # Add dependency checks
    return {"status": "ready"}

@app.get("/api/your-resource")
async def get_resource():
    try:
        # Your logic
        return {"message": "Success"}
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### 4. Dockerfile Template

```dockerfile
# Multi-stage Dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-alpine
RUN apk add --no-cache dumb-init
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
WORKDIR /app
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs . .
USER nodejs
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "src/index.js"]
```

### 5. Kubernetes Deployment Template

```yaml
# infrastructure/kubernetes/deployments/your-service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: your-service
  namespace: cloudmart
  labels:
    app: your-service
    tier: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: your-service
  template:
    metadata:
      labels:
        app: your-service
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "3000"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: your-service
        image: ${ECR_REGISTRY}/cloudmart/your-service:${IMAGE_TAG}
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: your-service
  namespace: cloudmart
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 3000
  selector:
    app: your-service
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: your-service
  namespace: cloudmart
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: your-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 6. GitHub Actions Template

```yaml
# .github/workflows/your-service.yml
name: Your Service CI/CD

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'services/your-service/**'
  pull_request:
    branches: [ main, develop ]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: cloudmart/your-service

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: '20'
    - run: npm ci
      working-directory: services/your-service
    - run: npm test
      working-directory: services/your-service

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    steps:
    - uses: actions/checkout@v4
    - uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
    - uses: aws-actions/amazon-ecr-login@v2
    - uses: docker/build-push-action@v5
      with:
        context: services/your-service
        push: true
        tags: ${{ env.ECR_REPOSITORY }}:${{ github.sha }}
```

## Service Checklist

When creating a new service, ensure:

### Code Quality
- [ ] Linting configured (ESLint, Pylint, golangci-lint)
- [ ] Code formatting (Prettier, Black, gofmt)
- [ ] Unit tests with >80% coverage
- [ ] Integration tests
- [ ] Error handling implemented
- [ ] Logging configured

### API Design
- [ ] RESTful endpoints
- [ ] Request validation
- [ ] Response pagination
- [ ] Proper HTTP status codes
- [ ] API documentation (OpenAPI/Swagger)

### Security
- [ ] Input validation and sanitization
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] Rate limiting
- [ ] Authentication/authorization
- [ ] Secrets from environment variables
- [ ] Non-root container user

### Observability
- [ ] Health check endpoint (/health)
- [ ] Readiness check endpoint (/ready)
- [ ] Metrics endpoint (/metrics)
- [ ] Structured logging
- [ ] Request/response logging
- [ ] Error tracking

### Performance
- [ ] Connection pooling
- [ ] Caching strategy
- [ ] Query optimization
- [ ] Resource limits defined
- [ ] Graceful shutdown

### DevOps
- [ ] Dockerfile optimized
- [ ] .dockerignore configured
- [ ] Multi-stage build
- [ ] Health checks in Docker
- [ ] CI/CD pipeline configured
- [ ] Auto-scaling configured

### Documentation
- [ ] README with service description
- [ ] API documentation
- [ ] Environment variables documented
- [ ] Local development guide
- [ ] Deployment guide

## Environment Variables Pattern

```bash
# Required
PORT=3000
NODE_ENV=production

# Database
DATABASE_URL=postgresql://user:pass@host:5432/db
MONGODB_URI=mongodb://host:27017/db
REDIS_URL=redis://host:6379

# External Services
API_KEY=xxx
SERVICE_URL=http://other-service

# Feature Flags
FEATURE_X_ENABLED=true

# Logging
LOG_LEVEL=info
```

## Testing Pattern

```javascript
// tests/unit/example.test.js
const request = require('supertest');
const app = require('../src/index');

describe('GET /health', () => {
  it('should return 200', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('message', 'OK');
  });
});
```

## Database Migration Pattern

```javascript
// migrations/001_create_table.js
exports.up = async (db) => {
  await db.schema.createTable('your_table', (table) => {
    table.increments('id').primary();
    table.string('name').notNullable();
    table.timestamps(true, true);
  });
};

exports.down = async (db) => {
  await db.schema.dropTable('your_table');
};
```

## Common Patterns

### Database Connection
```javascript
const { Pool } = require('pg');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
});
```

### Error Handling
```javascript
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
  }
}

// Usage
throw new AppError('Not found', 404);
```

### Middleware
```javascript
const authMiddleware = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) throw new AppError('Unauthorized', 401);
    // Verify token
    next();
  } catch (error) {
    next(error);
  }
};
```

## Resources

- Node.js Best Practices: https://github.com/goldbergyoni/nodebestpractices
- Go Standards: https://github.com/golang-standards/project-layout
- Python Guide: https://docs.python-guide.org/
- 12 Factor App: https://12factor.net/
