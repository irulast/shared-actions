# Shared GitHub Actions

Reusable composite actions for CI/CD workflows, designed for use with ARC (Actions Runner Controller) in Kubernetes container mode.

## Available Actions

### `checkout`
Shell-based git checkout for containers without Node.js. Use this instead of `actions/checkout@v4` when running in minimal containers. Automatically configures git safe.directory to handle cross-user ownership.

```yaml
jobs:
  build:
    runs-on: self-hosted
    container:
      image: moby/buildkit:v0.18.2
    steps:
      - uses: irulast/shared-actions/checkout@v1
      - uses: irulast/shared-actions/buildkit-build@v1
        with:
          destination: registry.example.com/myapp:latest
```

**Inputs:**
- `repository` - Repository to checkout (default: current repository)
- `ref` - Git ref to checkout (default: triggering ref)
- `token` - GitHub token for private repos
- `fetch-depth` - Number of commits to fetch (default: 1)
- `path` - Checkout path relative to workspace

### `buildkit-build`
Build and push Docker images using BuildKit (daemonless, secure container builds). BuildKit provides better caching, full Dockerfile syntax support, and improved performance compared to legacy tools.

```yaml
jobs:
  build:
    runs-on: self-hosted
    container:
      image: moby/buildkit:v0.18.2
    steps:
      - uses: irulast/shared-actions/checkout@v1
      - uses: irulast/shared-actions/buildkit-build@v1
        with:
          destination: registry.example.com/myapp:${{ github.sha }}
          cache: 'true'
          cache-repo: registry.example.com/cache/myapp
```

**Inputs:**
- `context` - Build context path (default: `.`)
- `dockerfile` - Path to Dockerfile (default: `Dockerfile`)
- `destination` - Image destination(s), one per line (required)
- `build-args` - Build arguments, one per line (format: `KEY=VALUE`)
- `target` - Target stage for multi-stage builds
- `cache` - Enable layer caching (default: `true`)
- `cache-repo` - Cache repository for registry-based caching
- `cache-mode` - Cache mode: `min` or `max` (default: `max`)
- `push` - Push image to registry (default: `true`)
- `platforms` - Target platforms (e.g., `linux/amd64,linux/arm64`)
- `secrets` - Build secrets, one per line (format: `id=ID,src=PATH`)
- `extra-args` - Additional BuildKit arguments

**Outputs:**
- `digest` - Image digest (sha256:...)

**Cache Warming:**
BuildKit's registry cache with `mode=max` automatically caches all intermediate layers, providing efficient cache warming without external tools. Each build exports its cache to the registry, which subsequent builds can import.

### `get-version`
Read version from VERSION file and get short git SHA.

```yaml
- uses: irulast/shared-actions/get-version@v1
  id: version
  with:
    version-file: frontend/VERSION  # Optional, defaults to VERSION
# Outputs: version, sha-short
```

**Inputs:**
- `version-file` - Path to VERSION file (default: `VERSION`)

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
    version-file: services/VERSION  # Optional, defaults to VERSION
    sync-package-json: 'frontend/package.json'
    sync-cargo-toml: 'services/*/Cargo.toml'
```

**Inputs:**
- `bump-type` - Version bump type: `major`, `minor`, or `patch` (required)
- `version-file` - Path to VERSION file (default: `VERSION`)
- `sync-package-json` - Glob pattern for package.json files to sync (optional)
- `sync-cargo-toml` - Glob pattern for Cargo.toml files to sync (optional)

### `git-commit-push`
Commit and push changes with automatic rebase retry for version bump commits.

When multiple workflows try to push version bumps simultaneously, this action will automatically detect if the intervening commits are all version bumps (contain `[skip ci]` or match `chore(*): bump` pattern), rebase on top of them, and retry the push.

```yaml
- uses: irulast/shared-actions/git-commit-push@v1
  with:
    message: "chore(frontend): bump version to ${{ steps.version.outputs.new-version }} [skip ci]"
    files: "frontend/VERSION frontend/package.json"
