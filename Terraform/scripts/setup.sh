#!/bin/bash
# setup.sh - Initial server setup with Rancher + ArgoCD

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

# Setup kubeconfig for ubuntu user
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
export KUBECONFIG=/home/ubuntu/.kube/config

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
for i in {1..30}; do
  if kubectl get nodes >/dev/null 2>&1; then
    echo "k3s is ready"
    break
  fi
  echo "Waiting for k3s... ($i/30)"
  sleep 10
done

# Install Rancher
docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  --name rancher \
  rancher/rancher:latest

# Wait for Rancher to start and get password
sleep 60

# Get Rancher bootstrap password
BOOTSTRAP_PASSWORD=$(docker logs rancher 2>&1 | grep "Bootstrap Password:" | tail -1 | cut -d' ' -f3)
echo $BOOTSTRAP_PASSWORD > /home/ubuntu/rancher-password.txt
chown ubuntu:ubuntu /home/ubuntu/rancher-password.txt

# -------------------------------
# Install ArgoCD
# -------------------------------
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --validate=false

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD pods..."
sleep 60

# Expose ArgoCD on port 8080
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":8080,"nodePort":30080}]}}'

# Get ArgoCD password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "admin")
echo $ARGOCD_PASSWORD > /home/ubuntu/argocd-password.txt
chown ubuntu:ubuntu /home/ubuntu/argocd-password.txt

# -------------------------------
# Done
# -------------------------------
echo "Setup completed successfully!"
echo "Rancher URL: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "ArgoCD URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):30080"
echo "Rancher password: /home/ubuntu/rancher-password.txt"
echo "ArgoCD password: /home/ubuntu/argocd-password.txt"