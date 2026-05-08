def call() {
    sh '''
        set -eu

        CURRENT_BRANCH="${BRANCH_NAME:-${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}}"
        CURRENT_BRANCH="${CURRENT_BRANCH#origin/}"

        if [ "$CURRENT_BRANCH" = "HEAD" ]; then
          echo "Detached HEAD checkout detected. Skipping branch name policy."
          exit 0
        fi

        case "$CURRENT_BRANCH" in
          main|develop|feature/*|bugfix/*|hotfix/*|release/*|PR-*|CHANGE-*)
            echo "Branch policy passed for: $CURRENT_BRANCH"
            ;;
          *)
            echo "Branch policy failed for: $CURRENT_BRANCH"
            echo "Use main, develop, feature/*, bugfix/*, hotfix/*, release/*, or Jenkins PR branches."
            exit 1
            ;;
        esac
    '''
}
