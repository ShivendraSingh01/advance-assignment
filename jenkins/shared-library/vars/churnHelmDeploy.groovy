def call(Map config = [:]) {
    def environment = config.environment
    def namespace = "churn-${environment}"
    def releaseName = config.releaseName ?: config.appName
    def chartPath = config.chartPath ?: 'charts/churn-app'
    def replicas = environment == 'prod' ? '2' : '1'
    def serviceType = environment == 'dev' ? 'LoadBalancer' : 'ClusterIP'
    def urlFile = "reports/service-url-${environment}.txt"

    sh """
        set -eu

        mkdir -p reports
        : > "${urlFile}"

        export KUBECONFIG="\$PWD/reports/kubeconfig-${environment}"

        aws eks update-kubeconfig \
            --region "${config.awsRegion}" \
            --name "${config.eksClusterName}" \
            --kubeconfig "\$KUBECONFIG"

        IMAGE_NAME="${config.imageName}"
        IMAGE_REPO="\${IMAGE_NAME%:*}"
        IMAGE_TAG="\${IMAGE_NAME##*:}"

        helm upgrade --install "${releaseName}" "${chartPath}" \
            --namespace "${namespace}" \
            --create-namespace \
            --set-string image.repository="\$IMAGE_REPO" \
            --set-string image.tag="\$IMAGE_TAG" \
            --set replicaCount="${replicas}" \
            --set service.type="${serviceType}" \
            --set environment="${environment}" \
            --set deploymentStrategy="${config.deploymentStrategy}" \
            --wait \
            --timeout 10m

        kubectl rollout status deployment/"${releaseName}" -n "${namespace}" --timeout=5m
        kubectl get service "${releaseName}" -n "${namespace}" -o wide

        SERVICE_HOST="\$(kubectl get service "${releaseName}" -n "${namespace}" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
        SERVICE_IP="\$(kubectl get service "${releaseName}" -n "${namespace}" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"

        if [ -n "\$SERVICE_HOST" ]; then
          echo "http://\$SERVICE_HOST" | tee "${urlFile}"
        elif [ -n "\$SERVICE_IP" ]; then
          echo "http://\$SERVICE_IP" | tee "${urlFile}"
        else
          echo "No external service URL yet. If this is dev, wait for the AWS LoadBalancer and run:"
          echo "kubectl get service ${releaseName} -n ${namespace}"
        fi
    """

    if (fileExists(urlFile)) {
        return readFile(urlFile).trim()
    }

    return ''
}
