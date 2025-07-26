#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up DynamoDB for IRS Application${NC}"
echo "=================================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

echo -e "${GREEN}✅ AWS CLI is installed${NC}"

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${YELLOW}⚠️  AWS credentials not configured. Please configure them first.${NC}"
    echo "Run: aws configure"
    echo "Or set environment variables:"
    echo "  export AWS_ACCESS_KEY_ID=your_access_key"
    echo "  export AWS_SECRET_ACCESS_KEY=your_secret_key"
    echo "  export AWS_DEFAULT_REGION=your_region"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials are configured${NC}"

# Get current AWS account and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
echo -e "${BLUE}📋 AWS Account: ${ACCOUNT_ID}${NC}"
echo -e "${BLUE}🌍 AWS Region: ${REGION}${NC}"

# Table name
TABLE_NAME="insident"

echo -e "\n${BLUE}📊 Creating DynamoDB Table: ${TABLE_NAME}${NC}"

# Create DynamoDB table
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions \
        AttributeName=id,AttributeType=S \
        AttributeName=createdAt,AttributeType=S \
        AttributeName=severity,AttributeType=S \
        AttributeName=status,AttributeType=S \
        AttributeName=insident_type,AttributeType=S \
    --key-schema \
        AttributeName=id,KeyType=HASH \
    --global-secondary-indexes \
        IndexName=CreatedAtIndex,KeySchema=[{AttributeName=createdAt,KeyType=HASH}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5} \
        IndexName=SeverityIndex,KeySchema=[{AttributeName=severity,KeyType=HASH}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5} \
        IndexName=StatusIndex,KeySchema=[{AttributeName=status,KeyType=HASH}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5} \
        IndexName=IncidentTypeIndex,KeySchema=[{AttributeName=insident_type,KeyType=HASH}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5} \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ DynamoDB table created successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Table might already exist or there was an error${NC}"
fi

# Wait for table to be active
echo -e "${BLUE}⏳ Waiting for table to be active...${NC}"
aws dynamodb wait table-exists --table-name $TABLE_NAME --region $REGION
echo -e "${GREEN}✅ Table is active${NC}"

# Add sample data
echo -e "\n${BLUE}📝 Adding sample data to DynamoDB...${NC}"

