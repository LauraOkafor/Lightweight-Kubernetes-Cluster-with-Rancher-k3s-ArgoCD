#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Start ArgoCD
docker run -d --name argocd --restart unless-stopped -p 30080:8080 argoproj/argocd:latest

echo "ArgoCD starting at port 30080" > /home/ubuntu/setup-complete.txt
chown ubuntu:ubuntu /home/ubuntu/setup-complete.txt