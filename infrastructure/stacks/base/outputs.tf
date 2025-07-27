# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_1_id" {
  description = "ID of the public subnet 1"
  value       = module.vpc.public_subnet_1_id
}

output "public_subnet_2_id" {
  description = "ID of the public subnet 2"
  value       = module.vpc.public_subnet_2_id
}

output "private_subnet_1_id" {
  description = "ID of the private subnet 1"
  value       = module.vpc.private_subnet_1_id
}

output "private_subnet_2_id" {
  description = "ID of the private subnet 2"
  value       = module.vpc.private_subnet_2_id
}

# Security Groups Outputs
output "local_access_security_group_id" {
  description = "ID of the local access security group"
  value       = module.local_access_sg.security_group_id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = module.database_sg.security_group_id
}

output "all_traffict_security_group_id" {
  description = "ID of the all traffic security group"
  value       = module.all_traffict_sg.security_group_id
} 