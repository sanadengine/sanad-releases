#!/usr/bin/env bash
# checkout-verified-source.sh <version> <signed-manifest-commit> <destination>
# Resolve the GitLab release tag, bind it to the signed manifest, and checkout
# the exact commit before any signing credential is used.
set -euo pipefail

version="${1:?version required}"
commit="${2:?signed manifest commit required}"
dest="${3:?destination required}"
source_url="${SANAD_SOURCE_REPOSITORY_URL:-https://gitlab.com/manageengine-group/sanad.git}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]] || { echo 'Invalid version' >&2; exit 1; }
[[ "$commit" =~ ^[0-9a-f]{40}$ ]] || { echo 'Invalid signed commit SHA' >&2; exit 1; }
[[ "$source_url" == 'https://gitlab.com/manageengine-group/sanad.git' ]] || { echo 'Unexpected source repository URL' >&2; exit 1; }
[[ ! -e "$dest" ]] || { echo 'Destination already exists' >&2; exit 1; }

if [[ -n "${SANAD_GITLAB_READ_TOKEN:-}" ]]; then
  askpass="$(mktemp)"
  trap 'rm -f "$askpass"' EXIT
  cat > "$askpass" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  *Username*) printf '%s\n' oauth2 ;;
  *Password*) printf '%s\n' "$SANAD_GITLAB_READ_TOKEN" ;;
esac
EOF
  chmod 700 "$askpass"
  GIT_ASKPASS="$askpass" GIT_TERMINAL_PROMPT=0 git clone --no-checkout "$source_url" "$dest"
else
  GIT_TERMINAL_PROMPT=0 git clone --no-checkout "$source_url" "$dest"
fi

tag_commit="$(git -C "$dest" rev-parse "v${version}^{commit}")"
if [[ "$tag_commit" != "$commit" ]]; then
  echo "GitLab tag v${version} differs from signed manifest sourceCommit" >&2
  exit 1
fi
git -C "$dest" checkout --detach "$commit"
[[ "$(git -C "$dest" rev-parse HEAD)" == "$commit" ]]
