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

# Common tags and security group rules
locals {
  # Security group rules configuration (only common ones)
  security_group_rules = {
    # Local Access Rules (for private instances)
    local_access = {
      ingress = [
        {
          description = "SSH from private network"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = [var.vpc_cidr]
        },
        {
          description = "ICMP from private network"
          from_port   = -1
          to_port     = -1
          protocol    = "icmp"
          cidr_blocks = [var.vpc_cidr]
        }
      ]
      egress = [
        {
          description = "All outbound traffic"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }

    # Database Rules
    database = {
      ingress = [
        {
          description = "All traffic from private network"
          from_port   = 0
          to_port     = 5432
          protocol    = "tcp"
          cidr_blocks = [var.vpc_cidr]
        }
      ]
      egress = [
        {
          description = "All outbound traffic"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }

    all = {
      ingress = [
        {
          description = "All traffic from private network"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      egress = [
        {
          description = "All outbound traffic"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/network/vpc"

  project_name          = var.project_name
  vpc_cidr              = var.vpc_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr 
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  availability_zone_1   = var.availability_zone_1
  availability_zone_2   = var.availability_zone_2
}

# Common Security Groups (only database and local access)
module "local_access_sg" {
  source = "../../modules/network/security-group"

  project_name        = var.project_name
  security_group_name = "local-access-sg"
  security_group_type = "local-access"
  description         = "Security group for local access services"
  vpc_id              = module.vpc.vpc_id
  ingress_rules       = local.security_group_rules.local_access.ingress
  egress_rules        = local.security_group_rules.local_access.egress
}

module "database_sg" {
  source = "../../modules/network/security-group"

  project_name        = var.project_name
  security_group_name = "database-sg"
  security_group_type = "database"
  description         = "Security group for database services"
  vpc_id              = module.vpc.vpc_id
  ingress_rules       = local.security_group_rules.database.ingress
  egress_rules        = local.security_group_rules.database.egress
} 

module "all_traffict_sg" {
  source = "../../modules/network/security-group"

  project_name        = var.project_name
  security_group_name = "all-traffict-sg"
  security_group_type = "all"
  description         = "Security group for all traffic"
  vpc_id              = module.vpc.vpc_id
  ingress_rules       = local.security_group_rules.all.ingress
  egress_rules        = local.security_group_rules.all.egress
} 