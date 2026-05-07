#!/usr/bin/env sh
set -eu

BRANCH_NAME="${BRANCH_NAME:-$(git rev-parse --abbrev-ref HEAD)}"

case "$BRANCH_NAME" in
  main|develop|feature/*|bugfix/*|hotfix/*|release/*|PR-*|CHANGE-*)
    echo "Branch policy passed for: $BRANCH_NAME"
    ;;
  *)
    echo "Branch policy failed for: $BRANCH_NAME"
    echo "Use main, develop, feature/*, bugfix/*, hotfix/*, release/*, or Jenkins PR branches."
    exit 1
    ;;
esac
