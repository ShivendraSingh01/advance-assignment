variable "aws_region" {
  type        = string
  description = "AWS region where the EKS cluster exists."
}

variable "eks_cluster_name" {
  type        = string
  description = "Existing AWS EKS cluster name."
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
