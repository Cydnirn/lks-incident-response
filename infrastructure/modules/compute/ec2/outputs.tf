output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.instance.id
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.instance.private_ip
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.instance.public_ip
}

output "instance_eip" {
  description = "Elastic IP of the EC2 instance (if created)"
  value       = var.create_eip ? aws_eip.instance_eip[0].public_ip : null
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${var.create_eip ? aws_eip.instance_eip[0].public_ip : aws_instance.instance.public_ip}"
}

output "primary_network_interface_id" {
  description = "ID of the primary network interface"
  value       = aws_instance.instance.primary_network_interface_id
} 