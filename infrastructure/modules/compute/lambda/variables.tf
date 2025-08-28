variable "function_name" {
  type        = string
  description = "The name of the Lambda function"
}

variable "function_file" {
  type        = string
  description = "The file of the Lambda function"
}

variable "function_environments" {
  type = map(string)
}

variable "function_iam_role" {
  type        = string
  description = "The IAM role of the Lambda function"
}


variable "memory_size" {
  type        = number
  description = "The memory size of the Lambda function"
  default     = 128
}

variable "storage_size" {
  type        = number
  description = "The storage size of the Lambda function"
  default     = 512
}

variable "timeout" {
  type        = number
  description = "The timeout of the Lambda function"
  default     = 3
}

variable "runtime" {
  type        = string
  description = "The runtime of the Lambda function"
}

variable "handler" {
  type        = string
  description = "The handler of the Lambda function"
}

variable "layers" {
  type        = list(string)
  description = "The layers of the Lambda function"
}

variable "vpc_config_enabled" {
  type        = bool
  description = "Whether to enable VPC configuration for the Lambda function"
  default     = false
}

variable "security_group_ids" {
  type        = list(string)
  description = "The security group IDs for the Lambda function"
  default     = [""]
}

variable "subnet_ids" {
  type        = list(string)
  description = "The subnet IDs for the Lambda function"
  default     = [""]
}