```

**Inputs:**
- `message` - Commit message (required)
- `files` - Files to add, space-separated or `.` for all (default: `.`)
- `author-name` - Git author name (default: `GitHub Actions`)
- `author-email` - Git author email (default: `actions@github.com`)
- `branch` - Branch to push to (default: current branch)
- `force` - Force push (default: `false`)
- `skip-if-empty` - Skip commit if no changes (default: `true`)

**Outputs:**
- `committed` - Whether a commit was made (`true`/`false`)
- `sha` - Commit SHA (if committed)

### `helm-push`
Package and push a Helm chart to an OCI registry. Automatically updates Chart.yaml with the specified version and optional OCI annotations before packaging. If the chart has dependencies defined in Chart.yaml, they are automatically built before packaging.

```yaml
jobs:
  push-chart:
    runs-on: self-hosted
    container:
      image: alpine/helm:latest
    steps:
      - uses: irulast/shared-actions/checkout@v1
      - uses: irulast/shared-actions/get-version@v1
        id: version
      - uses: irulast/shared-actions/helm-push@v1
        with:
          chart-path: deploy/charts/myapp
          version: ${{ steps.version.outputs.version }}
          registry: oci://registry.example.com/charts
          revision: ${{ github.sha }}
          created: ${{ github.event.head_commit.timestamp }}
```

**Inputs:**
- `chart-path` - Path to the Helm chart directory (required)
- `version` - Chart version (updates Chart.yaml version and appVersion) (required)
- `registry` - OCI registry URL (required)
- `registry-config` - Path to registry config.json for authentication
- `revision` - Git revision/SHA for `org.opencontainers.image.revision` annotation
- `created` - Build timestamp (RFC 3339) for `org.opencontainers.image.created` annotation

**Outputs:**
- `chart-ref` - Full OCI reference to the pushed chart

### `helm-deploy`
Deploy a Helm chart from an OCI registry. Useful for direct deployments from CI/CD (alternative to GitOps).

```yaml
- uses: irulast/shared-actions/helm-deploy@v1
  with:
    release-name: myapp
    chart: oci://registry.example.com/charts/myapp
    version: ${{ steps.version.outputs.version }}
    namespace: production
    set: |
      image.tag=${{ steps.version.outputs.version }}
```

**Inputs:**
- `release-name` - Helm release name (required)
- `chart` - OCI chart reference (required)
- `version` - Chart version to deploy (required)
- `namespace` - Kubernetes namespace (required)
- `values` - Helm values in YAML format
- `set` - Values to set via --set (one per line, format: `key=value`)
- `wait` - Wait for resources to be ready (default: `true`)
- `timeout` - Timeout for helm operations (default: `5m`)
- `create-namespace` - Create namespace if it does not exist (default: `false`)

**Outputs:**
- `revision` - Helm release revision number

### `k8s-job-run`
Apply and run a Kubernetes Job, optionally waiting for completion. Useful for deployment tasks triggered from CI/CD.

```yaml
- uses: irulast/shared-actions/k8s-job-run@v1
  with:
    manifest: deploy/my-job/job.yaml
    namespace: my-namespace
    image-tag: ${{ steps.version.outputs.version }}
    wait: 'true'
    timeout: '5m'
```

**Inputs:**
- `manifest` - Path to the Job manifest file (required)
- `namespace` - Kubernetes namespace (if not in manifest)
- `image-tag` - Image tag to substitute (replaces `${IMAGE_TAG}` in manifest)
- `wait` - Wait for job completion (default: `true`)
- `timeout` - Timeout for job completion (default: `5m`)
- `delete-existing` - Delete existing job with same name before applying (default: `true`)

**Outputs:**
- `job-name` - Name of the created job
- `status` - Job completion status (`Succeeded`/`Failed`)

**Note:** Requires the workflow container to have kubectl access to the cluster. When using ARC Kubernetes mode, configure a ServiceAccount with appropriate RBAC permissions in the worker podspec.

## Usage with ARC Kubernetes Mode

These actions are designed for ARC runners using Kubernetes container mode with the official `moby/buildkit` image. Each job must specify a `container:` image:

```yaml
jobs:
  build:
    runs-on: self-hosted
    container:
      image: moby/buildkit:v0.18.2
    steps:
      - uses: irulast/shared-actions/checkout@v1
      - uses: irulast/shared-actions/get-version@v1
        id: version
      - uses: irulast/shared-actions/buildkit-build@v1
        with:
          destination: |
            my-registry/my-image:${{ steps.version.outputs.version }}
            my-registry/my-image:${{ steps.version.outputs.sha-short }}
            my-registry/my-image:latest
          cache: 'true'
          cache-repo: my-registry/cache/my-image
```

All actions use POSIX-compatible shell scripts (`sh`) to work with minimal container images like the official BuildKit image which doesn't include bash.

## License

MIT