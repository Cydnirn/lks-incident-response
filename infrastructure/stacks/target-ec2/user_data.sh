#!/bin/bash

# Simple user data script for Ubuntu 24.04 - Loadsim application setup
export DEBIAN_FRONTEND=noninteractive

# Update system
apt-get update -y

# Install dependencies
apt-get install -y git wget

# Install Go
cd /tmp
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# Set Go environment
export PATH=$PATH:/usr/local/go/bin

# Create app directory and clone repository
mkdir -p /opt/loadsim
cd /opt/loadsim
git clone https://github.com/betuah/loadsim.git .

# Build application
/usr/local/go/bin/go mod tidy
/usr/local/go/bin/go build -o loadsim

# Create user and set permissions
useradd --system --shell /bin/false loadsim
chown -R loadsim:loadsim /opt/loadsim

# Create log directory
mkdir -p /var/log/loadsim
chown loadsim:loadsim /var/log/loadsim

# Create systemd service
cat > /etc/systemd/system/loadsim.service << 'EOF'
[Unit]
Description=Loadsim Application
After=network.target

[Service]
Type=simple
User=loadsim
Group=loadsim
WorkingDirectory=/opt/loadsim
ExecStart=/opt/loadsim/loadsim
Restart=always
RestartSec=5
StandardOutput=append:/var/log/loadsim/loadsim.log
StandardError=append:/var/log/loadsim/loadsim.log

[Install]
WantedBy=multi-user.target
EOF

# Start service
systemctl daemon-reload
systemctl enable loadsim
systemctl start loadsim

# Install CloudWatch agent
cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Create CloudWatch config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/loadsim/loadsim.log",
                        "log_group_name": "/ec2/lks-target-logs",
                        "log_stream_name": "{instance_id}/lks-target-logs/loadsim"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Log setup completion
echo "Setup completed at $(date)" >> /var/log/cloud-init-output.log
systemctl status loadsim >> /var/log/cloud-init-output.log
