terraform {
  required_version = ">= 1.4.0"
}

variable "environment" {
  type = string
}

variable "app_name" {
  type    = string
  default = "churn-app"
}

output "deployment_name" {
  value = "${var.app_name}-${var.environment}"
}
