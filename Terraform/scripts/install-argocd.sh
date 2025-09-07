#!/bin/bash

set -e

echo "Installing ArgoCD..."

# Wait for k3s to be fully ready
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD pods to be ready
echo "Waiting for ArgoCD pods to start..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Expose ArgoCD server via NodePort
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort","ports":[{"port":443,"targetPort":8080,"nodePort":30080}]}}'

# Get initial admin password
echo "Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Save password to file
echo $ARGOCD_PASSWORD > /home/ubuntu/argocd-password.txt
chown ubuntu:ubuntu /home/ubuntu/argocd-password.txt

echo "================================"
echo "ArgoCD Installation Complete!"
echo "================================"
echo "URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):30080"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
echo "Password saved to: /home/ubuntu/argocd-password.txt"
echo "================================"