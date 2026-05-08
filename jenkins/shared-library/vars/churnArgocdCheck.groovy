def call(Map config = [:]) {
    def server = config.server?.trim()
    def appName = config.appName?.trim()

    if (!server) {
        error('ARGOCD_SERVER is required when RUN_ARGOCD_CHECK=true.')
    }

    if (!appName) {
        error('ARGOCD_APP_NAME is required when RUN_ARGOCD_CHECK=true.')
    }

    sh """
        set -eu

        mkdir -p reports

        argocd app get "${appName}" \
            --server "${server}" \
            --auth-token "\$ARGOCD_AUTH_TOKEN" \
            --grpc-web \
            --insecure \
            --refresh | tee "reports/argocd-${appName}.txt"

        argocd app wait "${appName}" \
            --server "${server}" \
            --auth-token "\$ARGOCD_AUTH_TOKEN" \
            --grpc-web \
            --insecure \
            --health \
            --timeout 300 | tee -a "reports/argocd-${appName}.txt"
    """
}
