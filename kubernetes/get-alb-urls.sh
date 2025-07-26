#!/bin/bash

# Script to get ALB DNS names for accessing LKS applications
# This script shows you the external ALB URLs after deployment

echo "🔍 Getting ALB DNS names for LKS applications..."
echo "================================================"

echo ""
echo "📊 Staging Environment (lks-apps-stage):"
echo "----------------------------------------"
STAGING_URL=$(kubectl get ingress -n staging -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -n "$STAGING_URL" ]; then
    echo "🌐 http://$STAGING_URL"
else
    echo "Not deployed yet"
fi

echo ""
echo "🚀 Production Environment (lks-apps-prod):"
echo "------------------------------------------"
PROD_URL=$(kubectl get ingress -n production -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -n "$PROD_URL" ]; then
    echo "🌐 http://$PROD_URL"
else
    echo "Not deployed yet"
fi

echo ""
echo "📈 Monitoring Environment (lks-irs):"
echo "------------------------------------"
MONITORING_URL=$(kubectl get ingress -n monitoring -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -n "$MONITORING_URL" ]; then
    echo "🌐 http://$MONITORING_URL"
else
    echo "Not deployed yet"
fi

echo ""
echo "================================================"
echo "💡 Usage Instructions:"
echo "1. Deploy your applications first using: ./deploy.sh <environment>"
echo "2. Wait 5-10 minutes for AWS to provision the external ALB"
echo "3. Run this script again to get the ALB URLs"
echo "4. Access your apps using the HTTP URLs above"
echo ""
echo "🔧 Alternative access methods:"
echo "- From within the cluster: kubectl port-forward service/<service-name> 8080:80 -n <namespace>"
echo "- Direct service access: kubectl get svc -n <namespace>"
echo ""
echo "⚠️  Note: These are external URLs accessible from the internet (HTTP only, no SSL)" 