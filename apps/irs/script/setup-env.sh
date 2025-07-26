#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up Environment Variables for Real DynamoDB Data${NC}"
echo "================================================================"

# Check if .env file exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file already exists. Do you want to overwrite it? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}📝 Creating .env.example instead...${NC}"
        ENV_FILE=".env.example"
    else
        ENV_FILE=".env"
    fi
else
    ENV_FILE=".env"
fi

# Get AWS region
echo -e "${BLUE}🌍 Enter AWS Region (default: us-east-1):${NC}"
read -r aws_region
aws_region=${aws_region:-us-east-1}

# Get table name
echo -e "${BLUE}📊 Enter DynamoDB Table Name (default: insident):${NC}"
read -r table_name
table_name=${table_name:-insident}

# Get AWS credentials
echo -e "${BLUE}🔑 Enter AWS Access Key ID:${NC}"
read -r access_key_id

echo -e "${BLUE}🔐 Enter AWS Secret Access Key:${NC}"
read -s secret_access_key
echo

# Create .env file
cat > "$ENV_FILE" << EOF
# AWS Configuration
VITE_AWS_REGION=$aws_region
VITE_AWS_ACCESS_KEY_ID=$access_key_id
VITE_AWS_SECRET_ACCESS_KEY=$secret_access_key
VITE_DYNAMODB_TABLE_NAME=$table_name

# Set to false to use real DynamoDB data
VITE_USE_MOCK_DATA=false
EOF

echo -e "${GREEN}✅ Environment file created: $ENV_FILE${NC}"

# Test AWS credentials
echo -e "${BLUE}🧪 Testing AWS credentials...${NC}"
if aws sts get-caller-identity &> /dev/null; then
    echo -e "${GREEN}✅ AWS credentials are valid${NC}"
    
    # Get account info
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo -e "${BLUE}📋 AWS Account: ${ACCOUNT_ID}${NC}"
    
    # Test DynamoDB access
    echo -e "${BLUE}🔍 Testing DynamoDB access...${NC}"
    if aws dynamodb describe-table --table-name "$table_name" --region "$aws_region" &> /dev/null; then
        echo -e "${GREEN}✅ DynamoDB table '$table_name' is accessible${NC}"
        
        # Count items
        ITEM_COUNT=$(aws dynamodb scan --table-name "$table_name" --select COUNT --region "$aws_region" --query Count --output text)
        echo -e "${GREEN}📊 Total items in table: $ITEM_COUNT${NC}"
    else
        echo -e "${YELLOW}⚠️  DynamoDB table '$table_name' not found or not accessible${NC}"
        echo -e "${BLUE}💡 You may need to run: ./setup-dynamodb.sh${NC}"
    fi
else
    echo -e "${RED}❌ AWS credentials are invalid${NC}"
    echo -e "${YELLOW}💡 Please check your credentials and try again${NC}"
fi

echo -e "\n${GREEN}🎉 Environment setup complete!${NC}"
echo -e "${BLUE}📝 Next steps:${NC}"
echo "1. Restart your development server: npm run dev"
echo "2. The application will now use real DynamoDB data"
echo -e "\n${YELLOW}💡 To switch back to mock data, set VITE_USE_MOCK_DATA=true in $ENV_FILE${NC}" 