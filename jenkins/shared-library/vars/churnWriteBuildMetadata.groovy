def call(String environment = 'dev', String deploymentStrategy = 'rolling', String imageName = 'local') {
    sh """
        set -eu

        ENVIRONMENT="${environment}"
        DEPLOY_STRATEGY="${deploymentStrategy}"
        IMAGE_NAME="${imageName}"
        SHORT_SHA="\${SHORT_SHA:-\$(git rev-parse --short=8 HEAD)}"
        BUILD_NUMBER="\${BUILD_NUMBER:-local}"
        BUILD_TAG="build-\${BUILD_NUMBER}-\${SHORT_SHA}"

        mkdir -p reports

        cat > reports/build-metadata.json <<EOF
{
  "app": "churn-app",
  "build_number": "\${BUILD_NUMBER}",
  "build_tag": "\${BUILD_TAG}",
  "commit": "\${SHORT_SHA}",
  "environment": "\${ENVIRONMENT}",
  "deployment_strategy": "\${DEPLOY_STRATEGY}",
  "image": "\${IMAGE_NAME}"
}
EOF

        echo "Wrote reports/build-metadata.json"
    """
}
