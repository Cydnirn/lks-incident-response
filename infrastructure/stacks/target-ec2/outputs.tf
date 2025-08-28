output "target_instance_id" {
  description = "ID of the target instance"
  value       = module.target.instance_id
}

output "target_private_ip" {
  description = "Private IP of the target instance"
  value       = module.target.instance_private_ip
}
