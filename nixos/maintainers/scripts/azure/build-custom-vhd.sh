#!/usr/bin/env bash
set -x
set -euo pipefail

unset NIXOS_CONFIG
unset NIX_PATH

# build
nix-build \
  --no-out-link \
  -A machine.config.system.build.azureImage \
  custom-image-example.nix
      
