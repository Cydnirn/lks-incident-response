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

# Target EC2 Instance
module "target" {
  source = "../../modules/compute/ec2"

  project_name  = var.project_name
  instance_name = "target-host"
  ami           = var.target_ami
  instance_type = var.target_instance_type
  key_name      = var.target_key_name
  security_group_ids = [
    data.terraform_remote_state.base.outputs.local_access_security_group_id,
  ]
  subnet_id                   = data.terraform_remote_state.base.outputs.private_subnet_1_id
  iam_instance_profile        = "EC2SSM"
  root_volume_size            = var.target_root_volume_size
  root_volume_type            = var.target_root_volume_type
  root_volume_encrypted       = var.target_root_volume_encrypted
  associate_public_ip_address = false
  user_data = templatefile("${path.module}/user_data.sh", {

  })
  # Implicit dependency on bastion to ensure NAT routing is ready
  # This ensures the bastion instance is fully created before creating LLM
  depends_on = [
    data.terraform_remote_state.bastion
  ]
}
