#!/usr/bin/env bash
# download-verified-asset.sh <version> <asset-name> <dest-path> [policy-flag]
# Downloads one official release asset and verifies sha256+size (and the
# intendedUse policy) against the already-verified official manifest.
# Requires: OFFICIAL_MANIFEST_PATH env (set from the verify-official-release
# action's manifest-path output). policy-flag defaults to
# --forbid-signing-input; pass --expect-signing-input for unsigned inputs.
set -euo pipefail

VERSION="$1"
ASSET="$2"
DEST="$3"
POLICY="${4:---forbid-signing-input}"
MANIFEST="${OFFICIAL_MANIFEST_PATH:?OFFICIAL_MANIFEST_PATH not set — run verify-official-release first}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

base="${SANAD_RELEASE_DOWNLOAD_BASE:?Set SANAD_RELEASE_DOWNLOAD_BASE to this version's HTTPS asset directory}"
[[ "$base" =~ ^https://[^[:space:]]+$ ]] || { echo 'SANAD_RELEASE_DOWNLOAD_BASE must be HTTPS' >&2; exit 1; }
[[ "$ASSET" =~ ^[A-Za-z0-9._-]+$ ]] || { echo 'Invalid asset name' >&2; exit 1; }
url="${base%/}/${ASSET}"
mkdir -p "$(dirname "$DEST")"

# Download to a temp path and only move into place once verified, so unverified
# bytes never occupy the destination a later step reads. `set -e` aborts the job
# today, but that is a property of the caller, not of this script.
tmp="$(mktemp "${DEST}.download.XXXXXX")"
cleanup() { rm -f "$tmp"; }
trap cleanup EXIT

curl -fsSL --retry 3 --retry-delay 5 -o "$tmp" "$url"
node "$SCRIPT_DIR/verify-manifest.mjs" check-asset \
  --manifest "$MANIFEST" --name "$ASSET" --file "$tmp" "$POLICY"
mv "$tmp" "$DEST"
