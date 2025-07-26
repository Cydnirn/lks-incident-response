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

variable "llm_ami" {
  description = "AMI ID for the Ollama instance"
  type        = string
  default     = "ami-020cba7c55df1f615"
}

variable "llm_instance_type" {
  description = "EC2 instance type for Ollama"
  type        = string
  default     = "m5.large"
}

variable "llm_key_name" {
  description = "Key pair name for SSH access to Ollama"
  type        = string
  default     = "vockey"
}

variable "llm_root_volume_size" {
  description = "Size of the root volume in GB for Ollama"
  type        = number
  default     = 30
}

variable "llm_root_volume_type" {
  description = "Type of the root volume for Ollama"
  type        = string
  default     = "gp3"
}

variable "llm_root_volume_encrypted" {
  description = "Whether to encrypt the root volume for Ollama"
  type        = bool
  default     = true
}

variable "llm_model" {
  description = "Ollama model to pull"
  type        = string
  default     = "phi4-mini"
} 