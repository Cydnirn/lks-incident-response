#!/bin/bash

# Script to switch frontend from direct DynamoDB to Go backend

echo "Switching frontend to use Go backend instead of direct DynamoDB..."

# Create backup of original dynamodb.ts
if [ ! -f "src/services/dynamodb.ts.backup" ]; then
    echo "Creating backup of dynamodb.ts..."
    cp src/services/dynamodb.ts src/services/dynamodb.ts.backup
fi

# Update .envrc to include API base URL
echo "Updating .envrc to include API base URL..."
if ! grep -q "VITE_API_BASE_URL" .envrc; then
    echo "" >> .envrc
    echo "# API Configuration" >> .envrc
    echo "export VITE_API_BASE_URL=http://localhost:8080/api" >> .envrc
fi

echo ""
echo "To use the Go backend:"
echo "1. Start the backend: cd ../irs-be && ./run.sh"
echo "2. Update your frontend service imports to use APIService instead of TicketService"
echo "3. The API service is available at: src/services/api.ts"
echo ""
echo "To revert to direct DynamoDB:"
echo "1. Restore backup: cp src/services/dynamodb.ts.backup src/services/dynamodb.ts"
echo "2. Remove VITE_API_BASE_URL from .envrc"
echo ""
echo "Example usage in your components:"
echo "import { APIService } from '../services/api';"
echo "const tickets = await APIService.getAllTickets();" 