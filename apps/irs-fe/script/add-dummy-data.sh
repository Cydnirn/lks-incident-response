#!/bin/bash

# Script to add dummy incident data to DynamoDB insident table
# Make sure you have AWS CLI configured with proper credentials

set -e

TABLE_NAME="insidents"
REGION="${AWS_REGION:-us-east-1}"

echo "🚀 Adding dummy incident data to DynamoDB table: $TABLE_NAME"

# Function to add a single incident
add_incident() {
    local id=$1
    local title=$2
    local description=$3
    local severity=$4
    local category=$5
    local insident_type=$6
    local environment=$7
    local status=$8
    local action_status=$9
    local reporter=${10}
    local created_at=${11}
    local affected_services=${12}
    local tags=${13}

    echo "📝 Adding incident: $title"

    aws dynamodb put-item \
        --table-name "$TABLE_NAME" \
        --item "{
            \"id\": {\"S\": \"$id\"},
            \"title\": {\"S\": \"$title\"},
            \"description\": {\"S\": \"$description\"},
            \"report\": {\"S\": \"$description\"},
            \"severity\": {\"S\": \"$severity\"},
            \"category\": {\"S\": \"$category\"},
            \"insident_type\": {\"S\": \"$insident_type\"},
            \"environment\": {\"S\": \"$environment\"},
            \"actionStatus\": {\"S\": \"$action_status\"},
            \"status\": {\"S\": \"$status\"},
            \"reporter\": {\"S\": \"$reporter\"},
            \"createdAt\": {\"S\": \"$created_at\"},
            \"emailSent\": {\"BOOL\": false},
            \"affectedServices\": {\"L\": [$affected_services]},
            \"tags\": {\"L\": [$tags]}
        }" \
        --region "$REGION"

    echo "✅ Added incident: $title"
    echo ""
}

# Check if table exists
echo "🔍 Checking if table exists..."
if ! aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "❌ Table '$TABLE_NAME' does not exist. Please create it first using create-dynamodb-table.sh"
    exit 1
fi

echo "✅ Table '$TABLE_NAME' exists. Proceeding with data insertion..."
echo ""

# Incident 1: Kubernetes CPU High
add_incident \
    "inc-001" \
    "Kubernetes Node CPU Full - Production Cluster" \
    "Multiple nodes in the production Kubernetes cluster are experiencing 100% CPU utilization, causing pod scheduling issues and service degradation." \
    "critical" \
    "kubernetes" \
    "CPU_HIGH" \
    "production" \
    "in-progress" \
    "auto" \
    "john.doe@company.com" \
    "2024-01-15T08:30:00Z" \
    "{\"S\": \"api-gateway\"}, {\"S\": \"user-service\"}, {\"S\": \"payment-service\"}" \
    "{\"S\": \"urgent\"}, {\"S\": \"cpu-issue\"}, {\"S\": \"production\"}"

# Incident 2: Pod Crash
add_incident \
    "inc-002" \
    "Pod CrashLoopBackOff - Database Service" \
    "Database service pods are continuously crashing and restarting, causing application downtime and data access issues." \
    "high" \
    "kubernetes" \
    "POD_CRASH" \
    "staging" \
    "open" \
    "manual" \
    "jane.smith@company.com" \
    "2024-01-15T10:15:00Z" \
    "{\"S\": \"auth-service\"}, {\"S\": \"notification-service\"}, {\"S\": \"analytics-service\"}" \
    "{\"S\": \"pod-crash\"}, {\"S\": \"database\"}, {\"S\": \"memory-issue\"}"

# Incident 3: Image Pull Error
add_incident \
    "inc-003" \
    "Image Pull Error - Container Registry" \
    "Kubernetes is unable to pull container images from the registry, causing deployment failures and pod startup issues." \
    "critical" \
    "kubernetes" \
    "IMAGE_PULL" \
    "production" \
    "open" \
    "manual" \
    "devops.team@company.com" \
    "2024-01-15T11:45:00Z" \
    "{\"S\": \"web-service\"}, {\"S\": \"api-service\"}" \
    "{\"S\": \"image-pull\"}, {\"S\": \"registry\"}, {\"S\": \"deployment\"}"

# Incident 4: Unhealthy Pod
add_incident \
    "inc-004" \
    "Unhealthy Pod - Health Check Failures" \
    "Multiple pods are failing health checks and being marked as unhealthy, causing service disruption and load balancer issues." \
    "medium" \
    "kubernetes" \
    "UNHEALTHY_POD" \
    "development" \
    "solved" \
    "auto" \
    "dev.team@company.com" \
    "2024-01-14T14:20:00Z" \
    "{\"S\": \"dev-api\"}, {\"S\": \"dev-database\"}" \
    "{\"S\": \"health-check\"}, {\"S\": \"unhealthy\"}, {\"S\": \"development\"}"

# Incident 5: CI/CD Pipeline Error
add_incident \
    "inc-005" \
    "CI/CD Pipeline Build Failures" \
    "The main CI/CD pipeline is failing due to dependency conflicts and test failures. This is blocking deployments for multiple teams." \
    "high" \
    "ci-cd" \
    "APP_ERROR" \
    "development" \
    "in-progress" \
    "manual" \
    "devops.team@company.com" \
    "2024-01-15T09:00:00Z" \
    "{\"S\": \"jenkins\"}, {\"S\": \"gitlab-ci\"}, {\"S\": \"docker-registry\"}" \
    "{\"S\": \"ci-cd\"}, {\"S\": \"pipeline\"}, {\"S\": \"deployment\"}"

echo "🎉 Successfully added 5 dummy incidents to the '$TABLE_NAME' table!"
echo ""

# Display summary
echo "📊 Summary of added incidents:"
echo "1. inc-001: Kubernetes Node CPU Full - Production Cluster (Critical, CPU_HIGH)"
echo "2. inc-002: Pod CrashLoopBackOff - Database Service (High, POD_CRASH)"
echo "3. inc-003: Image Pull Error - Container Registry (Critical, IMAGE_PULL)"
echo "4. inc-004: Unhealthy Pod - Health Check Failures (Medium, UNHEALTHY_POD)"
echo "5. inc-005: CI/CD Pipeline Build Failures (High, APP_ERROR)"
echo ""

# Verify data was added
echo "🔍 Verifying data insertion..."
ITEM_COUNT=$(aws dynamodb scan --table-name "$TABLE_NAME" --select COUNT --region "$REGION" --query 'Count' --output text)
echo "✅ Total items in table: $ITEM_COUNT"

echo ""
echo "📝 Next steps:"
echo "1. Check your IRS application to see the new incidents"
echo "2. Test filtering by severity, status, or category"
echo "3. Verify that the data appears correctly in the dashboard"
echo "4. Test filtering by incident type (CPU_HIGH, POD_CRASH, etc.)" 