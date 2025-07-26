terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get base infrastructure outputs
data "terraform_remote_state" "base" {
  backend = "local"
  config = {
    path = "../base/terraform.tfstate"
  }
}

# Data source to get bastion infrastructure outputs
data "terraform_remote_state" "bastion" {
  backend = "local"
  config = {
    path = "../bastion/terraform.tfstate"
  }
}

# Ollama Security Group
module "ollama_sg" {
  source = "../../modules/network/security-group"

  project_name        = var.project_name
  security_group_name = "ollama"
  security_group_type = "ollama"
  description         = "Security group for Ollama instance"
  vpc_id              = data.terraform_remote_state.base.outputs.vpc_id
  
  ingress_rules = [
    {
      description = "Ollama API from private network"
      from_port   = 11434
      to_port     = 11434
      protocol    = "tcp"
      cidr_blocks = [data.terraform_remote_state.base.outputs.vpc_cidr_block]
    },
    {
      description = "SSH from private network"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      security_groups = [data.terraform_remote_state.bastion.outputs.bastion_security_group_id]
    }
  ]
  
  egress_rules = [
    {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    Service     = "ollama"
    ManagedBy   = "terraform"
  }
}

# Ollama EC2 Instance
module "ollama" {
  source = "../../modules/compute/ec2"
  
  project_name     = var.project_name
  instance_name    = "ollama"
  ami              = var.ollama_ami
  instance_type    = var.ollama_instance_type
  key_name         = var.ollama_key_name
  security_group_ids = [
    data.terraform_remote_state.base.outputs.local_access_security_group_id,
    module.ollama_sg.security_group_id
  ]
  subnet_id        = data.terraform_remote_state.base.outputs.private_subnet_1_id
  iam_instance_profile = "LabInstanceProfile"
  root_volume_size = var.ollama_root_volume_size
  root_volume_type = var.ollama_root_volume_type
  root_volume_encrypted = var.ollama_root_volume_encrypted
  create_eip       = true
  user_data        = templatefile("${path.module}/user_data.sh", {
    ollama_model = var.ollama_model
  })
  
  # Explicit dependency on bastion to ensure NAT routing is ready
  depends_on = [
    data.terraform_remote_state.bastion
  ]
} 