# LKS Infrastructure as Code

This directory contains the Terraform Infrastructure as Code (IaC) for the LKS project, organized using a modular, stack-based approach.

## Architecture

The infrastructure is organized into **stacks** and **modules**:

### Stacks
- **Base Stack** (`stacks/base/`) - Foundation infrastructure (VPC, Security Groups)
- **Bastion Stack** (`stacks/bastion/`) - Bastion host with NAT gateway and VPN
- **Ollama Stack** (`stacks/ollama/`) - AI/ML compute instance

### Modules
- **Network Modules** (`modules/network/`) - VPC, Security Groups
- **Compute Modules** (`modules/compute/`) - Reusable EC2 instances

## Quick Start

### Deploy Infrastructure
```bash
cd stacks/base && terrfaform
```


**Important**: LLM stack depends on bastion stack because bastion acts as a NAT instance for private subnets. The LLM instance needs internet access through the bastion host to download models and updates.

### Plan Changes
```bash
./deploy.sh plan bastion
```

### Check Status
```bash
./deploy.sh status
```

### Destroy Infrastructure
```bash
./deploy.sh destroy all
```

# List state for all stacks
./lkstf.sh state-list

# Clean up .terraform directories
./lkstf.sh clean
```

### Individual Stack Commands
```bash
# Navigate to a specific stack
cd stacks/base

# Initialize
terraform init

# Format
terraform fmt

# Validate
terraform validate

# Plan
terraform plan

# Apply
terraform apply

# Show outputs
terraform output
```

## Prerequisites

1. **Terraform** (>= 1.0)
2. **AWS CLI** configured with appropriate credentials
3. **SSH Key Pair** named `vockey` in your AWS account