#!/bin/bash

# Script to update image tags across environments using Kustomize
# This script demonstrates how to use Kustomize image transformer

set -e

ENVIRONMENT=$1
IMAGE_NAME=$2
NEW_TAG=$3

if [ -z "$ENVIRONMENT" ] || [ -z "$IMAGE_NAME" ] || [ -z "$NEW_TAG" ]; then
    echo "Usage: $0 <environment> <image_name> <new_tag>"
    echo ""
    echo "Examples:"
echo "  $0 staging betuah/loadsim v1.0.0"
echo "  $0 production betuah/loadsim v1.1.0"
echo "  $0 monitoring betuah/loadsim v2.1.0"
    echo ""
    echo "Available environments: staging, production, monitoring"
    exit 1
fi

echo "🔄 Updating image tag for $IMAGE_NAME to $NEW_TAG in $ENVIRONMENT environment..."

case $ENVIRONMENT in
    "staging")
        cd overlays/staging
        kustomize edit set image $IMAGE_NAME:$NEW_TAG
        echo "✅ Updated staging environment"
        ;;
    "production")
        cd overlays/production
        kustomize edit set image $IMAGE_NAME:$NEW_TAG
        echo "✅ Updated production environment"
        ;;
    "monitoring")
        cd monitoring
        kustomize edit set image $IMAGE_NAME:$NEW_TAG
        echo "✅ Updated monitoring environment"
        ;;
    *)
        echo "❌ Invalid environment: $ENVIRONMENT"
        echo "Available environments: staging, production, monitoring"
        exit 1
        ;;
esac

echo ""
echo "📋 Next steps:"
echo "1. Review the changes: kubectl kustomize overlays/$ENVIRONMENT/"
echo "2. Apply the changes: ./deploy.sh $ENVIRONMENT"
echo "3. Check deployment status: kubectl get pods -n $ENVIRONMENT" 