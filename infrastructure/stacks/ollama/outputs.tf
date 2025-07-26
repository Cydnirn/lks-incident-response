output "ollama_instance_id" {
  description = "ID of the Ollama instance"
  value       = module.ollama.instance_id
}

output "ollama_private_ip" {
  description = "Private IP of the Ollama instance"
  value       = module.ollama.instance_private_ip
}

output "ollama_public_ip" {
  description = "Public IP of the Ollama instance"
  value       = module.ollama.instance_eip
}

output "ollama_ssh_command" {
  description = "SSH command to connect to Ollama instance"
  value       = module.ollama.ssh_command
}

output "ollama_api_url" {
  description = "URL to access Ollama API"
  value       = "http://${module.ollama.instance_eip}:11434"
} 