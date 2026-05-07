#!/usr/bin/env sh
set -eu

missing_tools=""

has_command() {
  command -v "$1" >/dev/null 2>&1
}

add_missing() {
  missing_tools="${missing_tools} $1"
}

if ! has_command git; then
  add_missing git
fi

if ! has_command python3; then
  add_missing python3
fi

if ! has_command docker; then
  add_missing docker
fi

if ! has_command curl; then
  add_missing curl
fi

if [ -n "$missing_tools" ]; then
  echo "Missing required tools:${missing_tools}"
  echo ""
  echo "Install them on Ubuntu/Debian with:"
  echo "sudo apt-get update"
  echo "sudo apt-get install -y git python3 python3-pip python3-venv docker.io curl"
  exit 1
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

echo "Agent tool check passed: git, python3, venv, docker, and curl are ready."
