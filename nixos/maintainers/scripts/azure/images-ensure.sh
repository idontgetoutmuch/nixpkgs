#!/usr/bin/env bash
set -euo pipefail
set -x

# TODO: upload to primary location
# upload to ALL locations, skip primary, using URL from primary as blob copy source

# look ma, no NIX_PATH!
unset NIXOS_CONFIG
unset NIX_PATH

OUTDIR="./azure-result"
images="./azure-images-src.nix"

function build() {
  rev="${1}"
  nix-build "${images}" \
    -A "${rev}.machine.config.system.build.azureImage" \
    --out-link "${OUTDIR}/${rev}" \
    |& tee "${OUTDIR}/${rev}_buildlog";
  
  # note, this saves the nice label name separately (used for old images that
  # just name their output disk "disk.vhd")
  nix eval -f "${images}" "${rev}.name" --raw > "${OUTDIR}/${rev}_name"
}

rm -rf "${OUTDIR}"
mkdir -p "${OUTDIR}"

# TODO: replace this with something that lists out the
# images that don't have a URI yet
declare -a builds=(
  "nixos_19_03__9ec7625cee5365c741dee7b45a19aff5d5d56205"
)

for brev in "${builds[@]}"; do
  build "${brev}"
done

for brev in "${builds[@]}"; do
  url="$(./mkimage.sh \
    upload \
    "${OUTDIR}/${brev}/disk.vhd" \
    "$(cat "${OUTDIR}/${brev}_name")")"

  echo "${brev}: ${url}"
done

