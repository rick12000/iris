# Versioning and Release Process

## Version Number

The canonical version is defined in one place: `version` in `pyproject.toml`. The bootstrap
scripts (`scripts/bootstrapping/setup.ps1` and `scripts/bootstrapping/setup.sh`) contain
mirrored `VOCALANCE_VERSION` values that must always match. A CI check
(`verify-setup-script-version`) enforces this on every commit and will fail the pipeline
if they diverge.

When bumping the version, update all three fields together in the same commit.

## What Triggers a Release

The CI pipeline monitors every push to `main`. On each merge, the `draft-release` job
compares the current `pyproject.toml` version against the latest published GitHub release.
If the version is higher, a draft release is created automatically. If no version bump
occurred the job is skipped silently — code can be merged to main indefinitely without
producing a release.

The draft release requires all quality gates to pass first:

- Linting and pre-commit hooks
- Trivy security scan
- Unit tests
- Logging and activity tracking default-off checks
- Setup script version match check

Once created, the draft is invisible to end users. A developer must go into the GitHub
Releases page, add release notes, and publish it manually.

## Release Artifacts

The `draft-release` CI job produces the following release assets:

**Application zip** (`vocalance-v{VERSION}.zip`):

```
vocalance/   — application package
vocalance.py — entry point
pyproject.toml
uv.lock      — fully pinned dependency lockfile
README.md
DISCLAIMER.md
NOTICES/     — third-party licence disclosures
```

**Standalone scripts** (uploaded separately, not inside the zip):

- `setup.ps1` / `cleanup.ps1` — Windows installer and uninstaller
- `setup.sh` / `cleanup.sh` — macOS installer and uninstaller

**Checksum**: `vocalance-v{VERSION}.zip.sha256`

Dev-only files (tests, CI config, docs, pre-commit config, bootstrapping scripts) are excluded from the zip.

Once published, a GitHub release is **immutable** — all assets are fixed artifacts and will not change.

## How the Bootstrap Script Uses Releases

`setup.ps1` and `setup.sh` are distributed as standalone release assets rather than bundled in the zip.
Users fetch the script for their OS from the latest release and run it locally. The script then downloads
the application zip at a hard-coded URL derived from `VOCALANCE_VERSION`:

```
https://github.com/rick12000/vocalance/releases/download/v{VOCALANCE_VERSION}/vocalance-v{VOCALANCE_VERSION}.zip
```

This means every copy of the installer always installs **exactly the version it was shipped
with**, regardless of when it is run.

Windows installs to `%LOCALAPPDATA%\Programs\Vocalance\`. macOS installs to
`~/Library/Application Support/Vocalance/runtime/` and creates `~/Applications/Vocalance.app`.
Neither installer requires administrator or root privileges.

After extraction, dependencies are installed with `uv sync --frozen`, which requires the
`uv.lock` file to be satisfied exactly. If any dependency resolution would deviate from the
lockfile the install aborts.

## Developer Workflow Summary

1. Develop and merge features to `main` freely — no version bump required.
2. When ready to release, bump `version` in `pyproject.toml` and `VOCALANCE_VERSION` in
   `setup.ps1` and `setup.sh` to the same value in a single PR.
3. Merge the PR. CI creates a draft GitHub release automatically.
4. Add release notes on the GitHub Releases page and publish.
