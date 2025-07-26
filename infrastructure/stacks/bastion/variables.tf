variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "lks"
}

variable "bastion_ami" {
  description = "AMI ID for the bastion host"
  type        = string
  default     = "ami-020cba7c55df1f615"
}

variable "bastion_instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_key_name" {
  description = "Name of the key pair for bastion host"
  type        = string
  default     = "vockey"
}

variable "bastion_root_volume_size" {
  description = "Size of the root volume in GB for bastion host"
  type        = number
  default     = 20
}

variable "bastion_root_volume_type" {
  description = "Type of the root volume for bastion host"
  type        = string
  default     = "gp3"
}

variable "bastion_root_volume_encrypted" {
  description = "Whether to encrypt the root volume for bastion host"
  type        = bool
  default     = true
}

variable "wg_admin_password" {
  description = "WireGuard admin password"
  type        = string
  default     = "$$2a$12$8PtK.pNSIcSu02vpUvK3sOxcIDG5rjI6z/nTC4Gm7PSmRxl9Gqcjm"
  sensitive   = true
} 