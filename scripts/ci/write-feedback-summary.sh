#!/usr/bin/env sh
set -eu

mkdir -p reports

cat > reports/feedback-summary.md <<EOF
# CI Feedback Summary

- Unit and regression tests: see reports/junit/pytest.xml
- Coverage report: see reports/coverage.xml
- Lint report: see reports/flake8.txt
- Dependency audit: see reports/pip-audit.json when security scans are enabled
- Secret scan: see reports/gitleaks.json when security scans are enabled
- Container scan: see reports/trivy-image.txt when security scans are enabled
- Model evaluation: see reports/model-evaluation.txt

Use this file as the quick feedback loop for a Jenkins build.
EOF

echo "Wrote reports/feedback-summary.md"
