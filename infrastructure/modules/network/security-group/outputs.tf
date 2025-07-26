output "security_group_id" {
  description = "ID of the created security group"
  value       = aws_security_group.dynamic_sg.id
}

output "security_group_arn" {
  description = "ARN of the created security group"
  value       = aws_security_group.dynamic_sg.arn
}

output "security_group_name" {
  description = "Name of the created security group"
  value       = aws_security_group.dynamic_sg.name
}

output "security_group_vpc_id" {
  description = "VPC ID of the security group"
  value       = aws_security_group.dynamic_sg.vpc_id
} 