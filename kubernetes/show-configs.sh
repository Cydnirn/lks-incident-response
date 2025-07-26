#!/bin/bash

# Script to show ConfigMap differences between environments
# This script displays the configuration values for each environment

set -e

echo "📋 ConfigMap Comparison Across Environments"
echo "==========================================="

echo ""
echo "🔧 Staging Environment ConfigMap:"
echo "---------------------------------"
echo "Environment: staging"
echo "Log Level: DEBUG"
echo "Max Workers: 2"
echo "Port: 8080"
echo "CPU Load: 70%"
echo "Memory: 1GB"

echo ""
echo "🚀 Production Environment ConfigMap:"
echo "------------------------------------"
echo "Environment: production"
echo "Log Level: INFO"
echo "Max Workers: 5"
echo "Port: 8080"
echo "CPU Load: 70%"
echo "Memory: 1GB"

echo ""
echo "📈 Monitoring Environment ConfigMap:"
echo "------------------------------------"
echo "Environment: monitoring"
echo "Log Level: INFO"
echo "Max Workers: 1"
echo "Port: 8080"
echo "CPU Load: 70%"
echo "Memory: 1GB"

echo ""
echo "🔍 Key Differences:"
echo "-------------------"
echo "• Staging: DEBUG log level, 2 workers (for testing)"
echo "• Production: INFO log level, 5 workers (for performance)"
echo "• Monitoring: INFO log level, 1 worker (for monitoring)"
echo ""
echo "• All environments use port 8080"
echo "• All environments use same CPU/Memory load settings"
echo "• Staging and Production use betuah/loadsim:latest"
echo "• Monitoring uses ECR image: 472634532065.dkr.ecr.us-east-1.amazonaws.com/lks/loadsim:latest" 