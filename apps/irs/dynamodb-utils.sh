#!/bin/bash

# DynamoDB utility functions for IRS incident management
# Make sure you have AWS CLI configured with proper credentials

set -e

TABLE_NAME="insident"
REGION="${AWS_REGION:-us-east-1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to list all incidents
list_all_incidents() {
    print_status $BLUE "📋 Listing all incidents in table: $TABLE_NAME"
    echo ""
    
    aws dynamodb scan \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --query 'Items[*].{ID:id.S,Title:title.S,Severity:severity.S,Status:status.S,Category:category.S,Environment:environment.S,CreatedAt:createdAt.S}' \
        --output table
}

# Function to query incidents by status
query_by_status() {
    local status=$1
    print_status $BLUE "🔍 Querying incidents with status: $status"
    echo ""
    
    aws dynamodb query \
        --table-name "$TABLE_NAME" \
        --index-name StatusIndex \
        --key-condition-expression "#status = :status" \
        --expression-attribute-names '{"#status": "status"}' \
        --expression-attribute-values "{\":status\": {\"S\": \"$status\"}}" \
        --region "$REGION" \
        --query 'Items[*].{ID:id.S,Title:title.S,Severity:severity.S,Status:status.S,CreatedAt:createdAt.S}' \
        --output table
}

# Function to query incidents by severity
query_by_severity() {
    local severity=$1
    print_status $BLUE "🔍 Querying incidents with severity: $severity"
    echo ""
    
    aws dynamodb query \
        --table-name "$TABLE_NAME" \
        --index-name SeverityIndex \
        --key-condition-expression "#severity = :severity" \
        --expression-attribute-names '{"#severity": "severity"}' \
        --expression-attribute-values "{\":severity\": {\"S\": \"$severity\"}}" \
        --region "$REGION" \
        --query 'Items[*].{ID:id.S,Title:title.S,Severity:severity.S,Status:status.S,CreatedAt:createdAt.S}' \
        --output table
}

# Function to query incidents by category
query_by_category() {
    local category=$1
    print_status $BLUE "🔍 Querying incidents with category: $category"
    echo ""
    
    aws dynamodb query \
        --table-name "$TABLE_NAME" \
        --index-name CategoryIndex \
        --key-condition-expression "#category = :category" \
        --expression-attribute-names '{"#category": "category"}' \
        --expression-attribute-values "{\":category\": {\"S\": \"$category\"}}" \
        --region "$REGION" \
        --query 'Items[*].{ID:id.S,Title:title.S,Category:category.S,Status:status.S,CreatedAt:createdAt.S}' \
        --output table
}

# Function to get a specific incident by ID
get_incident_by_id() {
    local id=$1
    print_status $BLUE "🔍 Getting incident with ID: $id"
    echo ""
    
    aws dynamodb get-item \
        --table-name "$TABLE_NAME" \
        --key "{\"id\": {\"S\": \"$id\"}}" \
        --region "$REGION" \
        --query 'Item' \
        --output json
}

# Function to update incident status
update_incident_status() {
    local id=$1
    local new_status=$2
    
    print_status $YELLOW "🔄 Updating incident $id status to: $new_status"
    
    aws dynamodb update-item \
        --table-name "$TABLE_NAME" \
        --key "{\"id\": {\"S\": \"$id\"}}" \
        --update-expression "SET #status = :status" \
        --expression-attribute-names '{"#status": "status"}' \
        --expression-attribute-values "{\":status\": {\"S\": \"$new_status\"}}" \
        --region "$REGION"
    
    print_status $GREEN "✅ Status updated successfully"
}

# Function to delete an incident
delete_incident() {
    local id=$1
    
    print_status $RED "🗑️  Deleting incident with ID: $id"
    
    aws dynamodb delete-item \
        --table-name "$TABLE_NAME" \
        --key "{\"id\": {\"S\": \"$id\"}}" \
        --region "$REGION"
    
    print_status $GREEN "✅ Incident deleted successfully"
}

