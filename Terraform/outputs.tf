# outputs.tf
output "master_public_ip" {
  description = "Public IP of the master node"
  value       = aws_instance.k8s_master.public_ip
}

output "master_private_ip" {
  description = "Private IP of the master node"
  value       = aws_instance.k8s_master.private_ip
}

output "worker_public_ips" {
  description = "Public IPs of worker nodes"
  value       = aws_instance.k8s_worker[*].public_ip
}

output "ssh_command" {
  description = "SSH command to connect to master node"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.k8s_master.public_ip}"
}

output "rancher_url" {
  description = "Rancher access URL"
  value       = "https://${aws_instance.k8s_master.public_ip}"
}

output "rancher_bootstrap_password" {
  description = "Command to get Rancher bootstrap password"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.k8s_master.public_ip} 'cat /home/ubuntu/rancher-password.txt'"
}


output "argocd_url" {
  description = "ArgoCD access URL"
  value       = "http://${aws_instance.k8s_master.public_ip}:8080"
}