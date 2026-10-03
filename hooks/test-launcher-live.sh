#!/bin/sh
# Live check for bin/cli-version: runs the real launcher against PyPI in a fresh
# uv cache, so the pinned CLI resolves its dependencies the way a new install
# does. Needs network and uv. Run after every version bump: npm run test:live
set -eu
root="$(cd "$(dirname "$0")/.." && pwd)"
expected="$(tr -d '[:space:]' < "$root/bin/cli-version")"
cache="$(mktemp -d)"
trap 'rm -rf "$cache"' EXIT

out="$(UV_CACHE_DIR="$cache" "$root/bin/discolike" --version 2>&1)" || {
  printf 'FAIL pinned discolike-cli %s does not start:\n%s\n' "$expected" "$out"
  exit 1
}
case "$out" in
  *"$expected"*) printf 'ok discolike-cli %s starts: %s\n' "$expected" "$out" ;;
  *) printf 'FAIL expected version %s, got: %s\n' "$expected" "$out"; exit 1 ;;
esac
