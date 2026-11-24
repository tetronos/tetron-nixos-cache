#!/bin/sh
# Upload the store paths of the given outputs that cache.nixos.org lacks to
# the `cache` release of this repo, signed, as a flat Nix binary cache.
#   scripts/push.sh OUT_PATH...
# Env: NIX_SIGNING_KEY_FILE (secret key file), GH_TOKEN, GITHUB_REPOSITORY.
# Never overwrites an asset: one already in the release is skipped.
set -eu
: "${NIX_SIGNING_KEY_FILE:?}" "${GITHUB_REPOSITORY:?}"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Closure paths cache.nixos.org does not have. The narinfo of each path it
# has is kept in the local cache as a placeholder: a binary cache store
# refuses a path whose references it does not hold (never uploaded).
mkdir "$work/cache"
nix path-info --recursive "$@" | while read -r p; do
	h=$(basename "$p" | cut -c1-32)
	code=$(curl -s -o "$work/cache/$h.narinfo" -w '%{http_code}' "https://cache.nixos.org/$h.narinfo")
	[ "$code" = 200 ] || { rm -f "$work/cache/$h.narinfo"; echo "$p"; }
done > "$work/missing"
echo "paths not on cache.nixos.org: $(wc -l < "$work/missing")"
sed 's|^|  |' "$work/missing"
[ -s "$work/missing" ] || exit 0

# Signed while copying; only the listed paths, not their closure.
xargs nix copy --no-recursive \
	--to "file://$work/cache?compression=xz&secret-key=$NIX_SIGNING_KEY_FILE" < "$work/missing"

# Release assets are flat: the narinfo URL loses its nar/ prefix. The
# signature covers path, NAR hash, size and references, not the URL.
# Only the missing paths' narinfos, not the placeholders.
mkdir "$work/flat"
while read -r p; do
	n=$(basename "$p" | cut -c1-32).narinfo
	sed 's|^URL: nar/|URL: |' "$work/cache/$n" > "$work/flat/$n"
done < "$work/missing"
cp "$work"/cache/nar/* "$work/flat/"

have=$(gh release view cache -R "$GITHUB_REPOSITORY" --json assets -q '.assets[].name')
n=0
for f in "$work"/flat/*; do
	name=$(basename "$f")
	if printf '%s\n' "$have" | grep -qxF "$name"; then
		continue
	fi
	gh release upload cache "$f" -R "$GITHUB_REPOSITORY"
	n=$((n + 1))
done
echo "uploaded $n new assets"
