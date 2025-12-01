# Shared GitHub Actions

Reusable composite actions for CI/CD workflows, designed for use with ARC (Actions Runner Controller) in Kubernetes container mode.

## Available Actions

### `checkout`
Shell-based git checkout for containers without Node.js. Use this instead of `actions/checkout@v4` when running in minimal containers.

```yaml
jobs:
  build:
    runs-on: self-hosted
    container:
      image: your-registry/buildkit-builder:1.0.0
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
Build and push Docker images using BuildKit (daemonless, rootless, secure container builds). BuildKit provides better caching, full Dockerfile syntax support, and improved performance compared to legacy tools.

```yaml
jobs:
  build:
    runs-on: self-hosted
    container:
      image: your-registry/buildkit-builder:1.0.0
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

### `setup-kubectl`
Configure kubectl for Kubernetes cluster access.

```yaml
- uses: irulast/shared-actions/setup-kubectl@v1
  with:
    context: my-cluster
    namespace: production
```

## Builder Images

### `buildkit-builder`
A general-purpose CI/CD builder image with BuildKit for container builds. Includes:
- BuildKit (daemonless, rootless)
- Git, curl, wget, jq, yq
- kubectl, helm
- Common build utilities

Build and push to your registry:
```bash
docker build -t your-registry/buildkit-builder:1.0.0 buildkit-builder/
docker push your-registry/buildkit-builder:1.0.0
```

## Usage with ARC Kubernetes Mode

These actions are designed for ARC runners using Kubernetes container mode. Each job must specify a `container:` image:

```yaml
jobs:
  build:
    runs-on: self-hosted
    container:
      image: your-registry/buildkit-builder:1.0.0
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

## License

MIT