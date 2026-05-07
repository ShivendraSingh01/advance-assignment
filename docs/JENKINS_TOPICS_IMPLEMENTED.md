# Jenkins Topics Implemented

This project keeps the Jenkins implementation practical and beginner-friendly.

| Image topic | Where it is implemented |
| --- | --- |
| CI/CD pipeline design | `Jenkinsfile` stages from checkout to metadata archive |
| Environment approvals | `Approval` stage for `qa` and `prod` |
| PR, scheduled, manual triggers | Multibranch Jenkins setup, `cron`, and build parameters |
| Shared libraries | Example in `jenkins/shared-library/vars/churnNotify.groovy` |
| Pipeline parameterization | Jenkins parameters and `ci/pipeline.yml` |
| Git branching enforcement | `scripts/ci/check-branch.sh` |
| Automated metadata tagging | `scripts/ci/write-build-metadata.sh` |
| Code review support | `.github/pull_request_template.md` and `.github/CODEOWNERS` |
| Multi-module/container build | Docker build stage for the Python app |
| Unit, regression, and parallel tests | `Parallel Validation` stage and `pytest` |
| JUnit and coverage publishing | `reports/junit/pytest.xml`, `reports/coverage.xml`, and a 35% coverage gate |
| SonarQube quality gate setup | `sonar-project.properties` and optional Jenkins stage |
| Secret/security scans | Optional pip-audit plus Docker-based Gitleaks, Trivy, and ZAP stages |
| Artifact lifecycle | Jenkins archives reports and model files |
| Deployment strategies | Rolling, blue-green placeholder, canary placeholder in deploy script |
| Rollback | Jenkins `post failure` rollback with `kubectl rollout undo` |
| Multibranch pipeline | Jenkinsfile uses `checkout scm` and Jenkins branch env vars |
| Jenkins performance basics | Build discarder and disabled concurrent builds |
| GitOps | Kubernetes manifests under `k8s/` |
| Terraform with Jenkins | Optional plan stage under `infra/terraform/` |

The optional tools are disabled by default so a simple Jenkins agent can run the
main build first. Enable each integration after installing and configuring it.
