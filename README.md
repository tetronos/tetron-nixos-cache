# tetron-nixos-cache

Signed Nix binary cache for [tetron-nixos](https://github.com/tetronos/tetron-nixos): prebuilt tetron, tetron-wm, tetron-tui, casttui and kmscon (touchpad tap) for x86_64-linux and aarch64-linux, so `nix profile install github:tetronos/tetron-nixos#tetron-wm` downloads instead of compiling. Only the suite's own packages are here; everything else comes from cache.nixos.org, which Nix asks first.

The cache is the assets of the [`cache` release](https://github.com/tetronos/tetron-nixos-cache/releases/tag/cache).

## Use it

Substituter and public key:

```
https://github.com/tetronos/tetron-nixos-cache/releases/download/cache
tetron-nixos-cache-1:VZnNn/Hb0ytcL354uHPmQeZA0CZheIIHUgjBVrghLUI=
```

NixOS (`configuration.nix`):

```nix
nix.settings = {
  extra-substituters = [ "https://github.com/tetronos/tetron-nixos-cache/releases/download/cache" ];
  extra-trusted-public-keys = [ "tetron-nixos-cache-1:VZnNn/Hb0ytcL354uHPmQeZA0CZheIIHUgjBVrghLUI=" ];
};
```

Any Linux with Nix (`/etc/nix/nix.conf`, then restart nix-daemon):

```
extra-substituters = https://github.com/tetronos/tetron-nixos-cache/releases/download/cache
extra-trusted-public-keys = tetron-nixos-cache-1:VZnNn/Hb0ytcL354uHPmQeZA0CZheIIHUgjBVrghLUI=
```

## How it is built

`.github/workflows/build.yml` (run by hand with a tetron-nixos ref) builds the packages on GitHub-hosted x86_64 and arm64 runners, signs the store paths cache.nixos.org lacks with the key above, and uploads them (`scripts/push.sh`). Assets are never overwritten. The narinfo `URL` points at the flat asset name; the signature covers the store path, NAR hash, size and references, so it is unaffected.
