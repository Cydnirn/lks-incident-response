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
module "llm_sg" {
  source = "../../modules/network/security-group"

  project_name        = var.project_name
  security_group_name = "llm-sg"
  security_group_type = "llm"
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
      cidr_blocks = [data.terraform_remote_state.base.outputs.vpc_cidr_block]
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
  
  tags = {
    Name = "${var.project_name}-llm-sg"
    Project = var.project_name
    Owner = "lks-team"
  }
}

# Ollama EC2 Instance
module "ollama" {
  source = "../../modules/compute/ec2"
  
  project_name           = var.project_name
  instance_name          = "llm-host"
  ami                   = var.llm_ami
  instance_type         = var.llm_instance_type
  key_name              = var.llm_key_name
  security_group_ids    = [
    data.terraform_remote_state.base.outputs.local_access_security_group_id,
    module.llm_sg.security_group_id
  ]
  subnet_id             = data.terraform_remote_state.base.outputs.private_subnet_1_id
  iam_instance_profile  = "LabInstanceProfile"
  root_volume_size      = var.llm_root_volume_size
  root_volume_type      = var.llm_root_volume_type
  root_volume_encrypted = var.llm_root_volume_encrypted
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/user_data.sh", {
    ollama_model = var.llm_model
  })
  
  # Implicit dependency on bastion to ensure NAT routing is ready
  # This ensures the bastion instance is fully created before creating ollama
  depends_on = [
    data.terraform_remote_state.bastion
  ]
} 