variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "lks"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.4.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
  default     = "10.0.3.0/24"
}

variable "availability_zone_1" {
  description = "Availability zone for subnets"
  type        = string
  default     = "us-east-1a"
} 

variable "availability_zone_2" {
  description = "Availability zone for subnets"
  type        = string
  default     = "us-east-1b"
}