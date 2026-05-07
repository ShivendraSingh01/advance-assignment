#!/usr/bin/env sh
set -eu

RUN_SECURITY_SCANS="${1:-false}"
RUN_SONAR="${2:-false}"
RUN_DAST="${3:-false}"
RUN_TERRAFORM_PLAN="${4:-false}"
DEPLOY="${5:-false}"

missing_tools=""
missing_enabled_optional=""
missing_disabled_optional=""

has_command() {
  command -v "$1" >/dev/null 2>&1
}

add_missing_required() {
  missing_tools="${missing_tools} $1"
}

add_missing_optional() {
  tool_name="$1"
  enabled="$2"

  if [ "$enabled" = "true" ]; then
    missing_enabled_optional="${missing_enabled_optional} ${tool_name}"
  else
    missing_disabled_optional="${missing_disabled_optional} ${tool_name}"
  fi
}

if ! has_command git; then
  add_missing_required git
fi

if ! has_command python3; then
  add_missing_required python3
fi

if ! has_command docker; then
  add_missing_required docker
fi

if ! has_command curl; then
  add_missing_required curl
fi

if [ -n "$missing_tools" ]; then
  echo "Missing required tools:${missing_tools}"
  echo ""
  echo "Install them on Ubuntu/Debian with:"
  echo "sudo apt-get update"
  echo "sudo apt-get install -y git python3 python3-pip python3-venv docker.io curl"
  exit 1
fi

if ! has_command sonar-scanner; then
  add_missing_optional sonar-scanner "$RUN_SONAR"
fi

if ! has_command terraform; then
  add_missing_optional terraform "$RUN_TERRAFORM_PLAN"
fi

if ! has_command kubectl; then
  add_missing_optional kubectl "$DEPLOY"
fi

if ! python3 -m venv --help >/dev/null 2>&1; then
  echo "python3 venv support is missing."
  echo "Install it with:"
  echo "sudo apt-get install -y python3-venv python3-pip"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker is installed, but Jenkins cannot access the Docker daemon."
  echo "Fix it with:"
  echo "sudo usermod -aG docker jenkins"
  echo "sudo systemctl restart jenkins"
  exit 1
fi

if [ -n "$missing_disabled_optional" ]; then
  echo "Optional tools not installed and currently not required:${missing_disabled_optional}"
fi

if [ -n "$missing_enabled_optional" ]; then
  echo "Missing optional tools required by enabled Jenkins parameters:${missing_enabled_optional}"
  echo ""
  echo "Install only the tools you enabled:"
  echo "- sonar-scanner: SonarQube scan when RUN_SONAR=true"
  echo "- terraform: Terraform plan when RUN_TERRAFORM_PLAN=true"
  echo "- kubectl: deployment and rollback when DEPLOY=true"
  exit 1
fi

echo "Agent tool check passed: required tools are ready."
