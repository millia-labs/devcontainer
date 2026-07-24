# devcontainer

Reusable [Dev Container Features](https://containers.dev/implementors/features/) for the
Millia toolchain. Every toolchain lives here as a *composable* feature so any project can
layer on exactly what it needs; the [`millia-codespace`](../codespace) sandbox stays
bare-minimum (just `act` + a container builder) and pulls in nothing else.

| Feature | ID | What it does |
| --- | --- | --- |
| **act** | `act` | Installs [`nektos/act`](https://github.com/nektos/act) to run GitHub Actions workflows locally, and pre-seeds `~/.actrc` with a default runner image so the first run never blocks on the interactive prompt. |
| **uv** | `uv` | Installs the [`uv`](https://github.com/astral-sh/uv) / `uvx` binaries system-wide plus a shared, world-readable managed CPython (default 3.13). |
| **node** | `node` | Installs Node.js from NodeSource (default major 20) and pnpm as a system-wide npm global (default 8). |
| **flutter** | `flutter` | Installs the Flutter SDK + bundled Dart (default 3.41.4) into `/opt/flutter`, owned by the remote user, runs `flutter precache`, and optionally installs an OpenJDK for Android/Gradle builds. |

## Usage

Once published, reference them from any `devcontainer.json`:

```jsonc
"features": {
  "ghcr.io/millia-labs/devcontainer/act:1": {
    "version": "latest",
    "defaultImage": "catthehacker/ubuntu:act-22.04"
  },
  "ghcr.io/millia-labs/devcontainer/uv:1": {
    "version": "latest",
    "pythonVersion": "3.13"
  },
  "ghcr.io/millia-labs/devcontainer/node:1": {
    "nodeMajor": "20",
    "pnpmVersion": "8"
  },
  "ghcr.io/millia-labs/devcontainer/flutter:1": {
    "version": "3.41.4"
  }
}
```

`act` needs a Docker daemon, so pair it with the official
`ghcr.io/devcontainers/features/docker-in-docker` feature — the `act` feature declares
`installsAfter` for it so ordering is handled automatically.

## Options

### `act`

| Option | Default | Description |
| --- | --- | --- |
| `version` | `latest` | act release to install (`latest` or a bare semver like `0.2.82`). |
| `defaultImage` | `catthehacker/ubuntu:act-22.04` | Image mapped to `ubuntu-latest` in `~/.actrc`. Use `-` to skip writing `.actrc`. |

### `uv`

| Option | Default | Description |
| --- | --- | --- |
| `version` | `latest` | uv release to install. |
| `pythonVersion` | `3.13` | CPython to pre-install via `uv python install`. Use `-` to skip. |

### `node`

| Option | Default | Description |
| --- | --- | --- |
| `nodeMajor` | `20` | Node.js major version from NodeSource. |
| `pnpmVersion` | `8` | pnpm version installed globally via npm. Use `-` to skip pnpm. |

### `flutter`

| Option | Default | Description |
| --- | --- | --- |
| `version` | `3.41.4` | Flutter release to install (`latest` resolves the newest on the channel). |
| `channel` | `stable` | Release channel (`stable` / `beta`). |
| `installJdk` | `true` | Also install a headless OpenJDK for Android/Gradle builds. |
| `jdkVersion` | `17` | OpenJDK major version when `installJdk` is true. |
| `precache` | `true` | Run `flutter precache` after install. |

## Developing / testing locally

Tests use the official harness (no mocks — features are installed into a real container
and exercised):

```bash
npm install -g @devcontainers/cli

# per-feature autorun tests
devcontainer features test --features act     --base-image mcr.microsoft.com/devcontainers/base:bookworm .
devcontainer features test --features uv      --base-image mcr.microsoft.com/devcontainers/base:bookworm .
devcontainer features test --features node    --base-image mcr.microsoft.com/devcontainers/base:bookworm .
devcontainer features test --features flutter --base-image mcr.microsoft.com/devcontainers/base:bookworm .

# global scenarios (act + uv together)
devcontainer features test --global-scenarios-only .
```

## Publishing

`.github/workflows/release.yaml` publishes each feature to
`ghcr.io/millia-labs/devcontainer/<id>` on push to `main` via
`devcontainers/action`.
