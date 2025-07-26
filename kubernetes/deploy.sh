#!/bin/bash

# LKS Kubernetes Deployment Script
# This script deploys applications to different environments

set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    echo "Available environments: staging, production, monitoring"
    exit 1
fi

echo "Deploying to environment: $ENVIRONMENT"

case $ENVIRONMENT in
    "staging")
        echo "Deploying loadsim-app to staging environment..."
        kubectl apply -k overlays/staging/
        echo "✅ Staging deployment completed"
        ;;
    "production")
        echo "Deploying loadsim-app to production environment..."
        kubectl apply -k overlays/production/
        echo "✅ Production deployment completed"
        ;;
    "monitoring")
        echo "Deploying lks-irs to monitoring environment..."
        echo "⚠️  Note: Make sure to run ./setup-ecr-auth.sh first for ECR authentication"
        kubectl apply -k monitoring/
        echo "✅ Monitoring deployment completed"
        ;;
    "all")
        echo "Deploying to all environments..."
        kubectl apply -k overlays/staging/
        kubectl apply -k overlays/production/
        kubectl apply -k monitoring/
        echo "✅ All deployments completed"
        ;;
    *)
        echo "❌ Invalid environment: $ENVIRONMENT"
        echo "Available environments: staging, production, monitoring, all"
        exit 1
        ;;
esac

echo "Deployment completed successfully!" 