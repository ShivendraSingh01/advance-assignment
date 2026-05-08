def call(String imageName = 'local') {
    sh """
        set -eu

        IMAGE_NAME="${imageName}"
        SHORT_SHA="\${SHORT_SHA:-\$(git rev-parse --short=8 HEAD)}"
        BUILD_NUMBER="\${BUILD_NUMBER:-local}"
        APP_NAME="\${APP_NAME:-churn-app}"
        ARTIFACT_NAME="\${APP_NAME}-\${BUILD_NUMBER}-\${SHORT_SHA}"

        mkdir -p reports

        cat > "reports/\${ARTIFACT_NAME}.metadata.json" <<EOF
{
  "app": "\${APP_NAME}",
  "build_number": "\${BUILD_NUMBER}",
  "commit": "\${SHORT_SHA}",
  "image": "\${IMAGE_NAME}",
  "artifact": "\${ARTIFACT_NAME}.tar.gz"
}
EOF

        tar -czf "reports/\${ARTIFACT_NAME}.tar.gz" \\
          app model requirements.txt Dockerfile Jenkinsfile ci infra docs \\
          "reports/\${ARTIFACT_NAME}.metadata.json"

        echo "Created reports/\${ARTIFACT_NAME}.tar.gz"
    """
}
