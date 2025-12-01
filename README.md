# Shared GitHub Actions

Reusable composite actions for CI/CD workflows, designed for use with ARC (Actions Runner Controller) in Kubernetes container mode.

## Available Actions

### `checkout`
Shell-based git checkout for containers without Node.js (like Kaniko). Use this instead of `actions/checkout@v4` when running in minimal containers.

```yaml
jobs:
  build:
    runs-on: self-hosted
    container:
      image: gcr.io/kaniko-project/executor:debug
    steps:
      - uses: irulast/shared-actions/checkout@v1
      - uses: irulast/shared-actions/kaniko-build@v1
        with:
          destination: registry.example.com/myapp:latest
```

**Inputs:**
- `repository` - Repository to checkout (default: current repository)
- `ref` - Git ref to checkout (default: triggering ref)
- `token` - GitHub token for private repos
- `fetch-depth` - Number of commits to fetch (default: 1)
- `path` - Checkout path relative to workspace

### `kaniko-build`
Build and push Docker images using Kaniko (daemonless, secure container builds).

```yaml
jobs:
  build:
    runs-on: self-hosted
    container:
      image: gcr.io/kaniko-project/executor:debug
    steps:
      - uses: irulast/shared-actions/checkout@v1  # Use shell-based checkout for Kaniko
      - uses: irulast/shared-actions/kaniko-build@v1
        with:
          destination: registry.example.com/myapp:${{ github.sha }}
          cache: 'true'
          cache-repo: registry.example.com/cache/myapp
```

### `get-version`
Read version from VERSION file and get short git SHA.

```yaml
- uses: irulast/shared-actions/get-version@v1
  id: version
# Outputs: version, sha-short
```

### `validate-migrations`
Validate SQL migration file naming convention (Flyway format: `V<timestamp>__<description>.sql`).

```yaml
- uses: irulast/shared-actions/validate-migrations@v1
  with:
    migrations-path: migrations
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

## Usage with ARC Kubernetes Mode

These actions are designed for ARC runners using Kubernetes container mode. Each job must specify a `container:` image:

```yaml
jobs:
  build:
    runs-on: self-hosted
    container:
      image: gcr.io/kaniko-project/executor:debug
    steps:
      - uses: irulast/shared-actions/checkout@v1  # Shell-based checkout for Kaniko
      - uses: irulast/shared-actions/get-version@v1
        id: version
      - uses: irulast/shared-actions/kaniko-build@v1
        with:
          destination: |
            my-registry/my-image:${{ steps.version.outputs.version }}
            my-registry/my-image:${{ steps.version.outputs.sha-short }}
            my-registry/my-image:latest
```

## License

MIT