#!/bin/bash

# System Update
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    apache2-utils \
    iptables

# Install Docker
echo "[INFO] Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Enable Docker
systemctl enable docker
systemctl start docker
usermod -aG docker root

# Install Docker Compose
echo "[INFO] Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/2.39.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
sysctl -p

# Detect network interface
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

# Setup iptables untuk NAT
iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE
iptables -F FORWARD

# Save iptables to file
iptables-save > /etc/iptables.rules

# Create systemd service to restore iptables on boot
cat > /etc/systemd/system/iptables-restore.service << EOF
[Unit]
Description=Restore iptables rules
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore < /etc/iptables.rules
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl daemon-reload
systemctl enable iptables-restore
systemctl start iptables-restore

# Create directory for WireGuard Easy
mkdir -p /opt/wireguard-easy
cd /opt/wireguard-easy

# Create docker-compose.yml for WG-Easy
cat > docker-compose.yml <<EOF
services:
  wg-easy:
    environment:
      # Change Language:
      - LANG=en
      # Required:
      # Change this to your host's public address
      - WG_HOST=${wg_host}
      # The default password is lkspass
      - PASSWORD_HASH=\$\$2a\$\$12\$\$OEDu7fC0asOCim1iXyy/4.sgI9T8fPomOBkjlXNffk4rJaIut8FvK
      - WG_PORT=51820
      - WG_DEFAULT_ADDRESS=10.200.0.x
      - WG_DEFAULT_DNS=1.1.1.1,8.8.8.8
      - WG_MTU=1420
      - WG_PERSISTENT_KEEPALIVE=25
      - UI_TRAFFIC_STATS=true
      - UI_CHART_TYPE=2
      - UI_ENABLE_SORT_CLIENTS=true
    image: ghcr.io/wg-easy/wg-easy
    container_name: wg-easy
    volumes:
      - .:/etc/wireguard
    ports:
      - "51820:51820/udp"
      - "51821:51821/tcp"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
    devices:
      - /dev/net/tun:/dev/net/tun
EOF

# Start WG-Easy
docker compose up -d

# Create systemd service for auto-start
cat > /etc/systemd/system/wg-easy.service << EOF
[Unit]
Description=WG-Easy
Wants=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/wireguard-easy
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable service
systemctl enable wg-easy.service

# Setup logrotate for container logs
cat > /etc/logrotate.d/docker << EOF
/var/lib/docker/containers/*/*.log {
  rotate 7
  daily
  compress
  size=1M
  missingok
  delaycompress
  copytruncate
}
EOF

# Cleanup
apt-get autoremove -y
apt-get autoclean

# Disable UFW
ufw disable

# Log completion
echo "$(date): Bastion NAT instance with WireGuard setup completed" >> /var/log/user-data.log
echo "WireGuard Easy Web UI: http://$WG_HOST:51821" >> /var/log/user-data.log
echo "Admin Password: $WG_ADMIN_PASSWORD" >> /var/log/user-data.log