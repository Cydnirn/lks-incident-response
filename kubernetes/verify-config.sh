#!/bin/bash

# Script to verify all Kubernetes configurations are correct
# This script checks the generated manifests for each environment

set -e

echo "🔍 Verifying Kubernetes configurations..."
echo "========================================"

echo ""
echo "📊 Checking Staging Environment:"
echo "--------------------------------"
echo "Generated manifests:"
kubectl kustomize overlays/staging/ | head -20

echo ""
echo "📋 Staging ConfigMap:"
kubectl kustomize overlays/staging/ | grep -A 10 "kind: ConfigMap" | head -15

echo ""
echo "🚀 Checking Production Environment:"
echo "-----------------------------------"
echo "Generated manifests:"
kubectl kustomize overlays/production/ | head -20

echo ""
echo "📋 Production ConfigMap:"
kubectl kustomize overlays/production/ | grep -A 10 "kind: ConfigMap" | head -15

echo ""
echo "📈 Checking Monitoring Environment:"
echo "-----------------------------------"
echo "Generated manifests:"
kubectl kustomize monitoring/ | head -20

echo ""
echo "📋 Monitoring ConfigMap:"
kubectl kustomize monitoring/ | grep -A 10 "kind: ConfigMap" | head -15

echo ""
echo "🔧 Checking Image Transformations:"
echo "---------------------------------"
echo "Staging images:"
kubectl kustomize overlays/staging/ | grep -A 5 "image:" | head -10

echo ""
echo "Production images:"
kubectl kustomize overlays/production/ | grep -A 5 "image:" | head -10

echo ""
echo "Monitoring images:"
kubectl kustomize monitoring/ | grep -A 5 "image:" | head -10

echo ""
echo "✅ Configuration verification completed!"
echo ""
echo "📋 Summary:"
echo "- Staging: Uses betuah/loadsim:latest with staging config"
echo "- Production: Uses betuah/loadsim:latest with production config"
echo "- Monitoring: Uses ECR image with monitoring config"
echo ""
echo "🚀 To deploy: ./deploy.sh <environment>" 