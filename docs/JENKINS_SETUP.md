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

The shared-library wrappers live in `jenkins/shared-library/vars` and call the
scripts under `scripts/ci`.

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
- Terraform CLI: required when `RUN_TERRAFORM_PLAN=true` or `DEPLOY=true`.

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
- `terraform` when `RUN_TERRAFORM_PLAN=true` or `DEPLOY=true`

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

## AWS EKS Terraform Deployment

The pipeline creates Kubernetes resources on an existing AWS EKS cluster through
Terraform. It creates:

- Namespace: `churn-<environment>`
- Deployment: `churn-app`
- Service: `churn-app`

Set these Jenkins parameters:

- `AWS_REGION`: AWS region of the EKS cluster, for example `ap-south-1`.
- `EKS_CLUSTER_NAME`: EKS cluster name to create and manage.
- `AWS_CREDENTIAL_ID`: Jenkins credential ID, default `aws-jenkins-credentials`.
- `EKS_VERSION`: EKS Kubernetes version.
- `EKS_NODE_INSTANCE_TYPE`: worker node instance type, default `t3.small`.
- `DEPLOY_STRATEGY`: stored as a Kubernetes label for traceability.

Use `RUN_TERRAFORM_PLAN=true` to only run:

```bash
terraform plan
```

Use `DEPLOY=true` to run:

```bash
terraform plan
terraform apply
```

Terraform creates the EKS cluster, node group, VPC, subnets, IAM roles, and the
Kubernetes app resources. For an assignment, the simplest AWS setup is to use a
temporary IAM user with broad permissions, then delete it after the assignment.

For `dev`, Terraform creates a Kubernetes `LoadBalancer` service. After deploy,
Jenkins prints these Terraform outputs:

```text
service_hostname
service_ip
```

Use the hostname as the DAST target:

```text
DAST_TARGET_URL=http://<service_hostname>
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

The Jenkinsfile asks for approval before `qa` or `prod` deployments.

For a class assignment, rolling deployment is enough. Blue-green and canary are
included as lightweight placeholders so you can explain the strategy without
needing a service mesh or advanced traffic routing.
