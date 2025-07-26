#!/bin/bash

# Script to set up ECR authentication for LKS monitoring application
# This script creates the necessary secret to pull images from private ECR

set -e

echo "🔐 Setting up ECR authentication for monitoring namespace..."
echo "=========================================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Get AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
echo "ECR Repository: 472634532065.dkr.ecr.us-east-1.amazonaws.com/lks/loadsim"

# Create monitoring namespace if it doesn't exist
echo "📦 Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Get ECR login token and create secret
echo "🔑 Creating ECR authentication secret..."
aws ecr get-login-password --region us-east-1 | kubectl create secret docker-registry ecr-secret \
    --docker-server=472634532065.dkr.ecr.us-east-1.amazonaws.com \
    --docker-username=AWS \
    --docker-password-stdin \
    --namespace=monitoring \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✅ ECR authentication secret created successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Deploy the monitoring application: ./deploy.sh monitoring"
echo "2. Check the deployment status: kubectl get pods -n monitoring"
echo "3. View logs if needed: kubectl logs -f deployment/lks-irs -n monitoring"
echo ""
echo "🔍 To verify the secret was created:"
echo "kubectl get secret ecr-secret -n monitoring" 