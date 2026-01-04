#!/bin/bash

# Create main directories
mkdir -p infrastructure/{terraform,kubernetes,helm}
mkdir -p services/{frontend,product-service,user-service,cart-service,order-service,payment-service,notification-service}
mkdir -p databases/{postgres,mongodb,redis,elasticsearch}
mkdir -p cicd/{github-actions,scripts}
mkdir -p monitoring/{prometheus,grafana,elk}
mkdir -p docs/{architecture,api-specs,runbooks}

# Create subdirectories for Terraform
mkdir -p infrastructure/terraform/{modules,environments/{dev,staging,prod}}
mkdir -p infrastructure/terraform/modules/{vpc,compute,database,storage,security}

# Create subdirectories for Kubernetes
mkdir -p infrastructure/kubernetes/{namespaces,services,deployments,configmaps,secrets}

# Create subdirectories for each service
for service in frontend product-service user-service cart-service order-service payment-service notification-service; do
  mkdir -p services/$service/{src,tests,docker,.github}
done

# Create database setup directories
for db in postgres mongodb redis elasticsearch; do
  mkdir -p databases/$db/{init-scripts,config}
done

echo "Project structure created successfully!"
