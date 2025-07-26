#!/bin/bash

# LKS Infrastructure Deployment Script
# Simple script to deploy infrastructure stacks in order

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to deploy a stack
deploy_stack() {
    local stack_name=$1
    local stack_path="stacks/$stack_name"
    
    print_status "Deploying $stack_name stack..."
    
    if [ ! -d "$stack_path" ]; then
        print_error "Stack directory $stack_path not found!"
        exit 1
    fi
    
    cd "$stack_path"
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Apply the deployment
    print_status "Applying deployment..."
    terraform apply -auto-approve
    
    cd - > /dev/null
    print_success "$stack_name stack deployed successfully!"
}

# Function to destroy a stack
destroy_stack() {
    local stack_name=$1
    local stack_path="stacks/$stack_name"
    
    print_status "Destroying $stack_name stack..."
    
    if [ ! -d "$stack_path" ]; then
        print_error "Stack directory $stack_path not found!"
        exit 1
    fi
    
    cd "$stack_path"
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Destroy the stack
    print_status "Destroying stack..."
    terraform destroy -auto-approve
    
    cd - > /dev/null
    print_success "$stack_name stack destroyed successfully!"
}

# Function to plan a stack
plan_stack() {
    local stack_name=$1
    local stack_path="stacks/$stack_name"
    
    print_status "Planning $stack_name stack..."
    
    if [ ! -d "$stack_path" ]; then
        print_error "Stack directory $stack_path not found!"
        exit 1
    fi
    
    cd "$stack_path"
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan the deployment
    print_status "Planning deployment..."
    terraform plan
    
    cd - > /dev/null
}

# Function to show status
show_status() {
    print_status "Checking status of all stacks..."
    
    for stack in base bastion ollama; do
        local stack_path="stacks/$stack"
        if [ -d "$stack_path" ]; then
            cd "$stack_path"
            if [ -f "terraform.tfstate" ]; then
                # Check if state has resources
                if terraform show -json 2>/dev/null | grep -q '"resources"'; then
                    print_success "$stack: Deployed"
                else
                    print_warning "$stack: State file exists but no resources"
                fi
            else
                print_warning "$stack: Not deployed"
            fi
            cd - > /dev/null
        else
            print_error "$stack: Directory not found"
        fi
    done
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [STACK]"
    echo ""
    echo "Commands:"
    echo "  deploy [stack]    Deploy a specific stack or all stacks"
    echo "  destroy [stack]   Destroy a specific stack or all stacks"
    echo "  plan [stack]      Plan deployment for a specific stack"
    echo "  status            Show status of all stacks"
    echo "  help              Show this help message"
    echo ""
    echo "Stacks:"
    echo "  base              Base infrastructure (VPC, Security Groups)"
    echo "  bastion           Bastion host with NAT gateway"
    echo "  ollama            Ollama AI/ML compute instance"
    echo "  all               All stacks (deploy/destroy only)"
    echo ""
    echo "Examples:"
    echo "  $0 deploy base"
    echo "  $0 deploy all"
    echo "  $0 destroy ollama"
    echo "  $0 plan bastion"
}

# Main script logic
main() {
    local command=$1
    local stack=$2
    
    case $command in
        "deploy")
            case $stack in
                "base")
                    deploy_stack "base"
                    ;;
                "bastion")
                    deploy_stack "bastion"
                    ;;
                "ollama")
                    deploy_stack "ollama"
                    ;;
                "all")
                    deploy_stack "base"
                    deploy_stack "bastion"
                    deploy_stack "ollama"
                    ;;
                *)
                    print_error "Invalid stack: $stack"
                    show_usage
                    exit 1
                    ;;
            esac
            ;;
        "destroy")
            case $stack in
                "base")
                    print_warning "Destroying base stack will destroy all dependent stacks!"
                    read -p "Are you sure? (y/N): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        destroy_stack "ollama"
                        destroy_stack "bastion"
                        destroy_stack "base"
                    else
                        print_status "Destroy cancelled."
                    fi
                    ;;
                "bastion")
                    destroy_stack "bastion"
                    ;;
                "ollama")
                    destroy_stack "ollama"
                    ;;
                "all")
                    print_warning "This will destroy ALL infrastructure!"
                    read -p "Are you sure? (y/N): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        destroy_stack "ollama"
                        destroy_stack "bastion"
                        destroy_stack "base"
                    else
                        print_status "Destroy cancelled."
                    fi
                    ;;
                *)
                    print_error "Invalid stack: $stack"
                    show_usage
                    exit 1
                    ;;
            esac
            ;;
        "plan")
            case $stack in
                "base"|"bastion"|"ollama")
                    plan_stack "$stack"
                    ;;
                *)
                    print_error "Invalid stack: $stack"
                    show_usage
                    exit 1
                    ;;
            esac
            ;;
        "status")
            show_status
            ;;
        "help"|"--help"|"-h"|"")
            show_usage
            ;;
        *)
            print_error "Invalid command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 