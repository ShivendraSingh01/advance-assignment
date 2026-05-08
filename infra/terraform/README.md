# Terraform With Jenkins And AWS EKS

This folder creates Kubernetes resources on an existing AWS EKS cluster:

- Namespace: `churn-<environment>`
- Deployment: `churn-app`
- Service: `churn-app`

Jenkins passes the AWS region, EKS cluster name, environment, app name, and image
tag to Terraform.

Required Jenkins parameters:

- `AWS_REGION`
- `EKS_CLUSTER_NAME`
- `AWS_CREDENTIAL_ID`

The AWS identity used by Jenkins must be allowed to call:

- `eks:DescribeCluster`
- Kubernetes API operations inside the EKS cluster

The EKS cluster must already exist. This Terraform config deploys the app to the
cluster; it does not create the EKS cluster itself.
