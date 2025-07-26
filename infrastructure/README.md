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

### Deploy All Infrastructure
```bash
./deploy.sh deploy all
```

### Deploy Individual Stacks (in order)
```bash
# 1. Deploy base infrastructure first (VPC, Security Groups)
./deploy.sh deploy base

# 2. Deploy bastion host (NAT instance for private subnets)
./deploy.sh deploy bastion

# 3. Deploy Ollama instance (requires bastion for internet access)
./deploy.sh deploy ollama
```

**Important**: Ollama stack depends on bastion stack because bastion acts as a NAT instance for private subnets. The ollama instance needs internet access through the bastion host to download models and updates.

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

## Infrastructure Components

### Base Infrastructure
- **VPC** with CIDR `172.0.0.0/16`
- **Public Subnet** in `us-east-1a` (CIDR: `172.0.10.0/24`)
- **Private Subnet 1** in `us-east-1a` (CIDR: `172.0.20.0/24`)
- **Private Subnet 2** in `us-east-1b` (CIDR: `172.0.30.0/24`)
- **Internet Gateway** for public subnet internet access
- **Security Groups** for different services

### Bastion Host (NAT Instance)
- **EC2 Instance** (t3.micro) in public subnet
- **Elastic IP** for static public IP
- **NAT Instance** functionality for private subnets (cost-effective alternative to NAT Gateway)
- **WireGuard VPN** for secure remote access
- **SSH Access** for administration
- **Source/Destination Check Disabled** for NAT routing
- **Route Table Configuration** to route private subnet traffic through bastion

### Ollama Instance
- **EC2 Instance** (m5.large) in private subnet
- **Elastic IP** for external access
- **Ollama AI/ML** service running on port 11434
- **SSH Access** through bastion host
- **Internet Access** through bastion NAT instance


## Adding New Services

To add a new service:

1. Create a new directory in `stacks/<service-name>/`
2. Use the existing modules from `modules/`
3. Follow the same pattern as existing stacks
4. Update the deployment script if needed

## Dynamic Security Groups

The infrastructure uses a dynamic security group module that provides flexibility in creating security groups. Security groups are organized based on their scope:

### Base Stack Security Groups (Common/Shared)
- **Local Access**: SSH and ICMP from private network (used by multiple services)
- **Database**: All traffic from private network (for database services)

### Service-Specific Security Groups
Each service creates its own security group using the dynamic security group module:

- **Bastion Stack**: Creates bastion security group with SSH, WireGuard UI, and WireGuard VPN access
- **Ollama Stack**: Creates ollama security group with Ollama API and SSH access from private network

### Creating Custom Security Groups
You can create custom security groups for specific services using the dynamic security group module:

```hcl
module "web_service_sg" {
  source = "../../modules/network/dynamic-security-group"

  project_name        = var.project_name
  security_group_name = "web-service"
  security_group_type = "web"
  description         = "Security group for web service"
  vpc_id              = data.terraform_remote_state.base.outputs.vpc_id
  
  ingress_rules = [
    {
      description = "HTTP from anywhere"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS from anywhere"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
```

See `modules/network/dynamic-security-group/README.md` for detailed documentation.
