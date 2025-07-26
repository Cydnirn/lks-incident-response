#!/bin/bash

# Terraform Utilities Script
# This script helps run Terraform commands across all stacks

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

# Function to run command in all stacks
run_in_all_stacks() {
    local command=$1
    local stacks=("base" "bastion" "ollama")
    
    for stack in "${stacks[@]}"; do
        local stack_path="stacks/$stack"
        
        if [ -d "$stack_path" ]; then
            print_status "Running '$command' in $stack stack..."
            cd "$stack_path"
            
            if eval "$command"; then
                print_success "$stack: $command completed successfully"
            else
                print_error "$stack: $command failed"
                return 1
            fi
            
            cd ../..
        else
            print_warning "Stack directory $stack_path not found, skipping..."
        fi
    done
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  init              Initialize all stacks"
    echo "  fmt               Format all Terraform files"
    echo "  validate          Validate all configurations"
    echo "  plan              Plan all stacks"
    echo "  apply             Apply all stacks"
    echo "  destroy           Destroy all stacks"
    echo "  output            Show outputs from all stacks"
    echo "  state-list        List state for all stacks"
    echo "  clean             Clean up .terraform directories"
    echo "  help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 init"
    echo "  $0 fmt"
    echo "  $0 validate"
    echo "  $0 plan"
}

# Function to initialize all stacks
init_all() {
    print_status "Initializing all stacks..."
    run_in_all_stacks "terraform init"
}

# Function to format all files
format_all() {
    print_status "Formatting all Terraform files..."
    cd infrastructure
    terraform fmt -recursive
    print_success "All files formatted"
}

# Function to validate all stacks
validate_all() {
    print_status "Validating all stacks..."
    run_in_all_stacks "terraform validate"
}

# Function to plan all stacks
plan_all() {
    print_status "Planning all stacks..."
    run_in_all_stacks "terraform plan"
}

# Function to apply all stacks
apply_all() {
    print_warning "This will apply changes to ALL stacks!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Applying all stacks..."
        run_in_all_stacks "terraform apply -auto-approve"
    else
        print_status "Apply cancelled."
    fi
}

# Function to destroy all stacks
destroy_all() {
    print_warning "This will destroy ALL infrastructure!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Destroying all stacks..."
        # Destroy in reverse order
        run_in_all_stacks "terraform destroy -auto-approve"
    else
        print_status "Destroy cancelled."
    fi
}

# Function to show outputs
show_outputs() {
    print_status "Showing outputs from all stacks..."
    for stack in base bastion ollama; do
        local stack_path="stacks/$stack"
        
        if [ -d "$stack_path" ]; then
            print_status "Outputs from $stack stack:"
            cd "$stack_path"
            terraform output
            cd ../..
            echo ""
        fi
    done
}

# Function to list state
list_state() {
    print_status "Listing state for all stacks..."
    for stack in base bastion ollama; do
        local stack_path="stacks/$stack"
        
        if [ -d "$stack_path" ]; then
            print_status "State for $stack stack:"
            cd "$stack_path"
            terraform state list
            cd ../..
            echo ""
        fi
    done
}

# Function to clean up
clean_all() {
    print_status "Cleaning up .terraform directories..."
    find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
    print_success "Cleanup completed"
}

# Main script logic
main() {
    local command=$1
    
    case $command in
        "init")
            init_all
            ;;
        "fmt")
            format_all
            ;;
        "validate")
            validate_all
            ;;
        "plan")
            plan_all
            ;;
        "apply")
            apply_all
            ;;
        "destroy")
            destroy_all
            ;;
        "output")
            show_outputs
            ;;
        "state-list")
            list_state
            ;;
        "clean")
            clean_all
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