# Function to get table statistics
get_table_stats() {
    print_status $BLUE "📊 Table Statistics for: $TABLE_NAME"
    echo ""
    
    # Get table description
    aws dynamodb describe-table \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --query 'Table.{TableName:TableName,TableStatus:TableStatus,ItemCount:ItemCount,TableSizeBytes:TableSizeBytes}' \
        --output table
    
    echo ""
    
    # Get item count
    local item_count=$(aws dynamodb scan --table-name "$TABLE_NAME" --select COUNT --region "$REGION" --query 'Count' --output text)
    print_status $GREEN "Total items in table: $item_count"
}

# Function to clear all data (use with caution)
clear_all_data() {
    print_status $RED "⚠️  WARNING: This will delete ALL data from the table!"
    echo -n "Are you sure you want to continue? (yes/no): "
    read -r confirmation
    
    if [[ "$confirmation" == "yes" ]]; then
        print_status $YELLOW "🗑️  Clearing all data from table: $TABLE_NAME"
        
        # Get all items and delete them
        local items=$(aws dynamodb scan --table-name "$TABLE_NAME" --region "$REGION" --query 'Items[*].id.S' --output text)
        
        for id in $items; do
            aws dynamodb delete-item \
                --table-name "$TABLE_NAME" \
                --key "{\"id\": {\"S\": \"$id\"}}" \
                --region "$REGION" >/dev/null 2>&1
        done
        
        print_status $GREEN "✅ All data cleared successfully"
    else
        print_status $YELLOW "❌ Operation cancelled"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  list                    - List all incidents"
    echo "  status [STATUS]         - Query incidents by status (open, in-progress, solved, etc.)"
    echo "  severity [SEVERITY]     - Query incidents by severity (critical, high, medium, low)"
    echo "  category [CATEGORY]     - Query incidents by category (kubernetes, security, etc.)"
    echo "  get [ID]               - Get specific incident by ID"
    echo "  update-status [ID] [STATUS] - Update incident status"
    echo "  delete [ID]            - Delete incident by ID"
    echo "  stats                  - Show table statistics"
    echo "  clear                  - Clear all data (use with caution)"
    echo "  help                   - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 status open"
    echo "  $0 severity critical"
    echo "  $0 get inc-001"
    echo "  $0 update-status inc-001 solved"
    echo "  $0 delete inc-001"
}

# Main script logic
case "${1:-help}" in
    "list")
        list_all_incidents
        ;;
    "status")
        if [[ -z "$2" ]]; then
            print_status $RED "❌ Please provide a status value"
            echo "Available statuses: open, in-progress, solved, postponed, pending"
            exit 1
        fi
        query_by_status "$2"
        ;;
    "severity")
        if [[ -z "$2" ]]; then
            print_status $RED "❌ Please provide a severity value"
            echo "Available severities: critical, high, medium, low"
            exit 1
        fi
        query_by_severity "$2"
        ;;
    "category")
        if [[ -z "$2" ]]; then
            print_status $RED "❌ Please provide a category value"
            echo "Available categories: kubernetes, infrastructure, monitoring, security, database, network, storage, ci-cd, other"
            exit 1
        fi
        query_by_category "$2"
        ;;
    "get")
        if [[ -z "$2" ]]; then
            print_status $RED "❌ Please provide an incident ID"
            exit 1
        fi
        get_incident_by_id "$2"
        ;;
    "update-status")
        if [[ -z "$2" || -z "$3" ]]; then
            print_status $RED "❌ Please provide incident ID and new status"
            exit 1
        fi
        update_incident_status "$2" "$3"
        ;;
    "delete")
        if [[ -z "$2" ]]; then
            print_status $RED "❌ Please provide an incident ID"
            exit 1
        fi
        delete_incident "$2"
        ;;
    "stats")
        get_table_stats
        ;;
    "clear")
        clear_all_data
        ;;
    "help"|*)
        show_usage
        ;;
esac 