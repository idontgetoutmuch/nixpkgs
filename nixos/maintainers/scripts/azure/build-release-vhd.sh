#!/usr/bin/env bash
set -x
set -euo pipefail

unset NIXOS_CONFIG
unset NIX_PATH

image="${1}"; shift

# build
nix-build \
  --no-out-link \
  -A "${image}.machine.config.system.build.azureImage" \
  release-images.nix
