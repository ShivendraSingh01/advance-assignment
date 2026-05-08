# Jenkins Setup

## Minimum setup

1. Install Jenkins with Git, Pipeline, Credentials, and JUnit plugins.
2. Add this repository as a Pipeline or Multibranch Pipeline job:
   `https://github.com/ShivendraSingh01/advance-assignment.git`
3. Use the repo `Jenkinsfile`.
4. Make sure the Jenkins agent has Python 3.11 or `python3`, pip, Docker, and Git.
5. Run the job once with the default parameters.

## Recommended Jenkins job type

Use a Multibranch Pipeline job. That gives you pull request and branch builds.
The Jenkinsfile does not run a second Git checkout; Jenkins handles SCM checkout
from the job configuration.

Manual builds use the Jenkins build button and parameters. Scheduled builds use
the cron trigger already present in the Jenkinsfile.

## Shared Library

The Jenkinsfile uses this same repo as a Jenkins shared library:

```groovy
@Library('churn-shared-library') _
```

Configure it in Jenkins:

1. Go to **Manage Jenkins** > **System**.
2. Find **Global Trusted Pipeline Libraries**.
3. Add a library named `churn-shared-library`.
4. Set default version to `main`.
5. Use Git as the retrieval method.
6. Repository URL:

```text
https://github.com/ShivendraSingh01/advance-assignment.git
```

7. Set library path to:

```text
jenkins/shared-library
```

The shared-library functions live in `jenkins/shared-library/vars` and own the
CI actions for branch policy, agent checks, artifact packaging, promotion,
metadata, feedback summaries, Python setup, Terraform, and Helm deployment.
ArgoCD is used only as a Kubernetes visibility and health check when enabled.

## Git checkout fix

If Jenkins shows `https://github.com/yourrepo/churn-mlops-project.git`, the job
is still using the old placeholder URL. Open the Jenkins job configuration and
set the repository URL to:

```text
https://github.com/ShivendraSingh01/advance-assignment.git
```

For a public repository, leave credentials as `None`. For a private repository,
create a GitHub personal access token and save it in Jenkins as a username/token
credential. GitHub passwords are not supported for Git HTTPS checkout.

If the workspace already has the wrong remote cached, run **Wipe out current
workspace** from the Jenkins job page or delete the job workspace once, then
build again.

## Optional integrations

- SonarQube scanner: enable with `RUN_SONAR=true`.
- Gitleaks: runs through Docker when `RUN_SECURITY_SCANS=true`.
- Trivy: runs through Docker when `RUN_SECURITY_SCANS=true`.
- OWASP ZAP baseline: runs through Docker when `RUN_DAST=true`.
- ArgoCD CLI: required when `RUN_ARGOCD_CHECK=true`.
- Terraform CLI: required when `RUN_TERRAFORM_PLAN=true` or `DEPLOY=true`.
- AWS CLI, Helm, and kubectl: required when `DEPLOY=true`.

## Agent tool check

The Jenkinsfile has an `Agent Tool Check` stage. It checks these tools before
running the build:

- `git`
- `python3`
- `python3-pip`
- `python3-venv`
- Docker
- `curl`

It also checks optional installed tools and only fails when the matching Jenkins
parameter is enabled:

- `sonar-scanner` when `RUN_SONAR=true`
- `argocd` when `RUN_ARGOCD_CHECK=true`
- `terraform` when `RUN_TERRAFORM_PLAN=true` or `DEPLOY=true`
- `aws`, `helm`, and `kubectl` when `DEPLOY=true`

Gitleaks, Trivy, and OWASP ZAP are not installed on the Jenkins server. They run
as Docker containers:

- `zricethezav/gitleaks:latest`
- `aquasec/trivy:latest`
- `ghcr.io/zaproxy/zaproxy:stable`

Gitleaks uses `.gitleaks.toml` to ignore generated reports, model pickle files,
local virtual environments, and the sample CSV dataset.

Manual install command for Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y git python3 python3-pip python3-venv docker.io curl
```

For deployment jobs, also install these tools:

```bash
# AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# kubectl
curl -LO "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ArgoCD CLI
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 0755 argocd /usr/local/bin/argocd
```

Docker also needs daemon access. If Docker is installed but Jenkins cannot use
it, run:

```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

## Credentials to create

- `dockerhub-token`: username/password credential used when `PUSH_IMAGE=true`.
- `nexus-credentials`: optional username/password credential used when
  `NEXUS_REPO_URL` is set for Nexus uploads.
- `aws-jenkins-credentials`: username/password credential where username is
  `AWS_ACCESS_KEY_ID` and password is `AWS_SECRET_ACCESS_KEY`.
- `argocd-token`: optional Secret text credential for ArgoCD checks.
- SonarQube token: configure it in your Jenkins SonarQube installation if you
  decide to use SonarQube.

For SonarCloud, set:

