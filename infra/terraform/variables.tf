variable "aws_region" {
  type        = string
  description = "AWS region where the EKS cluster will be created."
}

variable "eks_cluster_name" {
  type        = string
  description = "AWS EKS cluster name to create and manage."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "app_name" {
  type        = string
  default     = "churn-app"
  description = "Application name used for Kubernetes resources."
}

variable "image" {
  type        = string
  default     = "shivam1999/churn-app:latest"
  description = "Docker image to deploy."
}

variable "replicas" {
  type        = number
  default     = 1
  description = "Number of application pods."
}

variable "service_type" {
  type        = string
  default     = "ClusterIP"
  description = "Kubernetes service type."
}

variable "deployment_strategy" {
  type        = string
  default     = "rolling"
  description = "Deployment strategy label used for traceability."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.50.0.0/16"
  description = "CIDR block for the EKS VPC."
}

variable "eks_version" {
  type        = string
  default     = "1.30"
  description = "EKS Kubernetes version."
}

variable "node_instance_types" {
  type        = list(string)
  default     = ["t3.small"]
  description = "Managed node group instance types."
}

variable "node_min_size" {
  type        = number
  default     = 1
  description = "Minimum EKS node count."
}

variable "node_desired_size" {
  type        = number
  default     = 1
  description = "Desired EKS node count."
}

variable "node_max_size" {
  type        = number
  default     = 2
  description = "Maximum EKS node count."
}
