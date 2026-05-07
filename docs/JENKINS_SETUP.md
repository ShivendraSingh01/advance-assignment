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

## Optional tools to install later

- SonarQube scanner: enable with `RUN_SONAR=true`.
- Gitleaks: required when `RUN_SECURITY_SCANS=true`.
- Trivy: required when `RUN_SECURITY_SCANS=true`.
- OWASP ZAP baseline script: required when `RUN_DAST=true`.
- Terraform CLI: required when `RUN_TERRAFORM_PLAN=true`.
- kubectl: required when `DEPLOY=true`.

## Agent tool check

The Jenkinsfile has an `Agent Tool Check` stage. It checks these tools before
running the build:

- `git`
- `python3`
- `python3-pip`
- `python3-venv`
- Docker
- `curl`

It also checks optional tools and only fails when the matching Jenkins parameter
is enabled:

- `gitleaks` and `trivy` when `RUN_SECURITY_SCANS=true`
- `sonar-scanner` when `RUN_SONAR=true`
- `zap-baseline.py` when `RUN_DAST=true`
- `terraform` when `RUN_TERRAFORM_PLAN=true`
- `kubectl` when `DEPLOY=true`

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
- Kubernetes access: configure kubeconfig on the Jenkins agent for deployments.
- SonarQube token: configure it in your Jenkins SonarQube installation if you
  decide to use SonarQube.

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

The manifests under `k8s/` are simple examples for `dev`, `qa`, and `prod`.
The Jenkinsfile asks for approval before `qa` or `prod` deployments.

For a class assignment, rolling deployment is enough. Blue-green and canary are
included as lightweight placeholders so you can explain the strategy without
needing a service mesh or advanced traffic routing.
