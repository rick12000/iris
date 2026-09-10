#!/usr/bin/env bash
set -euo pipefail

UV_VERSION="${1:-0.11.22}"
ARCH="${2:-aarch64}"
ARCHIVE_NAME="uv-${ARCH}-apple-darwin.tar.gz"
URL="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${ARCHIVE_NAME}"
TMP_FILE="$(mktemp "${TMPDIR:-/tmp}/uv-${UV_VERSION}-${ARCH}-hash.XXXXXX")"
trap 'rm -f "$TMP_FILE"' EXIT

echo "Downloading ${ARCHIVE_NAME} for uv ${UV_VERSION} from:"
echo "  ${URL}"
echo ""
curl -fsSL "$URL" -o "$TMP_FILE"
HASH="$(shasum -a 256 "$TMP_FILE" | awk '{print $1}')"
echo "SHA-256 (${ARCH}-apple-darwin): ${HASH}"
echo ""
echo "Paste into setup.sh UV_ARCHIVE_SHA256:"
echo "UV_ARCHIVE_SHA256='${HASH}'"
