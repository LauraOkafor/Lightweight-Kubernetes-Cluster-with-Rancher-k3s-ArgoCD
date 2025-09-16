# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
  default     = "k8s-rancher-argocd"
}

variable "key_pair_name" {
  description = "Name of AWS key pair for EC2 access"
  type        = string
}

variable "master_instance_type" {
  description = "Instance type for master node"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.small"
}

variable "worker_node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 0
}

