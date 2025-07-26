#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Checking Data Status and DynamoDB Connectivity${NC}"
echo "======================================================"

# Check if .env file exists
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ .env file found${NC}"
    
    # Read environment variables
    source .env
    
    echo -e "${BLUE}📋 Environment Configuration:${NC}"
    echo "  AWS Region: ${VITE_AWS_REGION:-'Not set'}"
    echo "  Table Name: ${VITE_DYNAMODB_TABLE_NAME:-'Not set'}"
    echo "  Use Mock Data: ${VITE_USE_MOCK_DATA:-'Not set'}"
    
    if [ "$VITE_USE_MOCK_DATA" = "false" ]; then
        echo -e "${GREEN}🎯 Using REAL DynamoDB data${NC}"
    else
        echo -e "${YELLOW}🎭 Using MOCK data${NC}"
    fi
    
    # Check AWS credentials
    if [ -n "$VITE_AWS_ACCESS_KEY_ID" ] && [ -n "$VITE_AWS_SECRET_ACCESS_KEY" ]; then
        echo -e "${GREEN}✅ AWS credentials configured${NC}"
        
        # Test AWS connectivity
        echo -e "${BLUE}🧪 Testing AWS connectivity...${NC}"
        if aws sts get-caller-identity &> /dev/null; then
            echo -e "${GREEN}✅ AWS credentials are valid${NC}"
            
            # Get account info
            ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
            echo -e "${BLUE}📋 AWS Account: ${ACCOUNT_ID}${NC}"
            
            # Test DynamoDB access
            if [ -n "$VITE_DYNAMODB_TABLE_NAME" ]; then
                echo -e "${BLUE}🔍 Testing DynamoDB table access...${NC}"
                if aws dynamodb describe-table --table-name "$VITE_DYNAMODB_TABLE_NAME" --region "${VITE_AWS_REGION:-us-east-1}" &> /dev/null; then
                    echo -e "${GREEN}✅ DynamoDB table '$VITE_DYNAMODB_TABLE_NAME' is accessible${NC}"
                    
                    # Count items
                    ITEM_COUNT=$(aws dynamodb scan --table-name "$VITE_DYNAMODB_TABLE_NAME" --select COUNT --region "${VITE_AWS_REGION:-us-east-1}" --query Count --output text)
                    echo -e "${GREEN}📊 Total items in table: $ITEM_COUNT${NC}"
                    
                    # Show sample data
                    echo -e "${BLUE}📋 Sample data from DynamoDB:${NC}"
                    aws dynamodb scan \
                        --table-name "$VITE_DYNAMODB_TABLE_NAME" \
                        --region "${VITE_AWS_REGION:-us-east-1}" \
                        --max-items 3 \
                        --query 'Items[0:3].{ID:id.S,Title:title.S,Severity:severity.S,Environment:environment.S,CreatedAt:createdAt.S}' \
                        --output table
                else
                    echo -e "${RED}❌ DynamoDB table '$VITE_DYNAMODB_TABLE_NAME' not found or not accessible${NC}"
                    echo -e "${YELLOW}💡 You may need to run: ./setup-dynamodb.sh${NC}"
                fi
            else
                echo -e "${YELLOW}⚠️  DynamoDB table name not configured${NC}"
            fi
        else
            echo -e "${RED}❌ AWS credentials are invalid${NC}"
            echo -e "${YELLOW}💡 Please check your credentials in .env file${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  AWS credentials not configured${NC}"
        echo -e "${BLUE}💡 Run: ./setup-env.sh to configure credentials${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  .env file not found${NC}"
    echo -e "${BLUE}💡 Run: ./setup-env.sh to create .env file${NC}"
fi

echo -e "\n${BLUE}📝 Quick Actions:${NC}"
echo "  • ./setup-env.sh     - Setup environment variables"
echo "  • ./setup-dynamodb.sh - Setup DynamoDB table and data"
echo "  • npm run dev        - Start development server"
echo -e "\n${GREEN}🎯 To use real data: Set VITE_USE_MOCK_DATA=false in .env${NC}"
echo -e "${YELLOW}🎭 To use mock data: Set VITE_USE_MOCK_DATA=true in .env${NC}" 