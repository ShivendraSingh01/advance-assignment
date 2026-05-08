# Jenkins Topics Implemented

This project keeps the Jenkins implementation practical and beginner-friendly.

| Image topic | Where it is implemented |
| --- | --- |
| CI/CD pipeline design | `Jenkinsfile` stages from checkout to metadata archive |
| Environment approvals | `Approval` stage for `qa` and `prod` |
| PR, scheduled, manual triggers | Multibranch Jenkins setup, `cron`, and build parameters |
| Shared libraries | Jenkinsfile uses wrappers from `jenkins/shared-library/vars` |
| Pipeline parameterization | Jenkins build parameters and environment-specific files in `ci/environments/` |
| Git branching enforcement | `churnCheckBranch` shared-library function |
| Automated metadata tagging | `churnWriteBuildMetadata` shared-library function |
| Code review support | `.github/pull_request_template.md` and `.github/CODEOWNERS` |
| Multi-module/container build | Python modules are tested together, then Docker builds one app image |
| Unit, regression, and parallel tests | `Parallel Validation` stage, `pytest`, JUnit, coverage, and `churnWriteFeedbackSummary` |
| JUnit and coverage publishing | `reports/junit/pytest.xml`, `reports/coverage.xml`, and a 35% coverage gate |
| SonarQube quality gate setup | `sonar-project.properties` and optional Jenkins stage |
| Secret/security scans | Optional pip-audit plus Docker-based Gitleaks, Trivy, and ZAP stages |
| Artifact lifecycle | `churnPackageArtifact`, optional Nexus upload, `churnPromoteArtifact`, and Jenkins archive |
| Deployment strategies | Environment-aware Terraform deployment parameters |
| Rollback | Terraform state tracks deployed Kubernetes resources for controlled re-apply |
| Multibranch pipeline | Jenkinsfile uses `checkout scm` and Jenkins branch env vars |
| Jenkins performance basics | Build discarder and disabled concurrent builds |
| GitOps | Not active in the Jenkins deploy path; Terraform is the single deployment tool |
| Terraform with Jenkins | Terraform plans/applies Kubernetes resources to AWS EKS from `infra/terraform/` |

The optional tools are disabled by default so a simple Jenkins agent can run the
main build first. Enable each integration after installing and configuring it.
