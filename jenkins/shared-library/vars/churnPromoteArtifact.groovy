def call(String environment = 'dev', String imageName = 'local') {
    sh """
        set -eu

        ENVIRONMENT="${environment}"
        IMAGE_NAME="${imageName}"
        SHORT_SHA="\${SHORT_SHA:-\$(git rev-parse --short=8 HEAD)}"
        BUILD_NUMBER="\${BUILD_NUMBER:-local}"
        APP_NAME="\${APP_NAME:-churn-app}"

        mkdir -p reports

        cat > reports/promotion.json <<EOF
{
  "app": "\${APP_NAME}",
  "build_number": "\${BUILD_NUMBER}",
  "commit": "\${SHORT_SHA}",
  "image": "\${IMAGE_NAME}",
  "promoted_to": "\${ENVIRONMENT}",
  "status": "ready_for_\${ENVIRONMENT}"
}
EOF

        echo "Wrote reports/promotion.json"
    """
}
