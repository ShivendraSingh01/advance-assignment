# Terraform With Jenkins And AWS EKS

This folder creates a small AWS EKS environment and deploys the app to it:

- VPC
- Internet gateway
- Two public subnets
- EKS control plane
- EKS managed node group
- Namespace: `churn-<environment>`
- Deployment: `churn-app`
- Service: `churn-app`

Jenkins passes the AWS region, EKS cluster name, environment, app name, and image
tag to Terraform.

Required Jenkins parameters:

- `AWS_REGION`
- `EKS_CLUSTER_NAME`
- `AWS_CREDENTIAL_ID`
- `EKS_VERSION`
- `EKS_NODE_INSTANCE_TYPE`

The AWS identity used by Jenkins must be allowed to manage:

- VPC, subnet, route table, and internet gateway resources
- EKS clusters and managed node groups
- IAM roles and policy attachments used by EKS
- EC2 instances created by the managed node group

For a class assignment, a temporary admin-like IAM policy is simplest. For real
work, scope the permissions more tightly.

Remember to destroy the cluster when done to avoid AWS charges:

```bash
terraform -chdir=infra/terraform destroy
```
