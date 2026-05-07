#!/usr/bin/env sh
set -eu

BRANCH_NAME="${BRANCH_NAME:-${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}}"
BRANCH_NAME="${BRANCH_NAME#origin/}"

if [ "$BRANCH_NAME" = "HEAD" ]; then
  echo "Detached HEAD checkout detected. Skipping branch name policy."
  exit 0
fi

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
