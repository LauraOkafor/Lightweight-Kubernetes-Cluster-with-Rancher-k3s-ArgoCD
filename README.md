# 🚀 GitOps with Rancher, k3s, and ArgoCD

This project demonstrates how to provision infrastructure with **Terraform**, set up a lightweight **Kubernetes cluster (k3s)** managed by **Rancher**, and enable a **GitOps workflow** with **ArgoCD**.  

The goal is to show how DevOps teams can automate infrastructure, deploy applications via Git, and achieve **self-healing & continuous delivery** in the cloud.

---

## 📌 Project Overview

- **Cloud Provider:** AWS (EC2, VPC, Security Groups)  
- **Orchestration:** Rancher + k3s  
- **GitOps Tool:** ArgoCD  
- **IaC:** Terraform  
- **Automation Scripts:** Bash  
- **Demo App:** Simple Nginx-based web app  

✅ Fully automated infrastructure provisioning  
✅ Kubernetes cluster managed by Rancher  
✅ GitOps deployment pipeline with ArgoCD  
✅ Drift detection & self-healing demonstration  

---

 ## ⚡ Features
- **Infrastructure as Code (IaC):** Automated AWS infrastructure with Terraform.
- **Automated Rancher Setup:** Rancher is installed automatically on the master node.
- **Automated ArgoCD Setup:** ArgoCD is deployed automatically into the cluster.
- **GitOps Workflow:** Applications deployed & updated automatically via ArgoCD.
- **Self-Healing:** ArgoCD restores drifted resources to match Git.
- **Scalable Setup:** Easily extendable to multiple environments.

## 🔑 Prerequisites
- AWS Account with credentials configured
- Terraform installed
- kubectl installed
- GitHub repo for storing manifests
---

## 🏗️ Project Architecture

```mermaid
flowchart TD
    A[Terraform] -->|Provision| B[AWS EC2 Instances]
    B --> C[Rancher Server]
    C --> D[k3s Master Node]
    D --> E[Worker Nodes]
    D --> F[ArgoCD]
    F --> G[GitHub Repo]
    F --> H[Demo Application]
```

## ⚙️ Setup Instructions
**Clone Repository**
```
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>
```

**Provision Infrastructure**
```
cd terraform
terraform init
terraform apply -auto-approve
```

**Access Dashboards**
- **Rancher UI:** https://<EC2_PUBLIC_IP>:9443
- **ArgoCD UI:** https://<EC2_PUBLIC_IP>:30080 (check outputs after Terraform apply)

---

## 🔍 Demonstration Scenarios
**Drift Detection**
```
kubectl delete pod <pod-name>

```
✅ ➡️ ArgoCD detects drift and recreates the pod automatically.

**Update Test**
	- Change image version in deployment.yaml
 - Commit & push to GitHub
✅ ➡️ ArgoCD detects change and rolls out the new version.

## 📊 Success Criteria
- Rancher accessible and managing k3s cluster
- ArgoCD UI accessible
- Applications deployed from Git repo
- Self-healing tested and working

## 🧹 Cleanup
```
cd terraform
terraform destroy -auto-approve
```
---
## ✨ Future Enhancements
- Add monitoring with Prometheus + Grafana
- Add centralized logging with ELK stack
- Implement CI/CD pipeline for Terraform
- Expand to multi-environment (dev/staging/prod)
---

### 👩🏽‍💻 Author
**Laura Okafor-Ndubueze**
- 🌐 LinkedIn
- 📧 lauraamanda56@gmail.com
- 💻 Passionate about DevOps, Cloud & GitOps