# Function to add incident
add_incident() {
    local id=$1
    local title=$2
    local description=$3
    local severity=$4
    local category=$5
    local incident_type=$6
    local environment=$7
    local action_status=$8
    local status=$9
    local created_at=${10}
    
    aws dynamodb put-item \
        --table-name $TABLE_NAME \
        --item "{
            \"id\": {\"S\": \"$id\"},
            \"title\": {\"S\": \"$title\"},
            \"description\": {\"S\": \"$description\"},
            \"report\": {\"S\": \"Investigation report for $title\"},
            \"suggestions\": {\"L\": [
                {\"S\": \"Implement monitoring and alerts\"},
                {\"S\": \"Review and update procedures\"},
                {\"S\": \"Conduct root cause analysis\"}
            ]},
            \"severity\": {\"S\": \"$severity\"},
            \"category\": {\"S\": \"$category\"},
            \"insident_type\": {\"S\": \"$incident_type\"},
            \"environment\": {\"S\": \"$environment\"},
            \"actionStatus\": {\"S\": \"$action_status\"},
            \"status\": {\"S\": \"$status\"},
            \"reporter\": {\"S\": \"System Monitor\"},
            \"createdAt\": {\"S\": \"$created_at\"},
            \"resolutionTime\": {\"S\": \"2 hours\"},
            \"emailSent\": {\"BOOL\": true},
            \"emailSentAt\": {\"S\": \"$created_at\"},
            \"actionTaken\": {\"S\": \"Automated resolution applied\"},
            \"affectedServices\": {\"L\": [
                {\"S\": \"web-service\"},
                {\"S\": \"api-service\"}
            ]},
            \"tags\": {\"L\": [
                {\"S\": \"$category\"},
                {\"S\": \"$severity\"},
                {\"S\": \"$environment\"}
            ]}
        }" \
        --region $REGION
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Added incident: $id${NC}"
    else
        echo -e "${RED}❌ Failed to add incident: $id${NC}"
    fi
}

# Add sample incidents for 2025
add_incident "INC-2025-001" "Kubernetes Node CPU High" "Production nodes experiencing high CPU usage" "critical" "kubernetes" "CPU_HIGH" "production" "auto" "solved" "2025-01-15T10:30:00Z"
add_incident "INC-2025-002" "Database Connection Pool Exhaustion" "Database connections exhausted causing timeouts" "high" "infrastructure" "APP_ERROR" "production" "manual" "in-progress" "2025-01-16T14:20:00Z"
add_incident "INC-2025-003" "Load Balancer Health Check Failures" "Multiple backend services failing health checks" "medium" "infrastructure" "UNHEALTHY_POD" "production" "auto" "solved" "2025-01-17T09:15:00Z"
add_incident "INC-2025-004" "Security Vulnerability Detected" "Critical security vulnerability in dependencies" "critical" "infrastructure" "OTHER" "production" "manual" "open" "2025-01-18T16:45:00Z"
add_incident "INC-2025-005" "Monitoring System Outage" "Prometheus monitoring system down" "high" "infrastructure" "OTHER" "production" "auto" "solved" "2025-01-19T11:30:00Z"
add_incident "INC-2025-006" "CI/CD Pipeline Failure" "Build pipeline failing due to tests" "medium" "ci-cd" "APP_ERROR" "staging" "manual" "in-progress" "2025-01-20T13:20:00Z"
add_incident "INC-2025-007" "Network Connectivity Issues" "Service-to-service communication failing" "high" "infrastructure" "APP_ERROR" "production" "auto" "solved" "2025-01-21T08:45:00Z"
add_incident "INC-2025-008" "Storage Space Low" "Disk space running low on production servers" "medium" "infrastructure" "OTHER" "production" "manual" "open" "2025-01-22T19:30:00Z"
add_incident "INC-2025-009" "API Rate Limiting" "API hitting rate limits causing 429 errors" "high" "infrastructure" "APP_ERROR" "production" "auto" "solved" "2025-01-23T12:15:00Z"
add_incident "INC-2025-010" "Cache Miss Rate High" "Redis cache miss rate causing performance issues" "medium" "infrastructure" "APP_ERROR" "production" "manual" "in-progress" "2025-01-24T15:30:00Z"

# Add sample incidents for 2024
add_incident "INC-2024-001" "Kubernetes Cluster Outage" "Complete cluster outage due to network issues" "critical" "kubernetes" "OTHER" "production" "manual" "solved" "2024-03-15T08:30:00Z"
add_incident "INC-2024-002" "Database Performance Degradation" "Slow queries causing application timeouts" "high" "infrastructure" "APP_ERROR" "production" "auto" "solved" "2024-06-20T14:15:00Z"
add_incident "INC-2024-003" "Security Breach Attempt" "Multiple failed login attempts detected" "critical" "infrastructure" "OTHER" "production" "manual" "solved" "2024-09-10T10:00:00Z"
add_incident "INC-2024-004" "Load Balancer Configuration Error" "Misconfigured routing causing service issues" "medium" "infrastructure" "APP_ERROR" "production" "manual" "solved" "2024-11-05T16:45:00Z"
add_incident "INC-2024-005" "Monitoring System Failure" "Complete monitoring system down" "high" "infrastructure" "OTHER" "production" "auto" "solved" "2024-12-15T09:30:00Z"

echo -e "\n${BLUE}📋 Creating .env file with AWS configuration...${NC}"

# Create .env file
cat > .env << EOF
# AWS Configuration
VITE_AWS_REGION=$REGION
VITE_AWS_ACCESS_KEY_ID=your_access_key_here
VITE_AWS_SECRET_ACCESS_KEY=your_secret_key_here
VITE_DYNAMODB_TABLE_NAME=$TABLE_NAME

# Set to false to use real DynamoDB data
VITE_USE_MOCK_DATA=false
EOF

echo -e "${GREEN}✅ .env file created${NC}"
echo -e "${YELLOW}⚠️  Please update the .env file with your actual AWS credentials:${NC}"
echo -e "${BLUE}   VITE_AWS_ACCESS_KEY_ID=your_actual_access_key${NC}"
echo -e "${BLUE}   VITE_AWS_SECRET_ACCESS_KEY=your_actual_secret_key${NC}"

echo -e "\n${BLUE}🔍 Verifying data in DynamoDB...${NC}"

# Count items in table
ITEM_COUNT=$(aws dynamodb scan --table-name $TABLE_NAME --select COUNT --region $REGION --query Count --output text)
echo -e "${GREEN}✅ Total items in table: $ITEM_COUNT${NC}"

# Show sample items
echo -e "\n${BLUE}📊 Sample items in DynamoDB:${NC}"
aws dynamodb scan \
    --table-name $TABLE_NAME \
    --region $REGION \
    --max-items 3 \
    --query 'Items[0:3].{ID:id.S,Title:title.S,Severity:severity.S,Environment:environment.S,CreatedAt:createdAt.S}' \
    --output table

echo -e "\n${GREEN}🎉 DynamoDB setup complete!${NC}"
echo -e "${BLUE}📝 Next steps:${NC}"
echo "1. Update .env file with your AWS credentials"
echo "2. Restart your development server"
echo "3. The dashboard will now use real DynamoDB data"
echo -e "\n${YELLOW}💡 To switch back to mock data, set VITE_USE_MOCK_DATA=true in .env${NC}" 