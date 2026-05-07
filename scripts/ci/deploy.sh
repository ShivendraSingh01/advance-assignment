#!/usr/bin/env sh
set -eu

ENVIRONMENT="${1:-dev}"
STRATEGY="${2:-rolling}"
IMAGE_NAME="${3:-yourdockerhub/churn-app:latest}"
NAMESPACE="churn-${ENVIRONMENT}"

echo "Deploying ${IMAGE_NAME} to ${NAMESPACE} using ${STRATEGY}"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "k8s/${ENVIRONMENT}/"
kubectl -n "$NAMESPACE" set image deployment/churn-app churn-app="$IMAGE_NAME"

case "$STRATEGY" in
  rolling)
    kubectl -n "$NAMESPACE" rollout status deployment/churn-app
    ;;
  blue-green)
    echo "Blue-green placeholder: switch service selector after validating the new deployment."
    kubectl -n "$NAMESPACE" rollout status deployment/churn-app
    ;;
  canary)
    echo "Canary placeholder: start with one replica, test, then scale normally."
    kubectl -n "$NAMESPACE" scale deployment/churn-app --replicas=1
    kubectl -n "$NAMESPACE" rollout status deployment/churn-app
    ;;
  *)
    echo "Unknown deployment strategy: $STRATEGY"
    exit 1
    ;;
esac
