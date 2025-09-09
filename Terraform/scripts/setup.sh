#!/bin/bash
# setup.sh - Initial server setup

set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    unzip \
    git

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install k3s (server mode)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

# Wait for k3s to be ready
sleep 30

# Install Rancher
docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  --name rancher \
  rancher/rancher:latest

# Wait for Rancher to start and get password
sleep 60

# Get bootstrap password
BOOTSTRAP_PASSWORD=$(docker logs rancher 2>&1 | grep "Bootstrap Password:" | tail -1 | cut -d' ' -f3)

# Save password to file
echo $BOOTSTRAP_PASSWORD > /home/ubuntu/rancher-password.txt
chown ubuntu:ubuntu /home/ubuntu/rancher-password.txt

# Create directory for manifests
mkdir -p /home/ubuntu/argocd

echo "Setup completed successfully!"
echo "Rancher URL: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "ArgoCD URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):30080"
echo "Rancher password: /home/ubuntu/rancher-password.txt"
echo "ArgoCD password: /home/ubuntu/argocd-password.txt"