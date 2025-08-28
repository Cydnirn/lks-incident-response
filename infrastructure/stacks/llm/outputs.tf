output "llm_instance_id" {
  description = "ID of the llm instance"
  value       = module.llm.instance_id
}

output "llm_private_ip" {
  description = "Private IP of the llm instance"
  value       = module.llm.instance_private_ip
}

output "llm_public_ip" {
  description = "Public IP of the llm instance"
  value       = module.llm.instance_public_ip
}

output "llm_ssh_command" {
  description = "SSH command to connect to llm instance"
  value       = module.llm.ssh_command
}

output "llm_api_url" {
  description = "URL to access llm API"
  value       = "http://${module.llm.instance_private_ip}:11434"
}