- `SONAR_PROJECT_KEY`: `ShivendraSingh01_advance-assignment`.
- `SONAR_ORGANIZATION`: `shivendrasingh01`.
- `SONAR_TOKEN_CREDENTIAL_ID`: Jenkins Secret text credential ID. Default:
  `sonarcloud-token`.

To add the token in Jenkins:

1. Open Jenkins.
2. Go to **Manage Jenkins** > **Credentials**.
3. Choose the global credentials domain.
4. Click **Add Credentials**.
5. Kind: **Secret text**.
6. Secret: paste your SonarCloud token.
7. ID: `sonarcloud-token`.
8. Save.

The pipeline reads that secret only during the Sonar stage.

## Artifact Repository

If you have Nexus, set:

- `NEXUS_REPO_URL`: upload URL, for example
  `https://nexus.example.com/repository/churn-app`.
- `NEXUS_CREDENTIAL_ID`: Jenkins username/password credential ID.

If `NEXUS_REPO_URL` is empty, Jenkins still creates and archives the local
artifact tarball in `reports/`.

## AWS EKS Terraform And Helm Deployment

Terraform creates a small AWS EKS environment:

- VPC, internet gateway, route table, and two public subnets
- EKS control plane and managed node group

Helm deploys the app after Terraform finishes:

- Chart: `charts/churn-app`
- Namespace: `churn-<environment>`
- Release: `churn-app`
- Deployment: `churn-app`
- Service: `churn-app`

ArgoCD does not deploy the app in this pipeline. It is only used after Helm to
check the Kubernetes app health/status.

Set these Jenkins parameters:

- `AWS_REGION`: AWS region of the EKS cluster, for example `ap-south-1`.
- `EKS_CLUSTER_NAME`: EKS cluster name to create and manage.
- `AWS_CREDENTIAL_ID`: Jenkins credential ID, default `aws-jenkins-credentials`.
- `EKS_VERSION`: EKS Kubernetes version.
- `EKS_NODE_INSTANCE_TYPE`: worker node instance type, default `t3.small`.
- `DEPLOY_STRATEGY`: passed to Helm as a Kubernetes label for traceability.
- `RUN_ARGOCD_CHECK`: checks the app in ArgoCD after Helm deployment.
- `ARGOCD_SERVER`: ArgoCD server host, for example `argocd.example.com`.
- `ARGOCD_APP_NAME`: ArgoCD app name to check. Empty uses
  `churn-app-<environment>`.
- `ARGOCD_TOKEN_CREDENTIAL_ID`: Jenkins Secret text credential ID. Default:
  `argocd-token`.

Use `RUN_TERRAFORM_PLAN=true` to only run:

```bash
terraform plan
```

Use `DEPLOY=true` to run:

```bash
terraform plan
terraform apply
helm upgrade --install
argocd app get
argocd app wait --health
```

Terraform creates the EKS cluster, node group, VPC, subnets, and IAM roles.
Helm creates the Kubernetes namespace, deployment, and service. For an
assignment, the simplest AWS setup is to use a temporary IAM user with broad
permissions, then delete it after the assignment.

To use ArgoCD checking, create an ArgoCD application that points at this repo
and chart, but keep automatic sync disabled if you want Jenkins/Helm to remain
the deployment owner:

```bash
argocd app create churn-app-dev \
  --repo https://github.com/ShivendraSingh01/advance-assignment.git \
  --path charts/churn-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace churn-dev
```

Then create an ArgoCD token and store it in Jenkins as Secret text with ID:

```text
argocd-token
```

For `dev`, Helm creates a Kubernetes `LoadBalancer` service. After deploy,
Jenkins prints the service and writes the detected URL to:

```text
reports/service-url-dev.txt
```

Use that hostname as the DAST target:

```text
DAST_TARGET_URL=http://<load-balancer-hostname>
```

At minimum, the Jenkins AWS identity needs permissions across:

- EKS cluster and node group management
- EC2 VPC, subnet, route table, internet gateway, and security group operations
- IAM role creation and policy attachment for EKS
- STS caller identity access

Remember to destroy the EKS environment after testing to avoid AWS charges.

## DAST Target URL

OWASP ZAP runs in Docker when `RUN_DAST=true`. It needs a real reachable URL.
Set:

```text
DAST_TARGET_URL=http://your-load-balancer-or-public-app-url
```

Do not use the placeholder `http://churn-app-dev.example.com` unless you own
that DNS name and it resolves to your app.

## Local checks

Run these before pushing:

```bash
python3 -m pip install -r requirements.txt
python3 -m pytest tests --cov=app --cov=model --cov-fail-under=35
python3 -m flake8 app model tests
docker build -t churn-app:local .
```

On Ubuntu/Debian Jenkins agents, install Python, pip, and venv with:

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv
```

This matters because the Jenkinsfile creates a local `.venv` and installs the
CI dependencies inside it.

To enable the local Git hook:

```bash
git config core.hooksPath .githooks
```

## Deployment notes

The Jenkinsfile asks for approval before `qa` or `prod` deployments. The
`DEPLOY_STRATEGY` value is stored as a Kubernetes label for traceability.
