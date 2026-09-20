# Sanad releases

This public repository hosts downloadable Sanad agent, viewer, and helper
packages. The source code and release build workflow live in the private
[`sanadengine/sanad`](https://github.com/sanadengine/sanad) repository.

## Release path

1. A reviewed `vX.Y.Z` tag in the private source repository starts its GitHub
   Actions release workflow. It builds the packages and container images,
   verifies platform signatures and image digests, and signs
   `release-artifact-manifest.json`.
2. The source workflow publishes the complete asset set here. Its
   `SANAD_PUBLIC_RELEASE_TOKEN` secret must be a fine-grained GitHub token with
   **Contents: write** on this repository only. The token is used only by the
   release publication job and by the guarded draft promotion workflow.
3. For a candidate or an operator-requested draft, promote the release through
   the source repository's `release-promotion.yml` workflow after the tagged
   source commit reaches `main`.
4. Point a Sanad deployment at these public assets only after a complete
   signed release exists:

   ```env
   BINARY_SOURCE=github
   BINARY_GITHUB_REPOSITORY=sanadengine/sanad-releases
   BINARY_VERSION=<published-version>
   RELEASE_ARTIFACT_MANIFEST_PUBLIC_KEYS=<base64-ed25519-public-key>
   ```

Keep `BINARY_SOURCE=local` while no complete release is published. A source
build or a draft release is not a usable download source.

Windows and macOS packages require platform signing credentials in the private
source repository before the release job can publish. The release manifest
signing key must also be configured there. `scripts/generate-manifest-key.sh`
can generate a new key pair for a future rotation.
