output "bastion_instance_id" {
  description = "ID of the bastion instance"
  value       = module.bastion.instance_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion.instance_eip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion host"
  value       = module.bastion.instance_private_ip
}

output "bastion_security_group_id" {
  description = "Security group ID of the bastion host"
  value       = module.bastion_sg.security_group_id
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = module.bastion.ssh_command
}

output "wireguard_ui_url" {
  description = "URL to access WireGuard UI"
  value       = "http://${module.bastion.instance_eip}:51821"
} 