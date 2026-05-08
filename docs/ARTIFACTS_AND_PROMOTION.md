# Artifacts And Promotion

The pipeline creates a simple build artifact:

```text
reports/churn-app-<build>-<commit>.tar.gz
```

It also writes metadata:

- `reports/<artifact>.metadata.json`
- `reports/promotion.json`
- `reports/build-metadata.json`

If `NEXUS_REPO_URL` is set, Jenkins uploads the tarball to Nexus with the
`nexus-credentials` Jenkins credential.

Promotion is intentionally lightweight for this assignment: the promotion file
records which environment the artifact is ready for. A real team would use
repository stages such as `dev`, `qa`, and `release`.
