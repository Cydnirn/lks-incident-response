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

variable "target_ami" {
  description = "AMI ID for the target instance"
  type        = string
  default     = "ami-0360c520857e3138f"
}

variable "target_instance_type" {
  description = "EC2 instance type for target"
  type        = string
  default     = "t3.micro"
}

variable "target_key_name" {
  description = "Key pair name for SSH access to target"
  type        = string
  default     = "LLM"
}

variable "target_root_volume_size" {
  description = "Size of the root volume in GB for Ollama"
  type        = number
  default     = 8
}

variable "target_root_volume_type" {
  description = "Type of the root volume for Ollama"
  type        = string
  default     = "gp3"
}

variable "target_root_volume_encrypted" {
  description = "Whether to encrypt the root volume for Ollama"
  type        = bool
  default     = true
}
