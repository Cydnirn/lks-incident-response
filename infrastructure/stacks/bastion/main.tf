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

# Bastion Security Group
module "bastion_sg" {
  source = "../../modules/network/security-group"

  project_name        = var.project_name
  security_group_name = "bastion-sg"
  security_group_type = "bastion"
  description         = "Security group for bastion host"
  vpc_id              = data.terraform_remote_state.base.outputs.vpc_id
  
  ingress_rules = [
    {
      description = "SSH from anywhere"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "WireGuard UI from anywhere"
      from_port   = 51821
      to_port     = 51821
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "WireGuard from anywhere"
      from_port   = 51820
      to_port     = 51820
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "All ports TCP from local network for NAT"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [data.terraform_remote_state.base.outputs.vpc_cidr_block]
    },
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
    Name = "${var.project_name}-bastion-sg"
    Project = var.project_name
    Owner = "lks-team"
  }
}

# Bastion EC2 Instance
module "bastion" {
  source = "../../modules/compute/ec2"
  
  project_name          = var.project_name
  instance_name         = "bastion-host"
  ami                   = var.bastion_ami
  instance_type         = var.bastion_instance_type
  key_name              = var.bastion_key_name
  security_group_ids    = [module.bastion_sg.security_group_id]
  subnet_id             = data.terraform_remote_state.base.outputs.public_subnet_1_id
  iam_instance_profile  = "LabInstanceProfile"
  source_dest_check     = false  # Required for NAT instances
  root_volume_size      = var.bastion_root_volume_size
  root_volume_type      = var.bastion_root_volume_type
  root_volume_encrypted = var.bastion_root_volume_encrypted
  create_eip            = true
  user_data             = templatefile("${path.module}/user_data.sh", {
    wg_host             = module.bastion.instance_eip
  })
}

# Route table for private subnets to route through bastion host
resource "aws_route_table" "private_rt_with_nat" {
  vpc_id = data.terraform_remote_state.base.outputs.vpc_id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = module.bastion.primary_network_interface_id
  }

  tags = {
    Name = "${var.project_name}-private-rt-nat"
    Project = var.project_name
    Owner = "lks-team"
  }
}

# Route table association for private subnet 1
resource "aws_route_table_association" "private_rta_1" {
  subnet_id      = data.terraform_remote_state.base.outputs.private_subnet_1_id
  route_table_id = aws_route_table.private_rt_with_nat.id
}

# Route table association for private subnet 2
resource "aws_route_table_association" "private_rta_2" {
  subnet_id      = data.terraform_remote_state.base.outputs.private_subnet_2_id
  route_table_id = aws_route_table.private_rt_with_nat.id
} 