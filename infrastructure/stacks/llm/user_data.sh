#!/bin/bash

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget unzip

# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
systemctl enable ollama
systemctl start ollama

# Wait for Ollama to be ready
sleep 10

# Pull the specified model
ollama pull ${ollama_model}

# Create a simple test script
cat > /home/ubuntu/test_ollama.sh << 'EOF'
#!/bin/bash
echo "Testing Ollama with phi4-mini model..."
ollama run phi4-mini "Hello, how are you today?"
EOF

chmod +x /home/ubuntu/test_ollama.sh
chown ubuntu:ubuntu /home/ubuntu/test_ollama.sh

# Disable UFW
ufw disable

# Create a systemd service for Ollama (already handled by installer)
# The installer creates /etc/systemd/system/ollama.service

echo "Ollama installation completed!"
echo "Model ${ollama_model} has been pulled"
echo "Ollama API is available on port 11434"
echo "Test the installation with: ./test_ollama.sh" 