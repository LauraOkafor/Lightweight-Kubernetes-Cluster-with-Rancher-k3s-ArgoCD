#!/bin/bash
# setup.sh - Automated k3s, Rancher & ArgoCD setup

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
    git \
    jq

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install k3s (server mode)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

# Wait for k3s to be ready
sleep 30

# Configure kubeconfig for ubuntu user
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# Make kubectl use this config during script run
export KUBECONFIG=/home/ubuntu/.kube/config

# Install Rancher (using different ports to avoid conflict with website)
docker run -d --restart=unless-stopped \
  -p 9443:443 -p 9080:80 \
  --privileged \
  --name rancher \
  rancher/rancher:latest

# Wait for Rancher to start
sleep 60

# Get Rancher bootstrap password
BOOTSTRAP_PASSWORD=$(docker logs rancher 2>&1 | grep "Bootstrap Password:" | tail -1 | awk '{print $NF}')
echo $BOOTSTRAP_PASSWORD > /home/ubuntu/rancher-password.txt
chown ubuntu:ubuntu /home/ubuntu/rancher-password.txt

# Install ArgoCD
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml



# Wait for ArgoCD pods to come up
echo "⏳ Waiting for ArgoCD pods..."
sleep 90

# Expose ArgoCD via NodePort
kubectl patch svc argocd-server -n argocd -p '{
  "spec": {
    "type": "NodePort",
    "ports": [
      {
        "port": 80,
        "targetPort": 8080,
        "nodePort": 30080,
        "protocol": "TCP"
      }
    ]
  }
}'

# Install nginx-ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller
sleep 30

# Apply your Application manifest (website-app.yaml)
kubectl wait --for=condition=Established crd/applications.argoproj.io --timeout=300s || true

kubectl apply -n argocd -f https://raw.githubusercontent.com/LauraOkafor/Lightweight-Kubernetes-Cluster-with-Rancher-k3s-ArgoCD/main/Terraform/kubernetes/argocd/website-app.yaml


# Save ArgoCD admin password
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo $ARGOCD_PASS > /home/ubuntu/argocd-password.txt
chown ubuntu:ubuntu /home/ubuntu/argocd-password.txt

echo "✅ Setup completed successfully!"
echo "🌐 Rancher URL: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9443"
echo "🌐 ArgoCD URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):30080"
echo "🔑 Rancher password: /home/ubuntu/rancher-password.txt"
echo "🔑 ArgoCD password: /home/ubuntu/argocd-password.txt"