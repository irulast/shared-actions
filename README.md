# Shared GitHub Actions

Reusable composite actions for CI/CD workflows.

## Available Actions

### `kaniko-build`
Build and push Docker images using Kaniko (daemonless, secure container builds).

```yaml
- uses: irulast/shared-actions/kaniko-build@v1
  with:
    destination: registry.example.com/myapp:${{ github.sha }}
    cache: 'true'
    cache-repo: registry.example.com/cache/myapp
```

### `bump-version`
Bump semantic version and sync across VERSION, package.json, and Cargo.toml files.

```yaml
- uses: irulast/shared-actions/bump-version@v1
  with:
    bump-type: 'patch'  # major, minor, or patch
    sync-package-json: 'frontend/package.json'
    sync-cargo-toml: 'services/*/Cargo.toml'
```

### `git-commit-push`
Commit and push changes (useful for GitOps workflows).

```yaml
- uses: irulast/shared-actions/git-commit-push@v1
  with:
    message: "chore: bump version to ${{ steps.version.outputs.new-version }}"
    files: "VERSION frontend/package.json services/"
```

### `setup-kubectl`
Configure kubectl for Kubernetes cluster access.

```yaml
- uses: irulast/shared-actions/setup-kubectl@v1
  with:
    context: my-cluster
    namespace: production
```

## Usage

These actions are designed to be used with self-hosted runners. Reference them in your workflows:

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux]
    steps:
      - uses: actions/checkout@v4
      - uses: irulast/shared-actions/kaniko-build@v1
        with:
          destination: my-registry/my-image:latest
```

## License

MIT