#!/usr/bin/env sh
set -eu

AUTO_INSTALL="${1:-false}"

missing_packages=""

has_command() {
  command -v "$1" >/dev/null 2>&1
}

add_package() {
  case " $missing_packages " in
    *" $1 "*) ;;
    *) missing_packages="$missing_packages $1" ;;
  esac
}

if ! has_command git; then
  add_package git
fi

if ! has_command python3; then
  add_package python3
fi

if ! has_command docker; then
  add_package docker.io
fi

if ! has_command curl; then
  add_package curl
fi

if [ -n "$missing_packages" ]; then
  echo "Missing required packages:$missing_packages"

  if [ "$AUTO_INSTALL" != "true" ]; then
    echo "AUTO_INSTALL_TOOLS is false. Install the packages manually and rebuild."
    exit 1
  fi

  if ! has_command apt-get; then
    echo "Automatic install currently supports Ubuntu/Debian agents with apt-get."
    exit 1
  fi

  if has_command sudo; then
    sudo apt-get update
    sudo apt-get install -y $missing_packages python3-pip python3-venv
  else
    apt-get update
    apt-get install -y $missing_packages python3-pip python3-venv
  fi
else
  echo "Required commands found: git, python3, docker, curl"
fi

if ! python3 -m venv --help >/dev/null 2>&1; then
  echo "python3 venv support is missing."
  if [ "$AUTO_INSTALL" = "true" ] && has_command apt-get; then
    if has_command sudo; then
      sudo apt-get install -y python3-venv python3-pip
    else
      apt-get install -y python3-venv python3-pip
    fi
  else
    echo "Install python3-venv and python3-pip manually."
    exit 1
  fi
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker is installed, but Jenkins cannot access the Docker daemon."
  echo "Start Docker and add the jenkins user to the docker group, then restart Jenkins."
  echo "Example: sudo usermod -aG docker jenkins && sudo systemctl restart jenkins"
  exit 1
fi

echo "Agent tool check passed."
